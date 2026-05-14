// ModelDownloadManager.swift
// 完整模型下载引擎 — URLSession 进度跟踪 + models 文件夹管理

import SwiftUI
import Combine

class ModelDownloadManager: ObservableObject {
    static let shared = ModelDownloadManager()

    struct DownloadTask: Identifiable {
        let id = UUID()
        let modelName: String
        let url: URL
        let quantLabel: String
        let destFileName: String
        var status: Status = .pending
        var downloadedBytes: Int64 = 0
        var totalBytes: Int64 = 0
        var sessionTask: URLSessionDownloadTask?
        var speedBytesPerSec: Double = 0
        var lastBytes: Int64 = 0
        var lastTime: Date = Date()

        enum Status: Equatable {
            case pending
            case downloading
            case completed(localPath: String)
            case failed(String)
            case cancelled

            var label: String {
                switch self {
                case .pending: return "等待中"
                case .downloading: return "下载中"
                case .completed: return "已完成"
                case .failed: return "失败"
                case .cancelled: return "已取消"
                }
            }
        }
    }

    @Published var downloads: [UUID: DownloadTask] = [:]
    @Published var overallProgress: Double = 0

    /// 模型存储目录 (app bundle 内)
    static var modelsDir: String {
        Bundle.main.bundlePath + "/Contents/Resources/models"
    }

    private var urlSession: URLSession!

