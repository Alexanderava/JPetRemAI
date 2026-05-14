// LlamaBridge.swift
// llama.cpp server 生命周期管理 + OpenAI 兼容 API 客户端
// 替代 JavaBridge 的 chat: 文本响应和本地 simulateResponse()

import SwiftUI
import Combine

class LlamaBridge: ObservableObject {
    static let shared = LlamaBridge()

    private var process: Process?
    private var port: Int = 8080
    private let session = URLSession(configuration: {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 120
        c.timeoutIntervalForResource = 300
        return c
    }())

    @Published var isRunning = false
    @Published var serverPID: Int32 = 0
    @Published var currentModel: String? = nil       // 当前加载的模型文件名
    @Published var availableModels: [String] = []    // models/ 下所有 .gguf

    private init() {}

    // MARK: - Model scanning

    var modelsDir: String {
        Bundle.main.bundlePath + "/Contents/Resources/models"
    }

    func scanModels() {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: modelsDir)) ?? []
        availableModels = files.filter { $0.hasSuffix(".gguf") }.sorted()
    }

    // MARK: - Server

    /// 启动 llama-server，指定模型（nil=自动选第一个）
    func startServer(modelName: String? = nil) {
        guard !isRunning else { return }
        stopServer()

        let serverBin = Bundle.main.bundlePath + "/Contents/Resources/llama/bin/llama-server"
        guard FileManager.default.fileExists(atPath: serverBin) else {
            print("[Llama] ❌ 未找到 llama-server")
            return
        }

        // 确定模型文件
        let allModels = (try? FileManager.default.contentsOfDirectory(atPath: modelsDir)) ?? []
        let ggufs = allModels.filter { $0.hasSuffix(".gguf") }
        guard !ggufs.isEmpty else {
            print("[Llama] ❌ models/ 中没有 GGUF 文件，跳过启动")
            return
        }

        let modelFile: String
        if let name = modelName, let match = ggufs.first(where: { $0 == name || $0 == name + ".gguf" || $0.hasPrefix(name) }) {
            modelFile = match
        } else {
            modelFile = ggufs.first!
        }
        let modelPath = modelsDir + "/" + modelFile

        print("[Llama] 启动模型: \(modelFile)")

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: serverBin)
        proc.arguments = [
            "-m", modelPath,
            "--host", "127.0.0.1",
            "--port", "\(port)",
            "-ngl", "99",
            "-c", "4096",
            "--threads", "\(ProcessInfo.processInfo.activeProcessorCount)",
            "--no-webui",
        ]
        proc.currentDirectoryURL = URL(fileURLWithPath: modelsDir)

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe

        do {
            try proc.run()
            process = proc
            serverPID = proc.processIdentifier
            currentModel = modelFile
            print("[Llama] ✅ PID \(serverPID) 端口 \(port)")

            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                let fh = pipe.fileHandleForReading
                while proc.isRunning {
                    let data = fh.availableData
                    if !data.isEmpty, let line = String(data: data, encoding: .utf8) {
                        if line.contains("HTTP server listening") || line.contains("server is listening") {
                            DispatchQueue.main.async { self.isRunning = true; NotificationCenter.default.post(name: .llamaServerRunning, object: nil) }
                            print("[Llama] ✅ 就绪")
                        }
                    }
                }
                DispatchQueue.main.async { self.isRunning = false }
            }
        } catch {
            print("[Llama] ❌ 启动失败: \(error)")
        }
    }

    /// 切换模型（停服 → 重新加载新模型 → 启动）
    func switchModel(_ modelName: String) {
        print("[Llama] 切换模型: \(modelName)")
        stopServer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.startServer(modelName: modelName)
        }
    }

    func stopServer() {
        guard let proc = process else { return }
        print("[Llama] 关闭服务器...")
        proc.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            if proc.isRunning { proc.interrupt() }
        }
        process = nil
        isRunning = false
        serverPID = 0
    }

    // MARK: - Chat (OpenAI-compatible)

    struct ChatRequest: Codable {
        let messages: [Message]
        let stream: Bool
        var temperature: Double = 0.7
        struct Message: Codable {
            let role: String
            let content: String
        }
    }

    struct ChatResponse: Codable {
        let choices: [Choice]
        struct Choice: Codable {
            let message: Message
            struct Message: Codable {
                let content: String
            }
        }
    }

    /// 流式聊天 — SSE token-by-token，实时推送到 UI
    func chatStream(prompt: String, system: String, temperature: Double = 0.7,
                    onToken: @escaping (String) -> Void,
                    onDone: @escaping (String?) -> Void) {
        guard isRunning else { print("[Llama] ⚠️ 未运行"); onDone(nil); return }
        let url = URL(string: "http://127.0.0.1:\(port)/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 180
        let body = ChatRequest(
            messages: [.init(role: "system", content: system), .init(role: "user", content: prompt)],
            stream: true, temperature: temperature
        )
        do { req.httpBody = try JSONEncoder().encode(body) } catch { onDone(nil); return }
        let del = SSEDelegate(onToken: onToken, onDone: onDone)
        let s = URLSession(configuration: .default, delegate: del, delegateQueue: nil)
        del.task = s.dataTask(with: req); del.task?.resume()
    }

    private class SSEDelegate: NSObject, URLSessionDataDelegate {
        let onToken: (String) -> Void; let onDone: (String?) -> Void
        var task: URLSessionDataTask?; var full = ""; var buf = ""
        init(onToken: @escaping (String) -> Void, onDone: @escaping (String?) -> Void) {
            self.onToken = onToken; self.onDone = onDone
        }
        func urlSession(_ s: URLSession, dataTask: URLSessionDataTask, didReceive d: Data) {
            buf += String(data: d, encoding: .utf8) ?? ""
            let lines = buf.components(separatedBy: "\n"); buf = lines.last ?? ""
            for line in lines.dropLast() {
                guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
                let json = String(line.dropFirst(6))
                guard let d = json.data(using: .utf8),
                      let o = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                      let ch = o["choices"] as? [[String: Any]],
                      let dt = ch.first?["delta"] as? [String: Any],
                      let tk = dt["content"] as? String, !tk.isEmpty else { continue }
                full += tk; DispatchQueue.main.async { self.onToken(tk) }
            }
        }
        func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError e: Error?) {
            DispatchQueue.main.async { self.onDone(self.full.trimmingCharacters(in: .whitespacesAndNewlines)) }
        }
    }

    func chat(prompt: String, system: String, completion: @escaping (String?) -> Void) {
        guard isRunning else {
            print("[Llama] ⚠️ 服务器未运行，使用离线模式")
            completion(nil)
            return
        }

        let url = URL(string: "http://127.0.0.1:\(port)/v1/chat/completions")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 120

        let body = ChatRequest(
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: prompt)
            ],
            stream: false
        )

        do {
            req.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(nil)
            return
        }

        let start = Date()
        session.dataTask(with: req) { data, _, error in
            let elapsed = Date().timeIntervalSince(start)
            guard let data = data, error == nil,
                  let resp = try? JSONDecoder().decode(ChatResponse.self, from: data),
                  let text = resp.choices.first?.message.content else {
                let ms = Int(elapsed * 1000); print("[Llama] ❌ \(ms)ms: \(error?.localizedDescription ?? "解析失败")")
                completion(nil)
                return
            }
            let ms = Int(elapsed * 1000); print("[Llama] ✅ \(ms)ms: \(text.prefix(80))")
            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}
