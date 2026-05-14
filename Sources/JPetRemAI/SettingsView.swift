// SettingsView.swift
// 偏好设置 —— 圆角液态玻璃设计

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: PetViewModel
    @AppStorage("userLanguage") private var language = "en-US"
    @AppStorage("autoStart") private var autoStart = false
    @AppStorage("useDarkMode") private var useDarkMode = true
    @AppStorage("llamaServerPort") private var llamaPort = 8080
    @AppStorage("useHuggingFace") private var useHuggingFace = true
    @AppStorage("useLMStudio") private var useLMStudio = false
    @AppStorage("hfMirrorURL") private var mirrorURL = "https://hf-mirror.com"
    @EnvironmentObject var i18n: I18NManager
    @State private var tempSliderDrag = false
    @State private var settingsTab = 0
    @State private var showQRCode = false

    let languages = [
        ("zh-CN", "🇨🇳 简体中文"), ("zh-TW", "🇹🇼 繁体中文"), ("ja-JP", "🇯🇵 日本語"),
        ("en-US", "🇺🇸 English"), ("ko-KR", "🇰🇷 한국어"), ("de-DE", "🇩🇪 Deutsch"),
        ("fr-FR", "🇫🇷 Français"), ("es-ES", "🇪🇸 Español"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            // ── Tab sidebar (圆角标签栏) ──
            VStack(spacing: 2) {
                settingsTabButton(0, i18n["tab.general"], "gearshape")
                settingsTabButton(1, i18n["tab.ai_model"], "cpu")
                settingsTabButton(2, i18n["tab.appearance"], "paintpalette")
                settingsTabButton(3, i18n["tab.shortcuts"], "keyboard")
                Spacer()
            }
            .frame(width: 140)
            .padding(.vertical, 16).padding(.trailing, 8)

            Divider()

            // ── Content ──
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    switch settingsTab {
                    case 0: generalContent
                    case 1: aiContent
                    case 2: appearanceContent
                    case 3: shortcutContent
                    default: EmptyView()
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 580, height: 480)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cr: 20))
        .overlay(RoundedRectangle(cr: 20).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 20, y: 6)
        .sheet(isPresented: $showQRCode) {
            QRCodeSheet()
        }
    }

    @ViewBuilder
    func settingsTabButton(_ tag: Int, _ title: String, _ icon: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { settingsTab = tag }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 11))
                Text(title).font(.system(size: 11, design: .rounded))
                Spacer()
            }
            .foregroundStyle(settingsTab == tag ? .primary : .secondary)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background {
                if settingsTab == tag {
                    RoundedRectangle(cr: 8).fill(.ultraThinMaterial)
                        .overlay(RoundedRectangle(cr: 8).strokeBorder(.white.opacity(0.08), lineWidth: 0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    // MARK: - Section helper
    func sectionHeader(_ t: String) -> some View {
        Text(t).font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary)
            .padding(.horizontal, 12).padding(.top, 16).padding(.bottom, 6)
    }

    func sectionCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(12)
            .background(RoundedRectangle(cr: 12).fill(.ultraThinMaterial.opacity(0.6)))
            .overlay(RoundedRectangle(cr: 12).strokeBorder(.white.opacity(0.06), lineWidth: 0.5))
    }

    // MARK: - General
    var generalContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(i18n["settings.feedback"])
            sectionCard {
                HStack {
                    Text(i18n["settings.feedback"]).font(.system(size: 11))
                    Spacer()
                    Link("xingxing6452@gmail.com", destination: URL(string: "mailto:xingxing6452@gmail.com")!)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.blue)
                }
            }

            sectionHeader(i18n["settings.support"])
            sectionCard {
                Button {
                    showQRCode = true
                } label: {
                    HStack {
                        Text(i18n["settings.view_qrcode"]).font(.system(size: 11))
                        Spacer()
                        Image(systemName: "qrcode").font(.system(size: 13)).foregroundStyle(.blue)
                    }
                }.buttonStyle(.plain)
            }

            sectionHeader(i18n["settings.language"])
            sectionCard {
                Picker(i18n["settings.interface"], selection: $language) {
                    ForEach(languages, id: \.0) { code, name in Text(name).tag(code) }
                }.pickerStyle(.menu).font(.system(size: 11))
                .onChange(of: language) { _, newLang in
                    viewModel.updateEngineLanguage(newLang)
                }
            }

            sectionHeader(i18n["settings.startup"])
            sectionCard {
                HStack { Text(i18n["settings.autostart"]).font(.system(size: 11)); Spacer(); Toggle("", isOn: $autoStart).labelsHidden() }
                Divider().opacity(0.3).padding(.vertical, 6)
                HStack { Text(i18n["settings.restore_pets"]).font(.system(size: 11)); Spacer(); Toggle("", isOn: .constant(true)).labelsHidden() }
            }

            sectionHeader(i18n["settings.system_status"])
            sectionCard {
                statusRow(i18n["settings.system_status"], viewModel.engineStatus == .running ? i18n["status.engine_running"] : i18n["status.engine_stopped"],
                          viewModel.engineStatus == .running ? .green : .orange)
                Divider().opacity(0.3).padding(.vertical, 6)
                labelRow(i18n["status.models_loaded"], "\(viewModel.downloadedModels.count) 个")
                Divider().opacity(0.3).padding(.vertical, 6)
                HStack {
                    Text(i18n["ui.model_dir"]).font(.system(size: 11)); Spacer()
                    Button { NSWorkspace.shared.open(URL(fileURLWithPath: ModelDownloadManager.modelsDir)) } label: {
                        Text(i18n["ui.open"]).font(.system(size: 10)).padding(.horizontal, 8).padding(.vertical, 2)
                            .background(RoundedRectangle(cr: 5).fill(.ultraThinMaterial))
                    }.buttonStyle(.plain)
                }
            }

            sectionHeader(i18n["settings.about"])
            sectionCard {
                aboutRow("版本", "6.0.0 (build 600)")
                Divider().opacity(0.3).padding(.vertical, 6)
                aboutRow("构建平台", "macOS 26 · arm64")
                Divider().opacity(0.3).padding(.vertical, 6)
                aboutRow("Java Engine", "OpenJDK 17")
                Divider().opacity(0.3).padding(.vertical, 6)
                aboutRow("构建日期", "2026-05-13")
            }
        }
    }

    // MARK: - AI
    var aiContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(i18n["settings.model_source"])
            sectionCard {
                labeledTF(i18n["settings.mirror"], $mirrorURL)
                Divider().opacity(0.3).padding(.vertical, 6)
                HStack { Text(i18n["settings.huggingface"]).font(.system(size: 11)); Spacer(); Toggle("", isOn: $useHuggingFace).labelsHidden() }
                Divider().opacity(0.3).padding(.vertical, 6)
                HStack { Text(i18n["settings.lmstudio"]).font(.system(size: 11)); Spacer(); Toggle("", isOn: $useLMStudio).labelsHidden() }
            }

            sectionHeader(i18n["settings.inference"])
            sectionCard {
                HStack {
                    Text(i18n["settings.llama_port"]).font(.system(size: 11)); Spacer()
                    TextField("8080", value: $llamaPort, format: .number).frame(width: 60).multilineTextAlignment(.trailing)
                        .font(.system(size: 11, design: .monospaced))
                }
                Divider().opacity(0.3).padding(.vertical, 6)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(i18n["chat.temperature"]).font(.system(size: 11))
                        Spacer()
                        Text(String(format: "%.1f", viewModel.temperature))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(tempSliderDrag ? .blue : .secondary)
                            .frame(width: 24)
                    }
                    Slider(value: $viewModel.temperature, in: 0.1...2.0, step: 0.1,
                           onEditingChanged: { tempSliderDrag = $0 })
                }
                .animation(.easeOut(duration: 0.15), value: tempSliderDrag)
            }

            sectionHeader(i18n["chat.system_prompt"])
            sectionCard {
                TextEditor(text: $viewModel.systemPrompt)
                    .font(.system(size: 10, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .frame(height: 100)
            }

            sectionHeader(i18n["settings.current_model"])
            sectionCard {
                labelRow("模型名", viewModel.chatModel.replacingOccurrences(of: ".gguf", with: ""))
            }

            sectionHeader(i18n["settings.cache"])
            sectionCard {
                Button { viewModel.downloadedModels.removeAll() } label: {
                    Label(i18n["models.clear_cache"], systemImage: "trash").font(.system(size: 11))
                }.buttonStyle(.borderless).foregroundStyle(.red)
                Divider().opacity(0.3).padding(.vertical, 6)
                Button {
                    viewModel.conversations.removeAll()
                    viewModel.persistConversations()
                } label: {
                    Label(i18n["chat.clear_history"], systemImage: "trash").font(.system(size: 11))
                }.buttonStyle(.borderless).foregroundStyle(.red)
            }
        }
    }

    // MARK: - Appearance
    var appearanceContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(i18n["settings.theme"])
            sectionCard {
                HStack { Text(i18n["settings.follow_system"]).font(.system(size: 11)); Spacer(); Toggle("", isOn: $useDarkMode).labelsHidden() }
                Text(i18n["settings.restart_hint"]).font(.system(size: 9)).foregroundStyle(.tertiary).padding(.top, 2)
            }

            sectionHeader(i18n["settings.accent_color"])
            sectionCard {
                HStack(spacing: 14) {
                    ForEach([Color.purple, .blue, .pink, .green, .orange, .mint], id: \.self) { c in
                        Circle().fill(c).frame(width: 22, height: 22)
                            .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: c == .purple ? 2.5 : 0))
                            .shadow(color: c.opacity(0.3), radius: 3, y: 1)
                    }
                }
            }

            sectionHeader(i18n["settings.glass"])
            sectionCard {
                VStack(spacing: 8) {
                    HStack {
                        Text(i18n["settings.glass_blur"]).font(.system(size: 11)); Spacer()
                        Slider(value: .constant(0.7), in: 0.3...1.0).frame(width: 120)
                    }
                    HStack {
                        Text(i18n["settings.corner_radius"]).font(.system(size: 11)); Spacer()
                        Slider(value: .constant(14.0), in: 6...24).frame(width: 120)
                    }
                }
            }
        }
    }

    // MARK: - Shortcuts
    var shortcutContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(i18n["settings.global_shortcuts"])
            sectionCard {
                shortcutItem(i18n["shortcut.control_panel"], "⌘ ⇧ J")
                Divider().opacity(0.3).padding(.vertical, 6)
                shortcutItem(i18n["shortcut.summon"], "⌘ ⇧ S")
                Divider().opacity(0.3).padding(.vertical, 6)
                shortcutItem(i18n["shortcut.hide_all"], "⌘ ⇧ H")
                Divider().opacity(0.3).padding(.vertical, 6)
                shortcutItem(i18n["shortcut.ai_chat"], "⌘ ⇧ L")
                Divider().opacity(0.3).padding(.vertical, 6)
                shortcutItem(i18n["shortcut.switch_char"], "⌘ → / ←")
            }
        }
    }

    // MARK: - Row helpers
    func statusRow(_ l: String, _ v: String, _ c: Color) -> some View {
        HStack {
            Text(l).font(.system(size: 11))
            Circle().fill(c).frame(width: 5, height: 5)
            Spacer()
            Text(v).font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }
    func labelRow(_ l: String, _ v: String) -> some View {
        HStack {
            Text(l).font(.system(size: 11)); Spacer()
            Text(v).font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
        }
    }
    func aboutRow(_ l: String, _ v: String) -> some View {
        HStack {
            Text(l).font(.system(size: 11)).foregroundStyle(.secondary); Spacer()
            Text(v).font(.system(size: 11, design: .monospaced)).foregroundStyle(.tertiary)
        }
    }
    func labeledTF(_ l: String, _ b: Binding<String>) -> some View {
        HStack {
            Text(l).font(.system(size: 11))
            Spacer()
            TextField("", text: b).frame(width: 180).multilineTextAlignment(.trailing).font(.system(size: 11, design: .monospaced))
        }
    }
    func shortcutItem(_ l: String, _ k: String) -> some View {
        HStack {
            Text(l).font(.system(size: 11, design: .rounded))
            Spacer()
            Text(k).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(RoundedRectangle(cr: 5).fill(.ultraThinMaterial))
        }
    }
}


// MARK: - QR Code Sheet
struct QRCodeSheet: View {
    @EnvironmentObject var i18n: I18NManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text(i18n["settings.support"]).font(.system(size: 16, weight: .semibold))
                .padding(.top, 8)

            if let imgURL = Bundle.main.url(forResource: "qrcode_author", withExtension: "png"),
               let data = try? Data(contentsOf: imgURL),
               let nsImg = NSImage(data: data) {
                Image(nsImage: nsImg)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 260, maxHeight: 260)
                    .clipShape(RoundedRectangle(cr: 12))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo").font(.system(size: 48)).foregroundStyle(.secondary)
                    Text(i18n["settings.qrcode_not_found"]).font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .frame(width: 260, height: 260)
            }

            Text(i18n["settings.donate_thanks"]).font(.system(size: 11)).foregroundStyle(.secondary)
            Button(i18n["ui.close"]) { dismiss() }
                .font(.system(size: 12))
                .padding(.horizontal, 20).padding(.vertical, 6)
                .background(RoundedRectangle(cr: 8).fill(.ultraThinMaterial))
                .buttonStyle(.plain)
                .padding(.bottom, 16)
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cr: 16))
        .overlay(RoundedRectangle(cr: 16).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
    }
}
