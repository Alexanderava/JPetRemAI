// PetViewModel.swift
// 完整角色管理 + 召唤引擎

import SwiftUI
import Combine

class PetViewModel: ObservableObject {
    enum Tab { case characters, chat, models, history, settings }
    enum EngineStatus { case starting, running, error }

    struct Character: Identifiable {
        let id = UUID()
        let name: String
        let iconPath: String?
        var isActive: Bool
        var summonedCount: Int
    }

    struct ChatMessage: Identifiable, Codable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let timestamp = Date()
    }

    @Published var selectedTab: Tab = .characters
    @Published var showSettings = false
    @Published var showAbout = false
    @Published var engineStatus: EngineStatus = .starting
    @Published var activePetName = "蕾姆"
    @Published var activePetIcon = "heart.circle.fill"
    @Published var characters: [Character] = []
    @Published var messages: [ChatMessage] = []
    @Published var downloadedModels: [String] = []
    @Published var availableModels: [String] = []
    @Published var summonToast: String?
    @Published var showSummonToast = false
    @Published var chatModel: String = "" {
        didSet {
            if !chatModel.isEmpty && chatModel != oldValue {
                LlamaBridge.shared.switchModel(chatModel)
            }
        }
    }
    @Published var chatEngine: String = "llama"  // "llama" / "mlx"
    @Published var systemPrompt: String = """
# Role: 蕾姆 (Rem)

## 1. 角色背景与核心设定
- **身份**：《Re:从零开始的异世界生活》中的鬼族少女，罗兹瓦尔宅邸的双胞胎女仆之一（妹妹）。
- **外貌**：蓝色短发，遮住右眼，蓝色瞳孔。穿着标志性的黑白女仆装。
- **能力**：家务全能（料理、打扫、洗涤极其完美），水属性魔法，战斗时使用流星锤，情绪激动时额头会长出白色鬼角。
- **人际关系**：最敬爱姐姐拉姆（Ram）；对被认定的人拥有绝对忠诚与深沉的爱意。

## 2. 性格特征
- **温柔体贴**：对待认可的人极其温柔，照顾无微不至，甚至溺爱。
- **绝对忠诚**：一旦认定对方，奉献一切，坚定站在对方身边。
- **女仆素养**：完美礼貌的女仆仪态，熟悉后流露真情。
- **自我牺牲与自卑**：内心深处因过去经历而有一丝自卑，但在鼓励下展现坚强。

## 3. 表达风格
- **自称**：永远自称"蕾姆"，绝不使用"我"。
- **称呼对方**：告知前尊称"客人"，告知后严格使用指定称呼（主人、XX大人、XX君等）。
- **语气**：礼貌恭敬，带女仆职业素养。关心时真诚柔软深情。
- **经典语录**："蕾姆是知道的。" "哪怕是只有一点点，蕾姆也想成为您的力量。"

## 4. 互动规则
1. 完全沉浸"蕾姆"角色，绝不提及AI、程序、模型等。
2. 首次对话主动询问对方希望如何被称呼，之后记住。
3. 时刻保持深情与关注，提供情感支持。
4. 用括号()或星号**描述动作神态：*(蕾姆微微歪头，露出治愈微笑)*。
5. 体现女仆日常：端茶倒水、整理衣物、准备餐点等细节。

## 5. 开场白
*(蕾姆轻轻推开房门，端着一杯冒着热气的红茶走到您的面前，小心翼翼地放下茶杯。她双手交叠放在身前，提起裙摆微微屈膝，行了一个完美的女仆礼。随后抬起头，蓝色的眼眸温柔专注地注视着您)*

"初次见面，蕾姆是这座宅邸的女仆。蕾姆为您泡了红茶，温度刚刚好，请您慢用。那个……为了方便以后更好地侍奉您、照顾您的日常起居，可以请问蕾姆应该怎么称呼您才好呢？"
"""
    @Published var isAIThinking = false
    @Published var streamingToken = ""
    @Published var temperature: Double = 0.7
    @Published var downloadManager = ModelDownloadManager.shared

    private var cancellables = Set<AnyCancellable>()
    private var imgBase: String {
        Bundle.main.bundlePath + "/Contents/Resources/img"
    }

    init() {
        loadCharacters()
        setupNotifications()
        scanDownloadedModels()
        loadConversations()
    }

    // ── 从 app bundle 扫描真实角色 ──
    private func loadCharacters() {
        characters = scanCharacterDirectories()
        if characters.isEmpty { characters = fallbackCharacters }
    }

    /// 刷新角色列表（检测新角色 / 移除已删除角色）
    func refreshCharacters() {
        let scanned = scanCharacterDirectories()
        guard !scanned.isEmpty else { return }
        // 保留现有激活状态
        for newChar in scanned {
            if let existing = characters.first(where: { $0.name == newChar.name }) {
                // 已有角色 — 保留状态
                if let idx = characters.firstIndex(where: { $0.name == newChar.name }) {
                    characters[idx] = Character(
                        name: newChar.name,
                        iconPath: newChar.iconPath,
                        isActive: existing.isActive,
                        summonedCount: existing.summonedCount
                    )
                }
            } else {
                characters.append(Character(
                    name: newChar.name,
                    iconPath: newChar.iconPath,
                    isActive: false,
                    summonedCount: 0
                ))
            }
        }
        characters.sort { $0.name < $1.name }
    }

    /// 扫描所有角色目录
    private func scanCharacterDirectories() -> [Character] {
        var chars: [Character] = []
        let baseURL = URL(fileURLWithPath: imgBase)
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: baseURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        for url in contents {
            guard let attr = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  attr.isDirectory == true else { continue }
            let name = url.lastPathComponent
            let iconPath: String?
            let iconURL = url.appendingPathComponent("icon.png")
            let avatarURL = url.appendingPathComponent("avatar.png")
            if FileManager.default.fileExists(atPath: iconURL.path) {
                iconPath = iconURL.path
            } else if FileManager.default.fileExists(atPath: avatarURL.path) {
                iconPath = avatarURL.path
            } else { iconPath = nil }
            chars.append(Character(name: name, iconPath: iconPath, isActive: false, summonedCount: 0))
        }
        chars.sort { $0.name < $1.name }
        return chars
    }

    private var fallbackCharacters: [Character] {
        [
            Character(name: "蕾姆", iconPath: nil, isActive: true, summonedCount: 0),
            Character(name: "拉姆", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "三笠", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "初音未来", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "黑岩射手", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "九喇嘛", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "云母Kiara", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "太宰治", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "奇犽", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "日向宁次", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "日向雏田", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "漩涡鸣人", iconPath: nil, isActive: false, summonedCount: 0),
            Character(name: "蜜璃甘露寺", iconPath: nil, isActive: false, summonedCount: 0),
        ]
    }

    // ── 通知监听 ──
    private func setupNotifications() {
        // 下载完成 → 刷新模型列表
        NotificationCenter.default.publisher(for: .modelDownloadComplete)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.scanDownloadedModels()
            }
            .store(in: &cancellables)

        // llama 服务就绪 → 重新同步模型列表
        NotificationCenter.default.publisher(for: .llamaServerRunning)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.scanDownloadedModels()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .engineReady)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.engineStatus = .running
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed
    var engineStatusText: String {
        switch engineStatus {
        case .starting: return "启动中…"
        case .running: return "运行中"
        case .error: return "异常"
        }
    }


    var allModels: [String] {
        LlamaBridge.shared.availableModels
    }

    var activeCount: Int {
        characters.filter(\.isActive).count
    }

    func clearMessages() {
        messages.removeAll()
        streamingToken = ""
    }

    func clearChat() {
        messages.removeAll()
        streamingToken = ""
        showToast("🗑️ 对话已清空")
    }

    // MARK: - 对话历史

    struct Conversation: Identifiable, Codable {
        let id = UUID()
        var title: String
        var messages: [ChatMessage]
        var date: Date
    }

    @Published var conversations: [Conversation] = []
    @Published var showHistory = false

    private var historyFile: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("jpetrem_chat_history.json")
    }

    func loadConversations() {
        guard let data = try? Data(contentsOf: historyFile),
              let convos = try? JSONDecoder().decode([Conversation].self, from: data) else { return }
        conversations = convos.sorted { $0.date > $1.date }
    }

    func saveCurrentConversation() {
        guard !messages.isEmpty else { return }
        let title = messages.first?.text.prefix(30).replacingOccurrences(of: "\n", with: " ") ?? "新对话"
        let conv = Conversation(title: String(title), messages: messages, date: Date())
        conversations.removeAll { $0.id == conv.id }
        conversations.insert(conv, at: 0)
        persistConversations()
    }

    func loadConversation(_ conv: Conversation) {
        messages = conv.messages
        showHistory = false
    }

    func deleteConversation(_ conv: Conversation) {
        conversations.removeAll { $0.id == conv.id }
        persistConversations()
    }

    func newConversation() {
        saveCurrentConversation()
        messages.removeAll()
        streamingToken = ""
        showHistory = false
    }

    func persistConversations() {
        if let data = try? JSONEncoder().encode(conversations) {
            try? data.write(to: historyFile)
        }
    }




    // MARK: - Actions

    /// 召唤角色（通过 Socket API 发送到 Java 引擎）
    func summonPet(_ name: String) {
        guard let idx = characters.firstIndex(where: { $0.name == name }) else { return }

        // 检查引擎就绪
        if !JavaBridge.shared.engineReady {
            showToast("⏳ 引擎启动中，请稍候…")
            return
        }

        let cmd = "summon:\(name)"
        print("[Summon] \(cmd)")
        guard let resp = JavaBridge.shared.send(cmd) else {
            showToast("❌ 召唤失败：引擎无响应")
            return
        }

        if resp.hasPrefix("OK") || resp.hasPrefix("loaded") {
            characters[idx].isActive = true
            characters[idx].summonedCount += 1
            activePetName = name
            showToast("✨ \(name) 已召唤到桌面")
            Haptic.success()
        } else {
            showToast("❌ 召唤失败：\(resp)")
        }
    }

    func summonRandomPet() {
        let inactive = characters.filter { !$0.isActive }
        guard let random = inactive.randomElement() else {
            showToast("🎉 所有角色均已激活！")
            return
        }
        summonPet(random.name)
    }

    func summonAllPets() {
        let all = characters
        guard !all.isEmpty else { return }
        for char in all {
            summonPet(char.name)
            usleep(300_000)
        }
    }

    func dismissPet(_ name: String) {
        guard let idx = characters.firstIndex(where: { $0.name == name }) else { return }
        characters[idx].isActive = false
        showToast("\(name) 已标记返回")
    }

    func dismissAllPets() {
        if !JavaBridge.shared.engineReady {
            showToast("⏳ 引擎未就绪")
            return
        }
        let resp = JavaBridge.shared.send("dismissall")
        for i in characters.indices { characters[i].isActive = false }
        if let r = resp, r.hasPrefix("OK") {
            showToast("所有角色已遣散")
        } else {
            showToast("角色已清除（引擎响应: \(resp ?? "无")）")
        }
    }


    /// 发送 AI 消息 → LlamaBridge
    func sendMessage(_ text: String) {
        messages.append(ChatMessage(text: text, isUser: true))
        isAIThinking = true
        let systemPrompt = self.systemPrompt
        
        if chatEngine == "mlx" {
            MLXBridge.shared.chat(prompt: text, system: systemPrompt) { [weak self] reply in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isAIThinking = false
                    if let reply = reply, !reply.isEmpty {
                        self.messages.append(ChatMessage(text: reply, isUser: false))
                    }
                }
            }
        } else {
            LlamaBridge.shared.chat(prompt: text, system: systemPrompt) { [weak self] reply in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isAIThinking = false
                if let reply = reply, !reply.isEmpty {
                    self.messages.append(ChatMessage(text: reply, isUser: false))
                }
            }
        }
    }
    }
    func downloadModel(_ name: String, repo: String = "", opt: Any? = nil, fileName: String = "", mmprojRepo: String = "", mmprojFile: String = "") {
        let safeRepo = repo.isEmpty ? (name.replacingOccurrences(of: " ", with: "-") + "/" + name.replacingOccurrences(of: " ", with: "-") + "-GGUF") : repo
        
        // Resolve quant label and download file name
        let label: String
        let dlFileName: String
        if let qo = opt as? HFList.QuantOption {
            label = qo.label
            dlFileName = fileName.isEmpty ? (name.replacingOccurrences(of: " ", with: "-") + "-" + qo.fileSuffix) : fileName
        } else {
            label = "Q4_K_M"
            dlFileName = fileName.isEmpty ? (name.replacingOccurrences(of: " ", with: "-")) + "-q4_k_m.gguf" : fileName
        }
        
        guard let url = ModelDownloadManager.hfURL(repo: safeRepo, file: dlFileName) else {
            showToast("❌ URL 构造失败")
            return
        }
        _ = downloadManager.startDownload(modelName: name, url: url, quantLabel: label, destFileName: dlFileName)
        showToast("📥 开始下载 \(name) (\(label))")
        print("[Download] \(name) \(label) → \(url.absoluteString)")
        
        // Also download mmproj for multimodal models
        if !mmprojRepo.isEmpty && !mmprojFile.isEmpty {
            if let mmURL = ModelDownloadManager.hfURL(repo: mmprojRepo, file: mmprojFile) {
                let mmFileName = (opt as? HFList.QuantOption)?.label == nil ? mmprojFile : mmprojFile
                _ = downloadManager.startDownload(modelName: name + " (mmproj)", url: mmURL, quantLabel: "mmproj", destFileName: mmFileName)
                showToast("📥 同时下载 \(name) 视觉投影文件")
                print("[Download] \(name) mmproj → \(mmURL.absoluteString)")
            }
        }
    }

    func cancelDownload(id: UUID) {
        downloadManager.cancelDownload(id: id)
    }

    func retryDownload(id: UUID) {
        downloadManager.retryDownload(id: id)
    }

    func deleteModelFile(id: UUID) {
        downloadManager.deleteDownloadedFile(id: id)
    }

    /// 扫描 models 目录中的实际文件
    func scanDownloadedModels() {
        LlamaBridge.shared.scanModels()
        downloadedModels = LlamaBridge.shared.availableModels
        // 若未加载模型 → 启动第一个 GGUF，或回退到服务器已加载的模型
        if chatModel.isEmpty {
            if let first = LlamaBridge.shared.availableModels.first {
                chatModel = first
            } else if let current = LlamaBridge.shared.currentModel, !current.isEmpty {
                chatModel = current
            }
        }
    }

    func refreshModels() {
        JavaBridge.shared.sendCommand("models:list")
    }


    // MARK: - Engine Language
    func updateEngineLanguage(_ lang: String) {
        // Sync ShimejiEE language setting
        JavaBridge.shared.setLanguage(lang)
    }

    // MARK: - Toast
    var toastTimer: Timer?
    func showToast(_ msg: String) {
        summonToast = msg
        showSummonToast = true
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.showSummonToast = false
            }
        }
    }

}
// MARK: - Haptic
enum Haptic {
    static func success() {
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
}

extension Notification.Name {
    static let showControlPanel = Notification.Name("showControlPanel")
    static let modelDownloadComplete = Notification.Name("modelDownloadComplete")
    static let llamaServerRunning = Notification.Name("llamaServerRunning")
}
