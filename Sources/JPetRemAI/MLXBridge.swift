// MLXBridge.swift
// Apple MLX 推理引擎生命周期管理 + OpenAI 兼容 API 客户端
// 使用 mlx_lm.server，专为 Apple Silicon 优化（统一内存，零拷贝）
// 与 LlamaBridge 并行存在，GGUF/MLX 模型任意切换
// Python3.12 + mlx + mlx-lm 已内置到 Contents/Resources/python3/

import SwiftUI
import Combine

class MLXBridge: ObservableObject {
    static let shared = MLXBridge()

    private var process: Process?
    private var port: Int = 8081  // 与 llama-server 端口错开
    private let session = URLSession(configuration: {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 120
        c.timeoutIntervalForResource = 300
        return c
    }())

    @Published var isRunning = false
    @Published var serverPID: Int32 = 0
    @Published var currentModel: String? = nil
    @Published var mlxAvailable = false
    @Published var statusText = "检测中..."

    /// 内置 Python3.12 可执行文件（App bundle 内）
    private let bundledPython: String = {
        Bundle.main.bundlePath + "/Contents/Resources/python3/bin/python3.12"
    }()

    private let modelsDir: String = {
        Bundle.main.bundlePath + "/Contents/Resources/mlx-models"
    }()

    private init() {
        checkEnvironment()
    }

    // MARK: - Environment Detection

    func checkEnvironment() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            let fm = FileManager.default
            let pythonOK = fm.isExecutableFile(atPath: self.bundledPython)

            if pythonOK {
                let mlxResult = self.shell("-c", "from mlx_lm import server; print('OK')")
                let mlxOK = mlxResult.contains("OK")
                DispatchQueue.main.async {
                    self.mlxAvailable = mlxOK
                    self.statusText = mlxOK ? "MLX 已就绪" : "MLX 模块异常"
                }
            } else {
                DispatchQueue.main.async { self.statusText = "Python 引擎缺失" }
            }
        }
    }

    // MARK: - Server

    func startServer(modelRepo: String = "") {
        guard !isRunning else { return }
        stopServer()

        guard FileManager.default.isExecutableFile(atPath: bundledPython) else {
            print("[MLX] ❌ 内置 Python 不可用: \(bundledPython)")
            return
        }

        // mlx_lm server 使用 --model 参数加载 mlx-community 模型
        let repo = modelRepo.isEmpty ? detectDefaultModel() : modelRepo
        print("[MLX] 启动模型: \(repo)")

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: bundledPython)
        // 国内镜像：huggingface_hub 下载模型走 hf-mirror.com
        proc.environment = ProcessInfo.processInfo.environment.merging([
            "HF_ENDPOINT": "https://hf-mirror.com",
            "HF_HUB_ENABLE_HF_TRANSFER": "1",
        ]) { (_, new) in new }
        proc.arguments = [
            "-m", "mlx_lm", "server",
            "--model", repo,
            "--host", "127.0.0.1",
            "--port", "\(port)",
        ]

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe

        do {
            try proc.run()
            process = proc
            serverPID = proc.processIdentifier
            currentModel = repo
            print("[MLX] ✅ PID \(serverPID) 端口 \(port)")

            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                let fh = pipe.fileHandleForReading
                while proc.isRunning {
                    let data = fh.availableData
                    if !data.isEmpty, let line = String(data: data, encoding: .utf8) {
                        if line.contains("Uvicorn running") || line.contains("Application startup complete") {
                            DispatchQueue.main.async { self.isRunning = true }
                            print("[MLX] ✅ 就绪")
                        }
                    }
                }
                DispatchQueue.main.async { self.isRunning = false }
            }
        } catch {
            print("[MLX] ❌ 启动失败: \(error)")
        }
    }

    func stopServer() {
        guard let proc = process else { return }
        print("[MLX] 关闭 MLX 服务器...")
        proc.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            if proc.isRunning { proc.interrupt() }
        }
        process = nil
        isRunning = false
        serverPID = 0
    }

    private func detectDefaultModel() -> String {
        // 检测 mlx-models/ 下是否已有模型
        let files = (try? FileManager.default.contentsOfDirectory(atPath: modelsDir)) ?? []
        return files.first ?? "mlx-community/Qwen3.5-4B-4bit"
    }

    // MARK: - Chat (OpenAI-compatible, same interface as LlamaBridge)

    struct ChatRequest: Codable {
        let messages: [Message]; let stream: Bool
        struct Message: Codable { let role: String; let content: String }
    }

    struct ChatResponse: Codable {
        let choices: [Choice]
        struct Choice: Codable { let message: Message; struct Message: Codable { let content: String } }
    }

    func chat(prompt: String, system: String, completion: @escaping (String?) -> Void) {
        guard isRunning else {
            print("[MLX] ⚠️ 服务器未运行")
            completion(nil)
            return
        }

        let url = URL(string: "http://127.0.0.1:\(port)/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 120

        let body = ChatRequest(
            messages: [.init(role: "system", content: system),
                       .init(role: "user", content: prompt)],
            stream: false)

        do {
            req.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(nil); return
        }

        let start = Date()
        session.dataTask(with: req) { data, _, error in
            let elapsed = Date().timeIntervalSince(start)
            guard let data = data, error == nil,
                  let resp = try? JSONDecoder().decode(ChatResponse.self, from: data),
                  let text = resp.choices.first?.message.content else {
                let ms = Int(elapsed * 1000)
                print("[MLX] ❌ \(ms)ms: \(error?.localizedDescription ?? "解析失败")")
                completion(nil); return
            }
            let ms = Int(elapsed * 1000)
            print("[MLX] ✅ \(ms)ms: \(text.prefix(80))")
            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }

    // MARK: - Shell helper (uses bundled Python3)

    private func shell(_ args: String...) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: bundledPython)
        proc.arguments = args
        let pipe = Pipe(); proc.standardOutput = pipe; proc.standardError = pipe
        try? proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
