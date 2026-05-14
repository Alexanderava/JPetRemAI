// JavaBridge.swift
// ShimejiEE 宠物引擎 — TCP Socket 通信

import Foundation

final class JavaBridge {
    static let shared = JavaBridge()

    private let host = "127.0.0.1"
    private var port: UInt16 = 17521
    private var process: Process?
    private var processPid: Int32 = 0
    var engineReady: Bool { _engineReady }
    private var _engineReady = false

    private init() {}

    func startEngine() {
        let res = Bundle.main.bundlePath + "/Contents/Resources"
        let javaBin = Bundle.main.bundlePath + "/Contents/Java/Home/bin/java"
        let libPath = res + "/lib"

        guard FileManager.default.fileExists(atPath: res + "/StartupLoader.class") else {
            print("[Bridge] ❌ StartupLoader.class 未找到"); return
        }

        // Sync language to ShimejiEE engine
        let lang = UserDefaults.standard.string(forKey: "userLanguage") ?? "en-US"
        let settingsPath = res + "/conf/settings.properties"
        if var props = try? String(contentsOfFile: settingsPath, encoding: .utf8) {
            props = props.replacingOccurrences(
                of: "Language=.*",
                with: "Language=" + lang,
                options: .regularExpression
            )
            try? props.write(toFile: settingsPath, atomically: true, encoding: .utf8)
            print("[Bridge] 🌐 Engine language → " + lang)
        }

        killExistingJavas()
        Thread.sleep(forTimeInterval: 0.2)

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: javaBin)
        proc.arguments = [
            "-noverify",
            "-Xmx512m", "-Xms64m",
            "-Dapple.awt.UIElement=true",
            "-Dapple.laf.useScreenMenuBar=true",
            "-Dsun.java2d.opengl=true",
            "-Dapple.awt.graphics.UseQuartz=true",
            "-Djava.awt.headless=false",
            "-Dfile.encoding=UTF-8",
            "-Duser.dir=" + res,
            "-Djava.library.path=" + libPath,
            "-cp",
            ".:ShimejiEE.jar:flatlaf-3.5.1.jar:lib/*",
            "StartupLoader"
        ]
        proc.currentDirectoryURL = URL(fileURLWithPath: res)

        let logDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs/JPetRemAI")
        try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true)
        let logFile = logDir.appendingPathComponent("shimeji.log")
        if FileManager.default.fileExists(atPath: logFile.path) {
            try? FileManager.default.removeItem(at: logFile)
        }
        FileManager.default.createFile(atPath: logFile.path, contents: nil)
        if let fh = FileHandle(forWritingAtPath: logFile.path) {
            proc.standardOutput = fh
            proc.standardError = fh
        }

        do {
            try proc.run()
            process = proc
            processPid = proc.processIdentifier
            print("[Bridge] ✅ PID \(proc.processIdentifier)")

            DispatchQueue.global().async { [weak self] in
                proc.waitUntilExit()
                print("[Bridge] ⚠️ Java 引擎已退出 (code: \(proc.terminationStatus))")
                self?._engineReady = false
            }

            DispatchQueue.global().async { [weak self] in
                var ready = false
                let deadline = Date().addingTimeInterval(10)
                while Date() < deadline && !ready {
                    Thread.sleep(forTimeInterval: 0.3)
                    if let resp = self?.send("ping"), resp.hasPrefix("pong") {
                        ready = true
                    }
                }
                self?._engineReady = ready
                if ready {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: .engineReady, object: nil)
                    }
                }
                print(ready ? "[Bridge] ✅ 引擎就绪" : "[Bridge] ⚠️ 超时 (10s)")
            }
        } catch {
            print("[Bridge] ❌ 启动失败: \(error)")
        }
    }

    func stopEngine() {
        guard let proc = process else { return }
        proc.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            if proc.isRunning { proc.interrupt() }
        }
        process = nil
    }

    /// Set engine language + restart if running
    func setLanguage(_ langCode: String) {
        let res = Bundle.main.bundlePath + "/Contents/Resources"
        let settingsPath = res + "/conf/settings.properties"
        if var props = try? String(contentsOfFile: settingsPath, encoding: .utf8) {
            props = props.replacingOccurrences(
                of: "Language=.*",
                with: "Language=" + langCode,
                options: .regularExpression
            )
            try? props.write(toFile: settingsPath, atomically: true, encoding: .utf8)
        }
        // Restart engine to apply new language
        stopEngine()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.startEngine()
        }
        print("[Bridge] 🌐 Language set → " + langCode + " (restarting engine)")
    }

    /// 发送命令 — 每次新建 TCP 连接（匹配 ShimejiClient 协议）
    /// 返回服务器响应字符串，失败返回 nil
    func send(_ cmd: String) -> String? {
        let s = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard s >= 0 else { print("[Bridge] socket() 失败"); return nil }
        defer { Darwin.close(s) }

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = inet_addr(host)

        let r = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(s, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard r == 0 else { return nil }

        var tv = timeval(tv_sec: 2, tv_usec: 0)
        setsockopt(s, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        let data = (cmd + "\n").data(using: .utf8) ?? Data()
        _ = data.withUnsafeBytes { Darwin.write(s, $0.baseAddress!, data.count) }

        var buf = [UInt8](repeating: 0, count: 8192)
        let n = Darwin.read(s, &buf, 8192)
        if n > 0, let resp = String(data: Data(buf[0..<n]), encoding: .utf8) {
            let t = resp.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !t.isEmpty { print("[Bridge ←] \(t.prefix(200))") }
            return t
        }
        return nil
    }

    @available(*, deprecated, message: "use send(_:) which returns String?")
    func sendCommand(_ cmd: String) -> Bool {
        return send(cmd) != nil
    }

    private func killExistingJavas() {
        let p = Process()
        p.launchPath = "/usr/bin/pkill"; p.arguments = ["-9", "-f", "ShimejiEE.jar"]
        try? p.run(); p.waitUntilExit()
    }
}

extension Notification.Name {
    static let engineReady = Notification.Name("engineReady")
}
