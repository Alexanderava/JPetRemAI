// JPetRemAIApp.swift
// 主入口 — 液态玻璃沉浸式 + ShimejiEE 桌面宠物

import SwiftUI
import AppKit

@main
struct JPetRemAIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = PetViewModel()
    @StateObject private var llama = LlamaBridge.shared
    @StateObject private var mlx = MLXBridge.shared
    @StateObject private var i18n = I18NManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(llama)
                .environmentObject(mlx)
                .environmentObject(i18n)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock 图标
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }

        // 启动 ShimejiEE 宠物引擎（后台，秒开）
        DispatchQueue.global().async {
            JavaBridge.shared.startEngine()
        }

        // 启动 AI 引擎
        LlamaBridge.shared.scanModels()
        LlamaBridge.shared.startServer()

        // 窗口风格
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = true
            window.level = .normal
            window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        JavaBridge.shared.stopEngine()
    }
}
