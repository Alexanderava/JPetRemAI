// AccessibilityBridge.swift
// 辅助功能权限请求 + 本地通知

import AppKit
import UserNotifications

enum AccessibilityBridge {
    static func requestPermission() {
        // 先静默检查已授权 → 不再弹窗
        if AXIsProcessTrusted() {
            print("[Accessibility] ✅ 辅助功能权限已授权")
            return
        }
        // 未授权 → 弹出系统权限对话框
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted {
            print("[Accessibility] ✅ 辅助功能权限已授权")
        } else {
            print("[Accessibility] ⚠️ 需要辅助功能权限 — 请在系统设置中授权")
        }
    }

    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            print("[Notification] \(granted ? "✅" : "❌") 通知权限")
        }
    }
}