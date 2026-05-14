// I18N.swift
// 多语言管理器 — 从 I18N.json 加载翻译，通过 @EnvironmentObject 注入 SwiftUI

import Foundation
import SwiftUI

final class I18NManager: ObservableObject {
    static let shared = I18NManager()

    @AppStorage("userLanguage") var currentLang: String = "en-US"
    @Published private var translations: [String: [String: String]] = [:]

    private init() {
        load()
    }

    /// 取翻译，key 不存在时返回 key 本身
    func t(_ key: String) -> String {
        translations[key]?[currentLang] ?? key
    }

    /// 切换语言 + 通知所有视图刷新
    func setLanguage(_ lang: String) {
        currentLang = lang
        objectWillChange.send()
    }

    /// 重新加载 I18N.json（用于 App 更新后新增 key）
    func reload() {
        load()
        objectWillChange.send()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "I18N", withExtension: "json") else {
            print("[I18N] ⚠️ I18N.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            translations = try JSONDecoder().decode([String: [String: String]].self, from: data)
            print("[I18N] ✅ Loaded \(translations.count) keys")
        } catch {
            print("[I18N] ❌ Decode error: \(error)")
        }
    }
}

/// 便捷 View 扩展：直接用 i18n("key") 在 View 中调用
/// 需配合 @EnvironmentObject var i18n: I18NManager 使用
extension I18NManager {
    /// 下标方便调用：i18n["key"]
    subscript(_ key: String) -> String { t(key) }
}