    private init() {
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: DownloadDelegate(manager: self), delegateQueue: .main)
        ensureModelsDir()
    }

    func ensureModelsDir() {
        try? FileManager.default.createDirectory(atPath: Self.modelsDir,
                                                  withIntermediateDirectories: true)
    }

    // MARK: - Download

    /// 国内镜像源（hf-mirror.com）
    static let mirrorBase = "https://hf-mirror.com"

    /// 构造 HuggingFace GGUF 下载 URL（国内镜像）
    static func hfURL(repo: String, file: String) -> URL? {
        let path = "\(mirrorBase)/\(repo)/resolve/main/\(file)"
        return URL(string: path)
    }

    /// 启动下载（destFileName 为保存到 models/ 的文件名）
    func startDownload(modelName: String, url: URL, quantLabel: String, destFileName: String = "") -> UUID {
        let dest = destFileName.isEmpty ? (modelName.replacingOccurrences(of: " ", with: "-") + "-" + quantLabel + ".gguf") : destFileName
        // 去重：清除同名同量化的旧任务（已完成/失败/取消），正在下载的保留
        if let existing = downloads.values.first(where: { $0.modelName == modelName && $0.quantLabel == quantLabel }) {
            switch existing.status {
            case .completed, .failed, .cancelled:
                downloads.removeValue(forKey: existing.id)
            default:
                return existing.id
            }
        }

        var task = DownloadTask(modelName: modelName, url: url, quantLabel: quantLabel, destFileName: dest)
        task.status = .downloading

        let dt = urlSession.downloadTask(with: url)
        dt.resume()

        task.sessionTask = dt
        downloads[task.id] = task
        recalcProgress()
        return task.id
    }

    /// 取消下载
    func cancelDownload(id: UUID) {
        guard var task = downloads[id] else { return }
        task.sessionTask?.cancel()
        task.status = .cancelled
        downloads[id] = task
    }

    /// 重试下载
    func retryDownload(id: UUID) {
        guard let task = downloads[id] else { return }
        let url = task.url; let name = task.modelName; let q = task.quantLabel; let f = task.destFileName
        downloads.removeValue(forKey: id)
        _ = startDownload(modelName: name, url: url, quantLabel: q, destFileName: f)
    }

    /// 删除已下载文件
    func deleteDownloadedFile(id: UUID) {
        guard let task = downloads[id],
              case .completed(let path) = task.status else { return }
        try? FileManager.default.removeItem(atPath: path)
        downloads.removeValue(forKey: id)
        recalcProgress()
    }

    /// 清理所有已完成 / 失败的下载
    func clearHistory() {
        downloads = downloads.filter {
            if case .downloading = $0.value.status { return true }
            if case .pending = $0.value.status { return true }
            return false
        }
        recalcProgress()
    }

    // MARK: - Query

    var activeCount: Int {
        downloads.values.filter {
            if case .downloading = $0.status { return true }
            if case .pending = $0.status { return true }
            return false
        }.count
    }

    var completedModels: [DownloadTask] {
        downloads.values.filter { if case .completed = $0.status { return true }; return false }
    }

    var totalDownloadedBytes: Int64 {
        downloads.values.reduce(0) { $0 + $1.downloadedBytes }
    }

    func progress(for id: UUID) -> Double {
        guard let task = downloads[id], task.totalBytes > 0 else { return 0 }
        return Double(task.downloadedBytes) / Double(task.totalBytes)
    }

    private func recalcProgress() {
        let active = downloads.values.filter { $0.totalBytes > 0 }
        guard !active.isEmpty else { overallProgress = 0; return }
        let done = active.reduce(0.0) { $0 + Double($1.downloadedBytes) }
        let total = active.reduce(0.0) { $0 + Double($1.totalBytes) }
        overallProgress = total > 0 ? done / total : 0
    }


    // MARK: - Delegate (inner class to avoid NSObject on main class)
    class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
        weak var manager: ModelDownloadManager?

        init(manager: ModelDownloadManager) {
            self.manager = manager
        }

        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                        didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
                        totalBytesExpectedToWrite: Int64) {
            guard let m = manager else { return }
            for (id, var task) in m.downloads where task.sessionTask == downloadTask {
                task.downloadedBytes = totalBytesWritten
                task.totalBytes = totalBytesExpectedToWrite
                let now = Date()
                let elapsed = now.timeIntervalSince(task.lastTime)
                if elapsed >= 0.5 {
                    task.speedBytesPerSec = Double(totalBytesWritten - task.lastBytes) / elapsed
                    task.lastBytes = totalBytesWritten
                    task.lastTime = now
                }
                DispatchQueue.main.async {
                    m.downloads[id] = task
                    m.recalcProgress()
                }
                break
            }
        }

        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                        didFinishDownloadingTo location: URL) {
            guard let m = manager else { return }
            // Check HTTP status code
            let httpResp = downloadTask.response as? HTTPURLResponse
            let statusCode = httpResp?.statusCode ?? 0
            for (id, var task) in m.downloads where task.sessionTask == downloadTask {
                // Reject non-200 responses
                guard statusCode == 200 else {
                    let msg = "HTTP \(statusCode): \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
                    task.status = .failed(msg)
                    DispatchQueue.main.async { m.downloads[id] = task }
                    print("[Download] ❌ \(task.modelName) → \(msg)")
                    break
                }
                // Verify downloaded file size > 0
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: location.path)[.size] as? Int64) ?? 0
                guard fileSize > 0 else {
                    task.status = .failed("下载文件为空")
                    DispatchQueue.main.async { m.downloads[id] = task }
                    print("[Download] ❌ \(task.modelName) → 文件为空")
                    break
                }
                let dest = URL(fileURLWithPath: ModelDownloadManager.modelsDir).appendingPathComponent(task.destFileName)
                try? FileManager.default.removeItem(at: dest)
                do {
                    try FileManager.default.moveItem(at: location, to: dest)
                    task.status = .completed(localPath: dest.path)
                    task.downloadedBytes = task.totalBytes
                    DispatchQueue.main.async {
                        m.downloads[id] = task
                        m.recalcProgress()
                    }
                    let szLabel = fileSize < 1024 ? "\(fileSize) B" : fileSize < 1048576 ? String(format: "%.1f KB", Double(fileSize)/1024) : fileSize < 1073741824 ? String(format: "%.1f MB", Double(fileSize)/1048576) : String(format: "%.2f GB", Double(fileSize)/1073741824)
                    print("[Download] ✅ \(task.modelName) → \(task.destFileName) (\(szLabel))")
                    DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("modelDownloadComplete"), object: nil,
                                                            userInfo: ["file": task.destFileName, "path": dest.path])
                        }
                } catch {
                    task.status = .failed("文件移动失败: \(error.localizedDescription)")
                    m.downloads[id] = task
                }
                break
            }
        }

        func urlSession(_ session: URLSession, task urlTask: URLSessionTask,
                        didCompleteWithError error: Error?) {
            guard let m = manager else { return }
            // Handle network error
            if let error = error {
                for (id, var dTask) in m.downloads where dTask.sessionTask == urlTask {
                    if case .completed = dTask.status { break }
                    let nsErr = error as NSError
                    if nsErr.domain == NSURLErrorDomain && nsErr.code == NSURLErrorCancelled {
                        dTask.status = .cancelled
                    } else {
                        dTask.status = .failed(error.localizedDescription)
                    }
                    m.downloads[id] = dTask
                    break
                }
                return
            }
            // No NSURLError but check HTTP status for failed requests
            let httpResp = urlTask.response as? HTTPURLResponse
            let statusCode = httpResp?.statusCode ?? 0
            if statusCode != 0 && statusCode != 200 {
                for (id, var dTask) in m.downloads where dTask.sessionTask == urlTask {
                    if case .completed = dTask.status { break }
                    dTask.status = .failed("HTTP \(statusCode): \(HTTPURLResponse.localizedString(forStatusCode: statusCode))")
                    m.downloads[id] = dTask
                    break
                }
            }
        }
    }
}
