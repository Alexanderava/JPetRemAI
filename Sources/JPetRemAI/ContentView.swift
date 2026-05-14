// ContentView.swift
// 液态玻璃 · 角色管理 · AI 对话 · 模型管理

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    @EnvironmentObject var vm: PetViewModel
    @Environment(\.colorScheme) var cs
    @State private var sideCollapse = false

    var body: some View {
        ZStack {
            background
            HStack(spacing: 0) {
                if !sideCollapse {
                    sidebar
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                main
            }
            toastOverlay
            if vm.selectedTab != .chat { fab }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: sideCollapse)
        .frame(minWidth: 880, minHeight: 620)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) { sideCollapse.toggle() } }) {
                    Image(systemName: sideCollapse ? "sidebar.right" : "sidebar.left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(sideCollapse ? i18n["ui.show_sidebar"] : i18n["ui.hide_sidebar"])
            }
        }
        .sheet(isPresented: $vm.showSettings) { SettingsView().environmentObject(vm) }
        .sheet(isPresented: $vm.showAbout) { AboutView() }
    }

    // ── Background ──
    private var background: some View {
        ZStack {
            (cs == .dark ? Color(red: 0.04, green: 0.04, blue: 0.06) : Color(red: 0.99, green: 0.985, blue: 0.98))
            Circle().fill(.purple.opacity(cs == .dark ? 0.06 : 0.09)).frame(width: 440).blur(radius: 90).offset(x: -100, y: -50)
            Circle().fill(.blue.opacity(cs == .dark ? 0.04 : 0.06)).frame(width: 340).blur(radius: 70).offset(x: 160, y: 110)
        }.ignoresSafeArea()
    }

    // ── Sidebar ──
    private var sidebar: some View {
        VStack(spacing: 0) {
            avatarSect.padding(.top, 20).padding(.bottom, 6)
            Divider().overlay(.primary.opacity(0.08)).padding(.horizontal, 10)
            navList.padding(.top, 6)
            Spacer()
            bottomSect.padding(.horizontal, 10).padding(.bottom, 12)
        }
        .frame(width: 240)
        // 折射光线
        .background(
            RoundedRectangle(cr: 20)
                .fill(LinearGradient(
                    colors: [
                        .white.opacity(0.06),
                        .clear,
                        .white.opacity(0.04),
                        .purple.opacity(0.04),
                        .blue.opacity(0.03),
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        // 镜面折射条纹
        .background(
            RoundedRectangle(cr: 20)
                .fill(LinearGradient(
                    colors: [.white.opacity(0.1), .clear, .white.opacity(0.04)],
                    startPoint: UnitPoint(x: 0.15, y: 0), endPoint: UnitPoint(x: 0.35, y: 1)))
        )
        // 高贵边缘：外层白金渐变
        .overlay(
            RoundedRectangle(cr: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.08),
                            .white.opacity(0.04),
                            .white.opacity(0.12),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.6)
        )
        // 内层金边
        .overlay(
            RoundedRectangle(cr: 20)
                .inset(by: 0.5)
                .strokeBorder(.white.opacity(0.06), lineWidth: 0.3)
        )
        // 投影保持层次
        .shadow(color: .purple.opacity(0.03), radius: 30, x: 0, y: 8)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 3, y: 1)
        .clipShape(RoundedRectangle(cr: 20))
        .padding(.leading, 10).padding(.vertical, 10)
    }

    private var avatarSect: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(.purple.opacity(0.25)).frame(width: 54, height: 54).blur(radius: 6)
                if let img = avatarImage {
                    Image(nsImage: img)
                        .resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
                } else {
                    Circle().fill(.ultraThinMaterial).frame(width: 48, height: 48)
                        .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
                    Image(systemName: "sparkles").font(.system(size: 20))
                        .foregroundStyle(LinearGradient(colors: [.purple,.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
            VStack(spacing: 1) {
                Text("JPetRemAI").font(.system(size: 13, weight: .bold, design: .rounded))
                Text("\(vm.activeCount)/\(vm.characters.count) \(i18n["status.active"])")
                    .font(.system(size: 9.5, design: .rounded)).foregroundStyle(.secondary)
            }
        }
    }

    private var avatarImage: NSImage? {
        let filePaths = [
            "/Users/chenxing/Downloads/41F1755B-EEBD-4F46-A624-1186CA2389F1_1_201_a.jpeg",
            Bundle.main.bundlePath + "/Contents/Resources/avatar.jpg",
        ]
        for p in filePaths where FileManager.default.fileExists(atPath: p) {
            return NSImage(contentsOfFile: p)
        }
        if let bp = Bundle.main.path(forResource: "avatar", ofType: "jpg") {
            return NSImage(contentsOfFile: bp)
        }
        if let bp = Bundle.main.path(forResource: "avatar", ofType: "jpeg") {
            return NSImage(contentsOfFile: bp)
        }
        return nil
    }

    private var navList: some View {
        VStack(spacing: 2) {
            ForEach(navItems) { item in
                NavRow(item: item, s: vm.selectedTab) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { vm.selectedTab = item.tab }
                }
            }
        }.padding(.horizontal, 6)
    }

    private var bottomSect: some View {
        VStack(spacing: 7) {
            HStack(spacing: 5) {
                Circle().fill(vm.engineStatus == .running ? .green : .orange).frame(width: 5, height: 5)
                Text(vm.engineStatusText).font(.system(size: 9.5, design: .rounded)).foregroundStyle(.tertiary)
                Spacer()
                Button(action: { withAnimation { sideCollapse.toggle() } }) {
                    Image(systemName: "sidebar.left").font(.system(size: 9.5)).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }
            Button(action: { vm.summonAllPets() }) {
                HStack(spacing: 4) { Image(systemName: "sparkles"); Text(i18n["pets.summon_all"]) }
                    .font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                    .padding(.vertical, 7).frame(maxWidth: .infinity)
                    .background(LinearGradient(colors: [.purple, .pink.opacity(0.85)], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cr: 8))
            }.buttonStyle(.plain)
        }
    }

    // ── Main Content ──
    private var main: some View {
        ZStack {
            RoundedRectangle(cr: 16).fill(.ultraThinMaterial.opacity(0.4)).padding(5)
            Group {
                switch vm.selectedTab {
                case .characters: CharsView()
                case .chat: ChatView()
                case .models: ModelManagerView()
                case .history: HistoryView()
                case .settings: SettingsView()
                }
            }.padding(12)
        }
    }

    private var fab: some View {
        VStack { Spacer(); HStack { Spacer()
            Button(action: { vm.summonRandomPet() }) {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 48, height: 48)
                        .overlay(Circle().strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
                        .shadow(color: .black.opacity(0.12), radius: 12, y: 2)
                    Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(LinearGradient(colors: [.purple,.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }.buttonStyle(.plain).help(i18n["pets.random_summon"])
            .padding(.trailing, 18).padding(.bottom, 18)
        }}
    }

    private var toastOverlay: some View {
        Group {
            if vm.showSummonToast, let msg = vm.summonToast {
                VStack { Spacer()
                    Text(msg).font(.system(size: 12.5, weight: .medium, design: .rounded)).foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(RoundedRectangle(cr: 12).fill(.black.opacity(0.5)).background(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cr: 12).strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
                        .padding(.bottom, 50)
                }.transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// ── Glass Panel Modifier ──
extension View {
    func glassPanel(radius: CGFloat) -> some View {
        self
            .background(GlassBackground(radius: radius))
            // 液态颜色注入：紫色/粉色环境光渗透
            .background(
                RoundedRectangle(cr: radius)
                    .fill(LinearGradient(
                        colors: [.purple.opacity(0.03), .pink.opacity(0.02)],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            // 顶部镜面高光
            .background(
                RoundedRectangle(cr: radius)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.18), .white.opacity(0.03), .clear],
                        startPoint: .top, endPoint: .center))
            )
            // 液态边缘：外高光 + 内阴影
            .overlay(
                RoundedRectangle(cr: radius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.22),   // 左上角镜面反射
                                .white.opacity(0.12),
                                .white.opacity(0.06),   // 右下角淡出
                                .black.opacity(0.03),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.7)
            )
            // 内边框第二层：反向渐变增加深度
            .overlay(
                RoundedRectangle(cr: radius)
                    .inset(by: 0.5)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.08), .white.opacity(0.18)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.4)
            )
            .clipShape(RoundedRectangle(cr: radius))
            .shadow(color: .purple.opacity(0.04), radius: 28, x: 0, y: 10)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 4, y: 2)
        .clipShape(RoundedRectangle(cr: radius))
        .shadow(color: .black.opacity(0.05), radius: 16, x: 3, y: 0)
    }
}

// ── macOS 26 Liquid Glass Effect ──
struct GlassBackground: NSViewRepresentable {
    let radius: CGFloat
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        // macOS 26 最强液态：菜单级毛玻璃 + 颜色注入
        v.material = .sidebar
        v.blendingMode = .behindWindow
        v.state = .active
        v.isEmphasized = true
        v.appearance = NSAppearance(named: .aqua)
        v.wantsLayer = true
        v.layer?.cornerRadius = radius
        v.layer?.masksToBounds = true
        v.alphaValue = 0.7
        return v
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.layer?.cornerRadius = radius
    }
}

// ── Nav ──
struct NavItem: Identifiable {
    let id = UUID(); let icon: String; let title: String; let tab: PetViewModel.Tab
}

struct NavRow: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let item: NavItem; let s: PetViewModel.Tab; let action: () -> Void
    var sel: Bool { s == item.tab }
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: sel ? "\(item.icon.replacingOccurrences(of: ".fill", with: ""))" : item.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(sel ? .white : .primary.opacity(0.6)).frame(width: 20)
                Text(item.title)
                    .font(.system(size: 12, weight: sel ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(sel ? .white : .primary.opacity(0.8))
                Spacer()
                if sel { Circle().fill(.white.opacity(0.8)).frame(width: 4, height: 4) }
            }
            .padding(.horizontal, 9).padding(.vertical, 7)
            .background(sel ? AnyShapeStyle(LinearGradient(colors: [.purple.opacity(0.82),.pink.opacity(0.65)], startPoint: .leading, endPoint: .trailing)) : AnyShapeStyle(.clear))
            .clipShape(RoundedRectangle(cr: 8))
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: sel)
        }.buttonStyle(.plain)
    }
}

// MARK: - ═══════════════════════════════════════════════════════
// MARK:  角色管理
// MARK: ═══════════════════════════════════════════════════════

struct CharsView: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    @EnvironmentObject var vm: PetViewModel
    let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(vm.characters.count) \(i18n["pets.role_count"])")
                    .font(.system(size: 10, design: .rounded)).foregroundStyle(.tertiary)
                Text("·").foregroundStyle(.tertiary.opacity(0.4))
                Text("\(vm.activeCount) \(i18n["status.active"])")
                    .font(.system(size: 10, design: .rounded)).foregroundStyle(.green.opacity(0.8))
                Spacer()
                Button { vm.refreshCharacters() } label: {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: 9)).foregroundStyle(.secondary)
                }.buttonStyle(.plain).help(i18n["pets.refresh"])
            }
            .padding(.horizontal, 12).padding(.vertical, 6)

            ScrollView {
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(vm.characters) { c in
                        CharCard(c: c)
                    }
                }.padding(10)
            }
        }
        .onAppear { vm.refreshCharacters() }
    }
}

struct CharCard: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let c: PetViewModel.Character
    @EnvironmentObject var vm: PetViewModel
    @State private var iconImg: NSImage? = nil

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let img = iconImg {
                    Image(nsImage: img)
                        .resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cr: 14))
                } else {
                    RoundedRectangle(cr: 14).fill(.ultraThinMaterial).frame(width: 56, height: 56)
                    Image(systemName: "person.crop.square.fill").font(.system(size: 22))
                        .foregroundStyle(LinearGradient(colors: [.purple,.pink],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                if c.isActive {
                    RoundedRectangle(cr: 14).strokeBorder(
                        LinearGradient(colors: [.purple.opacity(0.6), .pink.opacity(0.4), .clear],
                            startPoint: .top, endPoint: .bottom), lineWidth: 2)
                }
            }
            .shadow(color: .purple.opacity(c.isActive ? 0.25 : 0), radius: 8)

            Text(i18n["char." + c.name] ?? c.name).font(.system(size: 11, weight: .semibold, design: .rounded)).lineLimit(1)

            HStack(spacing: 4) {
                Button { vm.summonPet(c.name) } label: {
                    HStack(spacing: 3) {
                        Image(systemName: c.isActive ? "repeat" : "plus").font(.system(size: 7, weight: .bold))
                        Text(c.isActive ? "\(c.summonedCount)" : i18n["pets.summon"]).font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(
                        LinearGradient(colors: [.purple, .pink.opacity(0.85)],
                            startPoint: .leading, endPoint: .trailing)))
                }.buttonStyle(.plain)

                if c.isActive {
                    Button { vm.dismissPet(c.name) } label: {
                        Image(systemName: "xmark").font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(.ultraThinMaterial))
                    }.buttonStyle(.plain).help(i18n["ui.hide"])
                }
            }
        }
        .padding(8)
        .background(RoundedRectangle(cr: 14).fill(.ultraThinMaterial.opacity(0.4))
            .overlay(RoundedRectangle(cr: 14).strokeBorder(.white.opacity(0.06), lineWidth: 0.5)))
        .onAppear { loadIcon() }
        .onChange(of: c.iconPath) { _ in loadIcon() }
    }

    func loadIcon() {
        if let path = c.iconPath, let img = NSImage(contentsOfFile: path) { iconImg = img }
        else { iconImg = nil }
    }
}

// MARK: - Character Detail Sheet
// MARK:  AI 对话
// MARK: ═══════════════════════════════════════════════════════

struct ChatView: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    @EnvironmentObject var vm: PetViewModel
    @EnvironmentObject var llama: LlamaBridge
    @EnvironmentObject var mlx: MLXBridge
    @State private var t = ""
    @State private var showPromptEditor = false
    @State private var engineTab = 0  // 0=GGUF/llama, 1=MLX (synced to vm.chatEngine)
    @State private var tempDrag = false

    var body: some View {
        VStack(spacing: 0) {
            // Header: engine selector + model picker + system prompt
            VStack(spacing: 6) {
                // Engine toggle
                HStack(spacing: 1) {
                    ForEach(0..<2) { i in
                        Button {
                            withAnimation { 
                                engineTab = i
                                vm.chatEngine = i == 0 ? "llama" : "mlx"
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: i == 0 ? "shippingbox.fill" : "applelogo")
                                    .font(.system(size: 8, weight: .medium))
                                Text(i == 0 ? "GGUF" : "MLX")
                                    .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(engineTab == i ? .white : .secondary)
                            .padding(.horizontal, 12).padding(.vertical, 2)
                            .background(Capsule().fill(engineTab == i ? (i == 0 ? .blue : .orange) : .primary.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    // Engine status
                    Circle()
                        .fill(
                            engineTab == 0
                                ? (llama.isRunning ? Color.green : Color.orange)
                                : (mlx.isRunning ? Color.green : Color.orange)
                        )
                        .frame(width: 6, height: 6)
                    Text(engineTab == 0
                         ? (llama.currentModel?.replacingOccurrences(of: ".gguf", with: "") ?? i18n["chat.waiting_load"])
                         : (mlx.currentModel?.components(separatedBy: "/").last ?? i18n["chat.needs_python3"]))
                        .font(.system(size: 9, design: .rounded)).foregroundStyle(.secondary).lineLimit(1)
                }
                .padding(.horizontal, 12)

                // Model / MLX picker
                HStack(spacing: 6) {
                    if engineTab == 0 {
                        Menu {
                            if llama.availableModels.isEmpty {
                                Text(i18n["chat.no_model"]).foregroundStyle(.secondary)
                            } else {
                                ForEach(llama.availableModels, id: \.self) { m in
                                    Button {
                                        vm.chatModel = m
                                        llama.switchModel(m)
                                    } label: {
                                        HStack {
                                            Text(m.replacingOccurrences(of: ".gguf", with: ""))
                                            if vm.chatModel == m { Image(systemName: "checkmark") }
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "cpu").font(.system(size: 9))
                                Text(vm.chatModel.replacingOccurrences(of: ".gguf", with: "").isEmpty ? i18n["chat.select_model"] : vm.chatModel.replacingOccurrences(of: ".gguf", with: ""))
                                    .font(.system(size: 10.5, design: .rounded)).lineLimit(1)
                                Image(systemName: "chevron.down").font(.system(size: 7))
                            }
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(RoundedRectangle(cr: 6).fill(.ultraThinMaterial))
                        }
                        .buttonStyle(.plain)
                    } else {
                        // MLX: show repo path + install button
                        HStack(spacing: 4) {
                            Image(systemName: mlx.mlxAvailable ? "applelogo" : "exclamationmark.triangle")
                                .font(.system(size: 9)).foregroundStyle(mlx.mlxAvailable ? .orange : .yellow)
                            Text(mlx.statusText).font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(RoundedRectangle(cr: 6).fill(.ultraThinMaterial))
                    }

                    Spacer()

                    Text(i18n["char.蕾姆"] ?? "蕾姆")
                        .font(.system(size: 10, design: .rounded)).foregroundStyle(.purple)
                        .padding(.horizontal, 12).padding(.vertical, 2)
                        .background(Capsule().fill(.purple.opacity(0.1)))

                    Button { vm.showHistory.toggle() } label: {
                        Image(systemName: "clock.arrow.circlepath").font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain).help(i18n["chat.history"])
                }
                .padding(.horizontal, 12)
            }
            .padding(.top, 8).padding(.bottom, 6)

            if showPromptEditor {
                promptEditor.padding(.horizontal, 12).padding(.bottom, 6)
            }

            Divider().overlay(.primary.opacity(0.04))

            // Messages
            if vm.messages.isEmpty {
                emptyChat
            } else {
                ScrollViewReader { p in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.messages) { m in
                                ChatBubble(m: m)
                            }
                            if vm.isAIThinking {
                                if !vm.streamingToken.isEmpty {
                                    // Show streaming partial output
                                    HStack { Spacer(minLength: 40)
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(vm.streamingToken)
                                                .font(.system(size: 12.5, design: .rounded))
                                                .foregroundStyle(.primary)
                                                .padding(.horizontal, 12).padding(.vertical, 8)
                                                .background(RoundedRectangle(cr: 14).fill(.ultraThinMaterial))
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: 340, alignment: .leading)
                                            HStack(spacing: 4) {
                                                ProgressView().scaleEffect(0.35)
                                                Text(i18n["status.typing"]).font(.system(size: 8.5)).foregroundStyle(.tertiary)
                                            }
                                        }
                                    }
                                } else {
                                    HStack { Spacer()
                                        HStack(spacing: 4) {
                                            ProgressView().scaleEffect(0.4)
                                            Text(i18n["status.thinking"]).font(.system(size: 10)).foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(RoundedRectangle(cr: 10).fill(.ultraThinMaterial))
                                    }
                                }
                            }
                        }.padding(12)
                        .id("bottom")
                    }
                    .onChange(of: vm.messages.count) {
                        withAnimation { p.scrollTo("bottom", anchor: .bottom) }
                    }
                }
            }

            // Input
            HStack(spacing: 6) {
                // Temperature mini
                HStack(spacing: 0) {
                    Image(systemName: "thermometer.medium").font(.system(size: 7)).foregroundStyle(.tertiary)
                    Slider(value: $vm.temperature, in: 0.1...2.0, step: 0.1,
                           onEditingChanged: { editing in tempDrag = editing })
                        .frame(width: 32)
                    if tempDrag {
                        Text(String(format: "%.1f", vm.temperature))
                            .font(.system(size: 8, design: .monospaced)).foregroundStyle(.secondary)
                            .frame(width: 20)
                            .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.15), value: tempDrag)
                
                TextEditor(text: $t)
                    .font(.system(size: 12.5, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .frame(height: 36)
                    .padding(.horizontal, 10).padding(.vertical, 2)
                    .background(RoundedRectangle(cr: 10).fill(.ultraThinMaterial))
                    .overlay(RoundedRectangle(cr: 10).strokeBorder(.white.opacity(0.1), lineWidth: 0.5))
                
                Button(action: send) {
                    Circle()
                        .fill(t.isEmpty ? AnyShapeStyle(.clear) : AnyShapeStyle(LinearGradient(
                            colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)))
                        .frame(width: 30, height: 30)
                        .overlay(Image(systemName: "arrow.up")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(t.isEmpty ? Color.secondary : Color.white))
                }
                .buttonStyle(.plain).disabled(t.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
                
                Button { vm.clearChat() } label: {
                    Image(systemName: "trash").font(.system(size: 10)).foregroundStyle(.tertiary)
                }.buttonStyle(.plain).help(i18n["ui.clear"])
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
        }
        .sheet(isPresented: $vm.showHistory) { historySheet }
    }

    private var historySheet: some View {
        VStack(spacing: 0) {
            HStack {
                Text("对话历史").font(.system(size: 14, weight: .semibold))
                Spacer()
                Button { vm.showHistory = false } label: {
                    Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }.padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 12)

            Divider().padding(.horizontal, 20)

            if vm.conversations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 30)).foregroundStyle(.tertiary)
                    Text(i18n["chat.no_history"]).font(.system(size: 12)).foregroundStyle(.secondary)
                }.frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(vm.conversations) { conv in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(conv.title).font(.system(size: 12, design: .rounded)).lineLimit(1)
                                    Text(conv.date, style: .date).font(.system(size: 9)).foregroundStyle(.tertiary)
                                }
                                Spacer()
                                Text("\(conv.messages.count)").font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(RoundedRectangle(cr: 8).fill(.ultraThinMaterial.opacity(0.5)))
                            .onTapGesture { vm.loadConversation(conv) }
                            .contextMenu {
                                Button(role: .destructive) {
                                    vm.deleteConversation(conv)
                                } label: { Label(i18n["ui.delete"], systemImage: "trash") }
                            }
                        }
                        .padding(.horizontal, 16)
                    }.padding(.vertical, 8)
                }
            }

            Divider().padding(.horizontal, 20)
            HStack {
                Button { vm.newConversation() } label: {
                    Label(i18n["chat.new_chat"], systemImage: "square.and.pencil").font(.system(size: 11))
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 10)
        }
        .frame(width: 360, height: 480)
    }

    private var promptEditor: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(i18n["chat.system_prompt"]).font(.system(size: 10, weight: .semibold)).foregroundStyle(.secondary)
            TextEditor(text: $vm.systemPrompt)
                .font(.system(size: 10.5, design: .rounded))
                .frame(height: 50)
                .padding(6)
                .background(RoundedRectangle(cr: 8).fill(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cr: 8))
        }
    }

    private var emptyChat: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 38))
                .foregroundStyle(.secondary.opacity(0.25))
            VStack(spacing: 4) {
                Text(i18n["chat.subtitle"])
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(i18n["chat.system_prompt_hint"])
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func send() {
        guard !t.isEmpty else { return }
        let text = t; t = ""
        vm.sendMessage(text)
    }
}

struct ChatBubble: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let m: PetViewModel.ChatMessage
    @State private var showCopy = false
    @State private var codeBlocks: [CodeBlock] = []
    
    struct CodeBlock: Identifiable {
        let id = UUID()
        let language: String
        let code: String
        let range: Range<String.Index>
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            if m.isUser { Spacer(minLength: 40) }
            if !m.isUser {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 24, height: 24)
                    Image(systemName: "sparkles").font(.system(size: 9)).foregroundStyle(.purple)
                }
            }

            VStack(alignment: m.isUser ? .trailing : .leading, spacing: 4) {
                // 解析消息：拆分为文本段 + 代码块
                ForEach(parseBlocks(), id: \.id) { block in
                    switch block.kind {
                    case .text(let text):
                        Text(text)
                            .font(.system(size: 12.5, design: .rounded))
                            .foregroundStyle(m.isUser ? .white : .primary)
                    case .code(let info):
                        CodeSegment(language: info.lang, code: info.code)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(
                    m.isUser
                        ? AnyShapeStyle(LinearGradient(colors: [.purple.opacity(0.82), .pink.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cr: 14))

                // Metadata row
                HStack(spacing: 6) {
                    Text(m.timestamp, style: .time)
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(.tertiary)
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(m.text, forType: .string)
                        showCopy = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showCopy = false }
                    } label: {
                        Image(systemName: showCopy ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 8))
                            .foregroundStyle(showCopy ? Color.green : Color.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("复制")
                }
            }

            if !m.isUser { Spacer(minLength: 40) }

            if m.isUser {
                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 24, height: 24)
                    Image(systemName: "person.fill").font(.system(size: 9)).foregroundStyle(.secondary)
                }
            }
        }
    }
}
// ── Code Block Parser (adds to ChatBubble) ──
extension ChatBubble {
    enum BlockKind {
        case text(String)
        case code(CodeInfo)
    }
    struct BlockItem: Identifiable { let id = UUID(); let kind: BlockKind }
    struct CodeInfo { let lang: String; let code: String }
    
    func parseBlocks() -> [BlockItem] {
        let chars = Array(m.text)
        let n = chars.count
        var items: [BlockItem] = []
        var pos = 0
        var buf = ""
        
        while pos < n {
            // Check for ``` code fence
            if pos + 2 < n, chars[pos] == "`", chars[pos+1] == "`", chars[pos+2] == "`" {
                if !buf.isEmpty { items.append(BlockItem(kind: .text(buf))); buf = "" }
                let startPos = pos
                pos += 3
                // Read language hint
                var lang = ""
                while pos < n, chars[pos] != "\n" { lang.append(chars[pos]); pos += 1 }
                if pos < n { pos += 1 }
                // Read code until closing ```
                var code = ""
                var foundClose = false
                while pos < n {
                    if pos + 2 < n, chars[pos] == "`", chars[pos+1] == "`", chars[pos+2] == "`" {
                        pos += 3
                        if pos < n, chars[pos] == "\n" { pos += 1 }
                        foundClose = true; break
                    }
                    code.append(chars[pos]); pos += 1
                }
                if foundClose {
                    items.append(BlockItem(kind: .code(CodeInfo(lang: lang.trimmingCharacters(in: .whitespaces), code: code.trimmingCharacters(in: .newlines)))))
                } else {
                    // Unclosed fence: treat as text
                    buf += String(chars[startPos..<pos])
                }
            } else {
                buf.append(chars[pos]); pos += 1
            }
        }
        if !buf.isEmpty { items.append(BlockItem(kind: .text(buf))) }
        return items
    }
}

// ── Code Block Segment (simplified) ──
struct CodeSegment: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let language: String
    let code: String
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left.forwardslash.chevron.right").font(.system(size: 9))
                Text(language.isEmpty ? "code" : language).font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    HStack(spacing: 3) { Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.system(size: 9)); Text(copied ? i18n["chat.copied"] : "复制").font(.system(size: 9)) }
                        .padding(.horizontal, 12).padding(.vertical, 2).background(Capsule().fill(.primary.opacity(0.08))).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
                Button {
                    let ext = langToExt(language)
                    let panel = NSSavePanel(); panel.nameFieldStringValue = "code.\(ext)"
                    panel.begin { resp in if resp == .OK, let url = panel.url { try? code.write(to: url, atomically: true, encoding: .utf8) } }
                } label: {
                    HStack(spacing: 3) { Image(systemName: "arrow.down.circle").font(.system(size: 9)); Text("下载").font(.system(size: 9)) }
                        .padding(.horizontal, 12).padding(.vertical, 2).background(Capsule().fill(.primary.opacity(0.08))).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }.padding(.horizontal, 10).padding(.vertical, 5).background(.primary.opacity(0.04))
            Divider().overlay(.primary.opacity(0.06))
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code).font(.system(size: 11, design: .monospaced)).padding(10)
            }
        }
        .background(RoundedRectangle(cr: 10).fill(.black.opacity(0.04)))
        .overlay(RoundedRectangle(cr: 10).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cr: 10)).padding(.vertical, 6)
    }
    
    func langToExt(_ lang: String) -> String {
        switch lang.lowercased() {
        case "swift": return "swift"
        case "python", "py": return "py"
        case "javascript", "js": return "js"
        case "typescript", "ts": return "ts"
        case "go", "golang": return "go"
        case "rust", "rs": return "rs"
        case "java": return "java"
        case "bash", "sh", "shell": return "sh"
        case "json": return "json"
        case "html": return "html"
        case "css": return "css"
        case "sql": return "sql"
        case "cpp", "c++": return "cpp"
        default: return "txt"
        }
    }
}

// MARK: - ═══════════════════════════════════════════════════════
// MARK: - ═══════════════════════════════════════════════════════
// MARK:  模型管理
// MARK: ═══════════════════════════════════════════════════════

struct ModelManagerView: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    @EnvironmentObject var vm: PetViewModel
    @State private var s = ""
    @State private var tab: MTab = .community
    @State private var communityTab = 0  // 0=GGUF, 1=MLX
    enum MTab: String, CaseIterable, Identifiable {
        case community, local, downloads, lmStudio
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Picker("", selection: $tab) {
                    ForEach(MTab.allCases) { tab in
                        let label: String = {
                            switch tab {
                            case .community: return i18n["models.community"]
                            case .local: return i18n["models.local"]
                            case .downloads: return "队列"
                            case .lmStudio: return "LM Studio"
                            }
                        }()
                        Text(label).tag(tab)
                    }
                }
                .pickerStyle(.segmented).frame(width: 280)
                Spacer()
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass").font(.system(size: 9.5)).foregroundStyle(.tertiary)
                    TextField(i18n["models.search"], text: $s).textFieldStyle(.plain).font(.system(size: 10.5, design: .rounded))
                }
                .padding(.horizontal, 9).padding(.vertical, 5)
                .background(RoundedRectangle(cr: 7).fill(.ultraThinMaterial)).frame(width: 150)
            }
            .padding(.horizontal, 10).padding(.top, 10).padding(.bottom, 6)

            // GGUF / MLX 子标签
            if tab == .community {
                HStack(spacing: 1) {
                    ForEach(0..<2) { i in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { communityTab = i }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: i == 0 ? "shippingbox.fill" : "applelogo")
                                    .font(.system(size: 10, weight: .medium))
                                Text(i == 0 ? "GGUF" : "MLX")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(communityTab == i ? .white : .secondary)
                            .padding(.horizontal, 20).padding(.vertical, 5)
                            .background(
                                Capsule().fill(
                                    communityTab == i
                                    ? (i == 0 ? Color.blue : Color.orange)
                                    : Color.primary.opacity(0.05))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 6)
            }

            Divider().overlay(.primary.opacity(0.04))

            switch tab {
            case .local: LocalModelsView()
            case .community:
                if communityTab == 0 {
                    HFList(s: s)
                } else {
                    MLXList(s: s)
                }
            case .downloads: DownloadQueueView()
            case .lmStudio: LMStudioModelsView()
            }
        }
    }
}

// ── Download Queue ──
struct DownloadQueueView: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    @EnvironmentObject var vm: PetViewModel

    var body: some View {
        let tasks = Array(vm.downloadManager.downloads.values)
        if tasks.isEmpty {
            est("arrow.down.circle", i18n["models.no_downloads"], i18n["models.start_download"])
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Label("\(vm.downloadManager.activeCount) 个进行中", systemImage: "arrow.down.circle")
                        .font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    Spacer()
                    Text("\(vm.downloadManager.completedModels.count) 已完成").font(.system(size: 10)).foregroundStyle(.green)
                    if vm.downloadManager.activeCount > 0 {
                        Button(i18n["models.cancel_all"]) {
                            for t in vm.downloadManager.downloads.values {
                                if case .downloading = t.status { vm.downloadManager.cancelDownload(id: t.id) }
                            }
                        }.font(.system(size: 10)).foregroundStyle(.red)
                    }
                    Button {
                        NSWorkspace.shared.open(URL(fileURLWithPath: ModelDownloadManager.modelsDir))
                    } label: {
                        Image(systemName: "folder").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("打开 Models 文件夹")
                }.padding(.horizontal, 10).padding(.top, 10).padding(.bottom, 6)

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(tasks.sorted(by: { a, b in
                            let aActive = a.status == .downloading ? 0 : 1
                            let bActive = b.status == .downloading ? 0 : 1
                            return aActive < bActive
                        }))) { task in
                            DownloadTaskRow(task: task)
                        }
                    }.padding(.horizontal, 12).padding(.vertical, 8)
                }
            }
        }
    }
}

struct DownloadTaskRow: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let task: ModelDownloadManager.DownloadTask
    @EnvironmentObject var vm: PetViewModel

    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            statusIcon
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cr: 7).fill(statusColor.opacity(0.12)))

            VStack(alignment: .leading, spacing: 3) {
                Text(task.modelName).font(.system(size: 12, weight: .semibold, design: .rounded))
                HStack(spacing: 4) {
                    Text(task.quantLabel).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.tertiary)
                    Text(task.status.label).font(.system(size: 9.5)).foregroundStyle(statusColor)
                    if case .downloading = task.status, task.totalBytes > 0 {
                        Text("·").foregroundStyle(.tertiary)
                        Text(formatBytes(task.downloadedBytes) + " / " + formatBytes(task.totalBytes))
                            .font(.system(size: 9, design: .monospaced)).foregroundStyle(.tertiary)
                        if task.speedBytesPerSec > 0 {
                            Text("·").foregroundStyle(.tertiary)
                            Text(formatSpeed(task.speedBytesPerSec))
                                .font(.system(size: 9, design: .monospaced)).foregroundStyle(.blue.opacity(0.8))
                        }
                    }
                }
                if case .downloading = task.status, task.totalBytes > 0 {
                    progressBar
                }
                if case .completed(let path) = task.status {
                    HStack(spacing: 4) {
                        Image(systemName: "folder").font(.system(size: 7)).foregroundStyle(.tertiary)
                        Text(URL(fileURLWithPath: path).lastPathComponent)
                            .font(.system(size: 8.5, design: .monospaced)).foregroundStyle(.tertiary).lineLimit(1)
                    }
                }
                if case .failed(let msg) = task.status {
                    Text(msg).font(.system(size: 9)).foregroundStyle(.red).lineLimit(2)
                }
            }

            Spacer()

            // Actions
            actionButton
        }
        .padding(9)
        .background(RoundedRectangle(cr: 10).fill(.ultraThinMaterial.opacity(0.4)))
        .overlay(RoundedRectangle(cr: 10).strokeBorder(.white.opacity(0.05), lineWidth: 0.5))
        .contextMenu {
            if case .downloading = task.status {
                Button { vm.cancelDownload(id: task.id) } label: {
                    Label("取消下载", systemImage: "xmark.circle")
                }
            }
            if case .completed(let path) = task.status {
                Button {
                    NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                } label: {
                    Label("在 Finder 中显示", systemImage: "folder")
                }
                Divider()
                Button(role: .destructive) { vm.deleteModelFile(id: task.id) } label: {
                    Label("删除文件", systemImage: "trash")
                }
            }
            if case .failed = task.status {
                Button { vm.retryDownload(id: task.id) } label: {
                    Label(i18n["models.retry_download"], systemImage: "arrow.clockwise")
                }
            }
            Divider()
            Button {
                NSWorkspace.shared.open(URL(fileURLWithPath: ModelDownloadManager.modelsDir))
            } label: {
                Label("打开 Models 文件夹", systemImage: "folder.badge.gearshape")
            }
        }
    }

    private var statusIcon: some View {
        Group {
            switch task.status {
            case .pending: Image(systemName: "clock").font(.system(size: 12)).foregroundStyle(.orange)
            case .downloading: ProgressView().scaleEffect(0.55)
            case .completed: Image(systemName: "checkmark.circle.fill").font(.system(size: 13)).foregroundStyle(.green)
            case .failed: Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 12)).foregroundStyle(.red)
            case .cancelled: Image(systemName: "xmark.circle.fill").font(.system(size: 12)).foregroundStyle(.secondary)
            }
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .pending: return .orange
        case .downloading: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .secondary
        }
    }

    private var progressBar: some View {
        let p = task.totalBytes > 0 ? Double(task.downloadedBytes) / Double(task.totalBytes) : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cr: 3).fill(.primary.opacity(0.08)).frame(height: 4)
                RoundedRectangle(cr: 3)
                    .fill(LinearGradient(colors: [.blue, .purple.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(CGFloat(p) * geo.size.width, 4), height: 4)
                    .animation(.easeInOut(duration: 0.3), value: p)
            }
        }.frame(height: 4)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch task.status {
        case .pending, .downloading:
            Button { vm.cancelDownload(id: task.id) } label: {
                Image(systemName: "xmark.circle.fill").font(.system(size: 16)).foregroundStyle(.secondary)
            }.buttonStyle(.plain).help("取消下载")
        case .completed:
            Menu {
                Button { vm.deleteModelFile(id: task.id) } label: {
                    Label("删除文件", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill").font(.system(size: 16)).foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        case .failed:
            Button { vm.retryDownload(id: task.id) } label: {
                Image(systemName: "arrow.clockwise.circle.fill").font(.system(size: 16)).foregroundStyle(.blue)
            }.buttonStyle(.plain).help("重试")
        case .cancelled:
            Button { vm.retryDownload(id: task.id) } label: {
                Image(systemName: "arrow.clockwise.circle.fill").font(.system(size: 16)).foregroundStyle(.blue)
            }.buttonStyle(.plain).help("重试")
        }
    }

    func formatBytes(_ b: Int64) -> String {
        if b < 1024 { return "\(b) B" }
        if b < 1048576 { return String(format: "%.1f KB", Double(b)/1024) }
        if b < 1073741824 { return String(format: "%.1f MB", Double(b)/1048576) }
        return String(format: "%.2f GB", Double(b)/1073741824)
    }

    func formatSpeed(_ bps: Double) -> String {
        if bps < 1024 { return String(format: "%.0f B/s", bps) }
        if bps < 1048576 { return String(format: "%.1f KB/s", bps/1024) }
        return String(format: "%.1f MB/s", bps/1048576)
    }
}



// ── MLX Model List ──
struct MLXList: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let s: String
    @EnvironmentObject var vm: PetViewModel

    struct MLXModel: Identifiable {
        let id = UUID(); let name, author, size, downloads: String
        let tags: [String]; let gradient: [Color]; let desc: String; let params: String
        let hfRepo: String
    }

    let models: [MLXModel] = [
        // ━━━ Gemma 4 MLX (靠前) ━━━
        MLXModel(name: "MLX Gemma 4 E2B", author: "Google", size: "~1.3 GB", downloads: "2.8M",
            tags: ["轻量", "开放"], gradient: [c("#4285F4"), c("#669df6")],
            desc: "Google Gemma 4 2B MLX 版，Apple Silicon 原生。", params: "2B",
            hfRepo: "mlx-community/gemma-4-2b-it-4bit"),
        MLXModel(name: "MLX Gemma 4 E4B", author: "Google", size: "~2.5 GB", downloads: "3.5M",
            tags: ["均衡", "开放"], gradient: [c("#4285F4"), c("#8ab4f8")],
            desc: "Google Gemma 4 4B MLX 版，轻量高性能。", params: "4B",
            hfRepo: "mlx-community/gemma-4-4b-it-4bit"),
        MLXModel(name: "MLX Gemma 4 26B MoE", author: "Google", size: "~15 GB", downloads: "4.1M",
            tags: ["MoE", "旗舰"], gradient: [c("#4285F4"), c("#1a73e8")],
            desc: "Google Gemma 4 MoE MLX 版，26B/6B 高效旗舰。", params: "26B/6B",
            hfRepo: "mlx-community/gemma-4-26b-it-4bit"),
        MLXModel(name: "MLX Gemma 4 31B", author: "Google", size: "~18 GB", downloads: "3.9M",
            tags: ["旗舰", "开放"], gradient: [c("#1a73e8"), c("#174ea6")],
            desc: "Google Gemma 4 31B MLX 版，最强开放模型之一。", params: "31B",
            hfRepo: "mlx-community/gemma-4-31b-it-4bit"),
        // ━━━ Qwen ━━━
        MLXModel(name: "MLX Qwen 3.5 4B", author: "Qwen", size: "~2.5 GB", downloads: "3.1M",
            tags: ["中文", "轻量"], gradient: [c("#6366f1"), c("#818cf8")],
            desc: "通义千问 3.5 4B MLX 版，Apple Silicon 原生加速。", params: "4B",
            hfRepo: "mlx-community/Qwen3.5-4B-4bit"),
        MLXModel(name: "MLX Qwen 3.5 9B", author: "Qwen", size: "~5.5 GB", downloads: "5.2M",
            tags: ["中文", "通用"], gradient: [c("#6366f1"), c("#a78bfa")],
            desc: "通义千问 3.5 9B MLX 版，统一内存零拷贝推理。", params: "9B",
            hfRepo: "mlx-community/Qwen3.5-9B-4bit"),
        MLXModel(name: "MLX Llama 3.1 8B", author: "Meta", size: "~4.7 GB", downloads: "8.5M",
            tags: ["通用", "经典"], gradient: [c("#f59e0b"), c("#f97316")],
            desc: "Meta Llama 3.1 8B MLX 版，生态最完善。", params: "8B",
            hfRepo: "mlx-community/Meta-Llama-3.1-8B-Instruct-4bit"),
        MLXModel(name: "MLX Mixtral 8x7B", author: "Mistral", size: "~25 GB", downloads: "4.8M",
            tags: ["MoE", "旗舰"], gradient: [c("#ec4899"), c("#f472b6")],
            desc: "Mistral Mixtral 8x7B MoE MLX 版，12.9B 激活。", params: "46.7B/12.9B",
            hfRepo: "mlx-community/Mixtral-8x7B-Instruct-v0.1-4bit"),
        MLXModel(name: "MLX Qwen 3.6 27B", author: "Qwen", size: "~15 GB", downloads: "4.1M",
            tags: ["中文", "最新"], gradient: [c("#7c3aed"), c("#a78bfa")],
            desc: "通义千问 3.6 27B MLX 版，推理数学大幅增强。", params: "27B",
            hfRepo: "mlx-community/Qwen3.6-27B-4bit"),
        MLXModel(name: "MLX DeepSeek V4 Flash", author: "DeepSeek", size: "~20 GB", downloads: "6.3M",
            tags: ["MoE", "高速"], gradient: [c("#0ea5e9"), c("#38bdf8")],
            desc: "DeepSeek V4 Flash MLX 版，MoE 高效推理。", params: "37B/4B",
            hfRepo: "mlx-community/DeepSeek-V4-Flash-4bit"),
        MLXModel(name: "MLX Kimi K2.6", author: "Moonshot", size: "~18 GB", downloads: "4.7M",
            tags: ["国产", "128K"], gradient: [c("#10b981"), c("#34d399")],
            desc: "月之暗面 Kimi K2.6 MLX 版，超长上下文。", params: "32B",
            hfRepo: "mlx-community/Kimi-K2.6-4bit"),
    ]

    var filtered: [MLXModel] {
        s.isEmpty ? models : models.filter { $0.name.localizedCaseInsensitiveContains(s) || $0.author.localizedCaseInsensitiveContains(s) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filtered) { m in
                    MLXCard(m: m)
                }
            }.padding(10)
        }
    }
}

struct MLXCard: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let m: MLXList.MLXModel
    @EnvironmentObject var vm: PetViewModel

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cr: 10)
                .fill(LinearGradient(colors: m.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "applelogo").font(.system(size: 14)).foregroundStyle(.white.opacity(0.85)))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(m.name).font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text(m.params).font(.system(size: 8.5, design: .monospaced))
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(.ultraThinMaterial).clipShape(Capsule())
                }
                HStack(spacing: 4) {
                    Text(m.author).font(.system(size: 9.5)).foregroundStyle(.orange.opacity(0.8))
                    Text("·").foregroundStyle(.tertiary)
                    Text(m.size).font(.system(size: 9.5, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                // MLX 模型通过 mlx_lm.server 加载
                vm.showToast("🚀 MLX 引擎加载中…")
                print("[MLX] Queue download for \(m.name) → \(m.hfRepo)")
            } label: {
                Text("加载").font(.system(size: 9, weight: .medium))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(.orange.opacity(0.15)))
                    .foregroundStyle(.orange)
            }
            .buttonStyle(.plain)
        }
        .padding(9)
        .background(RoundedRectangle(cr: 12).fill(.ultraThinMaterial.opacity(0.4)))
        .overlay(RoundedRectangle(cr: 12).strokeBorder(.white.opacity(0.05), lineWidth: 0.5))
    }
}

// ── HF Model Cards ──
struct HFList: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let s: String
    @EnvironmentObject var vm: PetViewModel
    @State private var selectedModel: HuggingModel? = nil

    // ── 量化选项 ──
    struct QuantOption: Identifiable, Hashable {
        let id = UUID(); let label: String; let kind: String
        let fileSuffix: String; let sizeMB: Int; let isMMProj: Bool
    }

    struct HuggingModel: Identifiable {
        let id = UUID(); let name, author, size, downloads: String
        let quantizations: [QuantOption]; let tags: [String]; let gradient: [Color]
        let desc: String; let params: String
        let hfRepo: String
        let hasMMProj: Bool; let mmprojRepo: String; let mmprojFile: String
        
        /// 从 hfRepo 提取文件前缀（保留原始大小写）
        /// "bartowski/Meta-Llama-3.1-8B-Instruct-GGUF" → "Meta-Llama-3.1-8B-Instruct"
        var hfFilePrefix: String {
            let parts = hfRepo.split(separator: "/")
            guard let last = parts.last else { return name.replacingOccurrences(of: " ", with: "-") }
            return String(last).replacingOccurrences(of: "-GGUF", with: "", options: .caseInsensitive)
        }
        
        func hfFile(opt: QuantOption) -> String {
            if opt.isMMProj { return mmprojFile }
            return hfFilePrefix + "-" + opt.fileSuffix
        }
    }

    private func q(_ label: String, _ suffix: String = "", _ mb: Int = 0, _ mmproj: Bool = false) -> QuantOption {
        let s = suffix.isEmpty ? (label + ".gguf") : suffix
        return QuantOption(label: label, kind: mmproj ? "MMProj" : "GGUF", fileSuffix: s, sizeMB: mb, isMMProj: mmproj)
    }
    private func awq(_ label: String = "AWQ-INT4", _ mb: Int = 0) -> QuantOption {
        QuantOption(label: label, kind: "AWQ", fileSuffix: "awq-int4", sizeMB: mb, isMMProj: false)
    }
    private func gptq(_ label: String = "GPTQ-INT4", _ mb: Int = 0) -> QuantOption {
        QuantOption(label: label, kind: "GPTQ", fileSuffix: "gptq-int4", sizeMB: mb, isMMProj: false)
    }
    private func fp8(_ label: String = "FP8", _ mb: Int = 0) -> QuantOption {
        QuantOption(label: label, kind: "FP8", fileSuffix: "fp8", sizeMB: mb, isMMProj: false)
    }
    private func nvfp4(_ label: String = "NVFP4", _ mb: Int = 0) -> QuantOption {
        QuantOption(label: label, kind: "NVFP4", fileSuffix: "nvfp4", sizeMB: mb, isMMProj: false)
    }
    private func mmproj(_ label: String, _ mb: Int = 0) -> QuantOption {
        QuantOption(label: label, kind: "MMProj", fileSuffix: label + ".gguf", sizeMB: mb, isMMProj: true)
    }

    @State private var models: [HuggingModel] = []

    var filtered: [HuggingModel] {
        s.isEmpty ? models : models.filter { $0.name.localizedCaseInsensitiveContains(s) || $0.author.localizedCaseInsensitiveContains(s) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filtered) { m in
                    ModelCard(m: m)
                        .onTapGesture { selectedModel = m }
                }
            }.padding(10)
        }
        .onAppear { if models.isEmpty { load() } }
        .sheet(item: $selectedModel) { m in
            ModelDetailSheet(m: m)
                .frame(width: 520, height: 620)
        }
    }

    func load() {
        models = [
            // ━━━ 🔥 去审查版 Gemma 4 (靠前) ━━━
            HuggingModel(name: "Gemma 4 E4B Uncensored", author: "HauhauCS", size: "~2.8 GB", downloads: "5.1K",
                quantizations: [q("Q4_K_M"), q("Q5_K_M"), q("Q8_0")],
                tags: ["去审查", "进攻型"], gradient: [c("#ef4444"), c("#f97316")],
                desc: "Gemma 4 4B 去审查进攻版，HauhauCS 调校，无安全对齐。", params: "4B",
                hfRepo: "HauhauCS/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive", hasMMProj: true, mmprojRepo: "HauhauCS/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive", mmprojFile: "mmproj-Q8_K_P.gguf"),
            HuggingModel(name: "Gemma 4 E2B Uncensored", author: "HauhauCS", size: "~1.5 GB", downloads: "4.8K",
                quantizations: [q("Q4_K_M"), q("Q8_0")],
                tags: ["去审查", "轻量"], gradient: [c("#ef4444"), c("#dc2626")],
                desc: "Gemma 4 2B 去审查版，HauhauCS 进攻型调校，极轻量无限制。", params: "2B",
                hfRepo: "HauhauCS/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive", hasMMProj: true, mmprojRepo: "HauhauCS/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive", mmprojFile: "mmproj-Q8_K_P.gguf"),
            // ━━━ Gemma 4 ━━━
            HuggingModel(name: "Gemma 4 E2B", author: "Google", size: "~1.5 GB", downloads: "3.8M",
                quantizations: [q("IQ2_XXS"), q("IQ3_XXS"), q("Q4_K_M"), q("Q5_K_M"), awq(), gptq(), fp8()],
                tags: ["轻量", "开放"], gradient: [c("#4285F4"), c("#669df6")],
                desc: "Google Gemma 4 2B，开放商用。", params: "2B",
                hfRepo: "bartowski/gemma-4-2b-it-GGUF", hasMMProj: true, mmprojRepo: "bartowski/gemma-4-4b-it-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
            HuggingModel(name: "Gemma 4 E4B", author: "Google", size: "~2.8 GB", downloads: "4.2M",
                quantizations: [q("IQ2_XXS"), q("IQ3_XXS"), q("Q4_K_M"), q("Q5_K_M"), awq(), gptq(), fp8()],
                tags: ["均衡", "开放"], gradient: [c("#4285F4"), c("#8ab4f8")],
                desc: "Google Gemma 4 4B，轻量高性能。", params: "4B",
                hfRepo: "bartowski/gemma-4-4b-it-GGUF", hasMMProj: true, mmprojRepo: "bartowski/gemma-4-4b-it-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
            HuggingModel(name: "Gemma 4 26B MoE", author: "Google", size: "~16 GB", downloads: "5.9M",
                quantizations: [q("IQ2_XXS"), q("IQ3_XXS"), q("Q4_K_M"), q("Q5_K_M"), awq(), gptq(), fp8()],
                tags: ["MoE", "旗舰"], gradient: [c("#4285F4"), c("#1a73e8")],
                desc: "Google Gemma 4 MoE，26B/6B 高效旗舰。", params: "26B/6B",
                hfRepo: "bartowski/gemma-4-26b-it-GGUF", hasMMProj: true, mmprojRepo: "bartowski/gemma-4-4b-it-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
            HuggingModel(name: "Gemma 4 31B", author: "Google", size: "~19 GB", downloads: "5.1M",
                quantizations: [q("IQ2_XXS"), q("IQ3_XXS"), q("Q4_K_M"), q("Q5_K_M"), awq(), gptq(), fp8()],
                tags: ["旗舰", "开放"], gradient: [c("#1a73e8"), c("#174ea6")],
                desc: "Google Gemma 4 31B，最强开放模型之一。", params: "31B",
                hfRepo: "bartowski/gemma-4-31b-it-GGUF", hasMMProj: true, mmprojRepo: "bartowski/gemma-4-4b-it-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
            // ━━━ Qwen 3.5 ━━━
            HuggingModel(name: "Qwen 3.5 0.8B", author: "Qwen", size: "~600 MB", downloads: "3.2M",
                quantizations: [q("Q2_K"), q("Q4_K_M"), q("Q5_K_M"), q("Q6_K"), awq(), gptq(), fp8()],
                tags: ["中文", "轻量"], gradient: [c("#6366f1"), c("#818cf8")],
                desc: "通义千问 3.5 最小版，0.8B，适合嵌入和边缘设备。", params: "0.8B",
                hfRepo: "Qwen/Qwen3.5-0.8B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Qwen 3.5 2B", author: "Qwen", size: "~1.5 GB", downloads: "4.1M",
                quantizations: [q("Q2_K"), q("Q4_K_M"), q("Q5_K_M"), q("Q6_K"), awq(), gptq(), fp8()],
                tags: ["中文", "入门"], gradient: [c("#6366f1"), c("#818cf8")],
                desc: "通义千问 3.5 2B，轻量全能，适合消费级设备。", params: "2B",
                hfRepo: "Qwen/Qwen3.5-2B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Qwen 3.5 4B", author: "Qwen", size: "~2.9 GB", downloads: "5.3M",
                quantizations: [q("Q2_K"), q("Q4_K_M"), q("Q5_K_M"), q("Q6_K"), awq(), gptq(), fp8()],
                tags: ["中文", "均衡"], gradient: [c("#6366f1"), c("#a5b4fc")],
                desc: "通义千问 3.5 4B，日常对话最佳性价比。", params: "4B",
                hfRepo: "Qwen/Qwen3.5-4B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Qwen 3.5 9B", author: "Qwen", size: "~5.8 GB", downloads: "7.2M",
                quantizations: [q("Q2_K"), q("Q4_K_M"), q("Q5_K_M"), q("Q6_K"), awq(), gptq(), fp8()],
                tags: ["中文", "通用"], gradient: [c("#6366f1"), c("#a78bfa")],
                desc: "通义千问 3.5 9B，实用级通用模型。", params: "9B",
                hfRepo: "Qwen/Qwen3.5-9B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Qwen 3.5 27B", author: "Qwen", size: "~16 GB", downloads: "6.8M",
                quantizations: [q("Q2_K"), q("Q4_K_M"), q("Q5_K_M"), q("Q6_K"), awq(), gptq(), fp8()],
                tags: ["中文", "高性能"], gradient: [c("#4f46e5"), c("#818cf8")],
                desc: "通义千问 3.5 27B，旗舰级通用模型。", params: "27B",
                hfRepo: "Qwen/Qwen3.5-27B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Qwen 3.5 397B", author: "Qwen", size: "~240 GB", downloads: "2.8M",
                quantizations: [q("Q2_K"), q("Q4_K_M"), q("Q5_K_M"), q("Q6_K"), awq(), gptq(), fp8()],
                tags: ["中文", "旗舰"], gradient: [c("#4338ca"), c("#6366f1")],
                desc: "通义千问 3.5 397B MoE，顶尖智能。", params: "397B/52B",
                hfRepo: "Qwen/Qwen3.5-397B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            // ━━━ Qwen 3.6 ━━━
            HuggingModel(name: "Qwen 3.6 27B", author: "Qwen", size: "~16 GB", downloads: "5.6M",
                quantizations: [q("UD-Q2_K_XL"), q("UD-Q4_K_XL"), q("Q5_K_M"), q("Q6_K"), awq(), gptq(), fp8()],
                tags: ["中文", "最新"], gradient: [c("#7c3aed"), c("#a78bfa")],
                desc: "通义千问 3.6 27B，推理数学大幅增强。", params: "27B",
                hfRepo: "Qwen/Qwen3.6-27B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Qwen 3.6 35B-A3B", author: "Qwen", size: "~3 GB", downloads: "6.1M",
                quantizations: [q("UD-Q2_K_XL"), q("UD-Q4_K_XL"), q("Q5_K_M"), awq(), gptq(), fp8(), nvfp4()],
                tags: ["MoE", "高效"], gradient: [c("#7c3aed"), c("#c084fc")],
                desc: "通义千问 3.6 MoE，35B/3B 极致高效。", params: "35B/3B",
                hfRepo: "Qwen/Qwen3.6-35B-A3B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            // ━━━ Mistral / Nemotron / Helios / LTX ━━━
            HuggingModel(name: "Mistral Small 4", author: "Mistral", size: "~69 GB", downloads: "4.8M",
                quantizations: [q("Q4_K_M"), gptq(), awq()],
                tags: ["MoE", "旗舰"], gradient: [c("#ec4899"), c("#f472b6")],
                desc: "Mistral Small 4，119B MoE，128K 上下文。", params: "119B/20B",
                hfRepo: "bartowski/Mistral-Small-4-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Helios", author: "PKU/Bytedance", size: "~14 GB", downloads: "2.3M",
                quantizations: [q("Q4_K_M"), awq()],
                tags: ["国产", "推理"], gradient: [c("#f97316"), c("#fb923c")],
                desc: "北大+字节联合 Helios，国产强力推理。", params: "27B",
                hfRepo: "bartowski/Helios-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Nemotron 3 Super", author: "NVIDIA", size: "~14 GB", downloads: "3.6M",
                quantizations: [q("Q4_K_M"), awq(), fp8()],
                tags: ["通用", "企业"], gradient: [c("#76b900"), c("#a3e635")],
                desc: "NVIDIA Nemotron 3 Super，企业级通用。", params: "27B",
                hfRepo: "bartowski/Nemotron-3-Super-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "LTX 2.3", author: "Lightricks", size: "~8 GB", downloads: "1.5M",
                quantizations: [q("Q4_K_M"), awq()],
                tags: ["视频", "创意"], gradient: [c("#8b5cf6"), c("#c084fc")],
                desc: "Lightricks LTX 2.3，视频理解创意模型。", params: "14B",
                hfRepo: "bartowski/LTX-2.3-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            // ━━━ GLM 系列 ━━━
            HuggingModel(name: "GLM 5.1", author: "Zhipu", size: "~15 GB", downloads: "4.3M",
                quantizations: [q("Q4_K_M"), awq(), gptq()],
                tags: ["中文", "全模态"], gradient: [c("#3b82f6"), c("#60a5fa")],
                desc: "智谱 GLM 5.1，文本/图像/视频多模态。", params: "32B",
                hfRepo: "bartowski/GLM-5.1-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "GLM 6 130B", author: "Zhipu", size: "~78 GB", downloads: "2.1M",
                quantizations: [q("Q4_K_M"), awq(), fp8()],
                tags: ["中文", "超大规模"], gradient: [c("#1d4ed8"), c("#3b82f6")],
                desc: "智谱 GLM 6 130B，千亿参数旗舰。", params: "130B",
                hfRepo: "bartowski/GLM-6-130B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            // ━━━ 国产 ━━━
            HuggingModel(name: "MiMo V2.5", author: "Xiaomi", size: "~5 GB", downloads: "2.5M",
                quantizations: [q("Q4_K_M"), awq()],
                tags: ["国产", "通用"], gradient: [c("#ff6900"), c("#ff9500")],
                desc: "小米 MiMo V2.5，国产通用新势力。", params: "8B",
                hfRepo: "bartowski/MiMo-V2.5-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "MiMo V2.5 Pro", author: "Xiaomi", size: "~16 GB", downloads: "1.8M",
                quantizations: [q("Q4_K_M"), awq()],
                tags: ["国产", "专业"], gradient: [c("#ff6900"), c("#ff3b30")],
                desc: "小米 MiMo V2.5 Pro，专业级国产模型。", params: "32B",
                hfRepo: "bartowski/MiMo-V2.5-Pro-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "MiniMax M2.7", author: "MiniMax", size: "~18 GB", downloads: "3.1M",
                quantizations: [q("Q4_K_M"), awq()],
                tags: ["国产", "长上下文"], gradient: [c("#06b6d4"), c("#22d3ee")],
                desc: "MiniMax M2.7，超长上下文。", params: "32B",
                hfRepo: "bartowski/MiniMax-M2.7-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "Kimi K2.6", author: "Moonshot", size: "~19 GB", downloads: "6.8M",
                quantizations: [q("Q4_K_M"), awq(), fp8()],
                tags: ["国产", "128K"], gradient: [c("#10b981"), c("#34d399")],
                desc: "月之暗面 Kimi K2.6，超长上下文。", params: "32B",
                hfRepo: "bartowski/Kimi-K2.6-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "DeepSeek V4", author: "DeepSeek", size: "~140 GB", downloads: "9.2M",
                quantizations: [q("Q4_K_M"), awq(), gptq()],
                tags: ["旗舰", "MoE"], gradient: [c("#06b6d4"), c("#22d3ee")],
                desc: "深度求索 V4，236B/20B MoE 旗舰。", params: "236B/20B",
                hfRepo: "bartowski/DeepSeek-V4-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "DeepSeek V4 Pro", author: "DeepSeek", size: "~180 GB", downloads: "7.5M",
                quantizations: [q("Q4_K_M"), awq(), gptq()],
                tags: ["旗舰", "专业"], gradient: [c("#0891b2"), c("#06b6d4")],
                desc: "深度求索 V4 Pro，300B/30B 专业旗舰。", params: "300B/30B",
                hfRepo: "bartowski/DeepSeek-V4-Pro-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "DeepSeek V4 Flash", author: "DeepSeek", size: "~20 GB", downloads: "8.3M",
                quantizations: [q("Q4_K_M"), awq(), gptq()],
                tags: ["轻量", "高速"], gradient: [c("#0ea5e9"), c("#38bdf8")],
                desc: "DeepSeek V4 Flash，37B/4B 轻量版。", params: "37B/4B",
                hfRepo: "bartowski/DeepSeek-V4-Flash-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "SenseNova U1", author: "SenseTime", size: "~16 GB", downloads: "1.9M",
                quantizations: [q("Q4_K_M"), awq()],
                tags: ["国产", "多模态"], gradient: [c("#8b5cf6"), c("#d8b4fe")],
                desc: "商汤 SenseNova U1，国产多模态新标杆。", params: "32B",
                hfRepo: "bartowski/SenseNova-U1-GGUF", hasMMProj: true, mmprojRepo: "bartowski/SenseNova-U1-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
            // ━━━ Llama 4 ━━━
            HuggingModel(name: "Llama 4 Scout", author: "Meta", size: "~11 GB", downloads: "7.2M",
                quantizations: [q("Q4_K_M"), awq()],
                tags: ["多模态", "轻量"], gradient: [c("#f59e0b"), c("#f97316")],
                desc: "Meta Llama 4 Scout，17B 多模态。", params: "17B",
                hfRepo: "bartowski/Llama-4-Scout-17B-Instruct-GGUF", hasMMProj: true, mmprojRepo: "bartowski/Llama-4-Scout-17B-Instruct-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
            HuggingModel(name: "Llama 4 Maverick", author: "Meta", size: "~42 GB", downloads: "6.8M",
                quantizations: [q("Q4_K_M"), awq()],
                tags: ["通用", "旗舰"], gradient: [c("#f59e0b"), c("#ef4444")],
                desc: "Meta Llama 4 Maverick，70B 通用旗舰。", params: "70B",
                hfRepo: "bartowski/Meta-Llama-4-Maverick-17B-128E-Instruct-GGUF", hasMMProj: true, mmprojRepo: "bartowski/Meta-Llama-4-Maverick-17B-128E-Instruct-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
            HuggingModel(name: "Llama 4 Ultra", author: "Meta", size: "~242 GB", downloads: "3.5M",
                quantizations: [q("Q4_K_M"), awq(), fp8()],
                tags: ["超大规模", "旗舰"], gradient: [c("#dc2626"), c("#f97316")],
                desc: "Meta Llama 4 Ultra，405B 终极旗舰。", params: "405B",
                hfRepo: "bartowski/Meta-Llama-4-Ultra-GGUF", hasMMProj: true, mmprojRepo: "bartowski/Meta-Llama-4-Ultra-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
            // ━━━ 其他 ━━━
            HuggingModel(name: "SmolAgent 2B", author: "HuggingFace", size: "~1.3 GB", downloads: "2.2M",
                quantizations: [q("Q2_K"), q("Q4_K_M"), awq()],
                tags: ["Agent", "轻量"], gradient: [c("#fbbf24"), c("#f59e0b")],
                desc: "HuggingFace SmolAgent 2B，Agent 任务优化。", params: "2B",
                hfRepo: "bartowski/SmolAgent-2B-GGUF", hasMMProj: false, mmprojRepo: "", mmprojFile: ""),
            HuggingModel(name: "BARD VL", author: "BARD", size: "~8 GB", downloads: "1.2M",
                quantizations: [q("Q4_K_M"), fp8()],
                tags: ["多模态", "视觉"], gradient: [c("#ec4899"), c("#8b5cf6")],
                desc: "BARD 视觉语言模型，图文理解生成。", params: "14B",
                hfRepo: "bartowski/BARD-VL-GGUF", hasMMProj: true, mmprojRepo: "bartowski/BARD-VL-GGUF", mmprojFile: "mmproj-Q8_K_P.gguf"),
        ]
    }
}

struct ModelCard: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let m: HFList.HuggingModel
    @EnvironmentObject var vm: PetViewModel

    var body: some View {
        HStack(spacing: 10) {
            // Gradient icon
            RoundedRectangle(cr: 10)
                .fill(LinearGradient(colors: m.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "cube.fill").font(.system(size: 14)).foregroundStyle(.white.opacity(0.85)))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(m.name).font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text(m.params).font(.system(size: 8.5, design: .monospaced))
                        .padding(.horizontal, 4).padding(.vertical, 2)
                        .background(.ultraThinMaterial).clipShape(Capsule())
                }
                HStack(spacing: 4) {
                    Text(m.author).font(.system(size: 9.5)).foregroundStyle(.purple.opacity(0.8))
                    Text("·").foregroundStyle(.tertiary)
                    Text(m.size).font(.system(size: 9.5, design: .monospaced)).foregroundStyle(.secondary)
                }
            }
            Spacer()

            // Quant badges
            ForEach(m.quantizations.prefix(3).filter { !$0.isMMProj }, id: \.id) { opt in
                Button {
                    vm.downloadModel(m.name, repo: m.hfRepo, opt: opt, fileName: m.hfFile(opt: opt),
                        mmprojRepo: m.hasMMProj ? m.mmprojRepo : "", mmprojFile: m.hasMMProj ? m.mmprojFile : "")
                } label: {
                    Text(opt.label).font(.system(size: 7.5, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(.blue.opacity(0.12)))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(9)
        .background(RoundedRectangle(cr: 12).fill(.ultraThinMaterial.opacity(0.4)))
        .overlay(RoundedRectangle(cr: 12).strokeBorder(.white.opacity(0.05), lineWidth: 0.5))
        .contentShape(RoundedRectangle(cr: 12))
        .contextMenu {
            ForEach(m.quantizations.prefix(5).filter { !$0.isMMProj }, id: \.id) { opt in
                Button {
                    vm.downloadModel(m.name, repo: m.hfRepo, opt: opt, fileName: m.hfFile(opt: opt),
                        mmprojRepo: m.hasMMProj ? m.mmprojRepo : "", mmprojFile: m.hasMMProj ? m.mmprojFile : "")
                } label: {
                    Label("下载 \(opt.label) (\(opt.kind))", systemImage: "arrow.down.circle")
                }
            }
            if m.hasMMProj {
                Divider()
                Button {
                    let mmOpt = HFList.QuantOption(label: "Q8_K_P", kind: "MMProj", fileSuffix: "mmproj-Q8_K_P.gguf", sizeMB: 0, isMMProj: true)
                    vm.downloadModel(m.name, repo: m.mmprojRepo, opt: mmOpt, fileName: m.mmprojFile, mmprojRepo: "", mmprojFile: "")
                } label: {
                    Label(i18n["models.download_mmproj"], systemImage: "eye")
                }
            }
        }
    }
}

// ── Model Detail Sheet ──
struct ModelDetailSheet: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let m: HFList.HuggingModel
    @EnvironmentObject var vm: PetViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
                Spacer()
            }.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

            // Hero
            VStack(spacing: 12) {
                RoundedRectangle(cr: 14)
                    .fill(LinearGradient(colors: m.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 70, height: 70)
                    .overlay(Image(systemName: "cpu.fill").font(.system(size: 28)).foregroundStyle(.white.opacity(0.9)))
                    .shadow(color: m.gradient[0].opacity(0.4), radius: 16)

                Text(m.name).font(.system(size: 22, weight: .bold, design: .rounded))
                Text(m.author).font(.system(size: 12)).foregroundStyle(.purple)
                Text(m.desc).font(.system(size: 11, design: .rounded)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
            }.padding(.bottom, 16)

            Divider().padding(.horizontal, 20)

            // Specs
            HStack(spacing: 24) {
                detailSpec("cpu", i18n["models.params"], m.params)
                detailSpec("internaldrive", "大小", m.size)
                detailSpec("arrow.down.to.line", "下载", m.downloads)
                detailSpec("tag", i18n["models.quantization"], "\(m.quantizations.filter { !$0.isMMProj }.count)种")
            }.padding(.vertical, 14)

            Divider().padding(.horizontal, 20)

            // Quantization download buttons
            VStack(alignment: .leading, spacing: 8) {
                Text(i18n["models.select_quant"]).font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    .padding(.horizontal, 20).padding(.top, 12)
                let nonMM = m.quantizations.filter { !$0.isMMProj }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(nonMM, id: \.id) { opt in
                        Button {
                            vm.downloadModel(m.name, repo: m.hfRepo, opt: opt, fileName: m.hfFile(opt: opt),
                                mmprojRepo: m.hasMMProj ? m.mmprojRepo : "", mmprojFile: m.hasMMProj ? m.mmprojFile : "")
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle.fill").font(.system(size: 9))
                                Text(opt.label).font(.system(size: 10, design: .monospaced))
                                Text(opt.kind).font(.system(size: 7)).foregroundStyle(.white.opacity(0.6))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10).padding(.vertical, 7)
                            .background(RoundedRectangle(cr: 7).fill(
                                LinearGradient(colors: m.gradient, startPoint: .leading, endPoint: .trailing)))
                        }
                        .buttonStyle(.plain)
                    }
                }.padding(.horizontal, 20)
                
                // MMProj section for multimodal models
                if m.hasMMProj {
                    Divider().padding(.horizontal, 20).padding(.vertical, 4)
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill").font(.system(size: 9)).foregroundStyle(.orange)
                        Text("多模态").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                        Text(i18n["models.mmproj_hint"]).font(.system(size: 8)).foregroundStyle(.tertiary)
                    }.padding(.horizontal, 20)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(["Q8_K_P", "Q6_K_P", "Q5_K_P", "Q4_K_P", "Q3_K_P", "Q2_K_P"], id: \.self) { mm in
                            Button {
                                let opt = HFList.QuantOption(label: mm, kind: "MMProj", fileSuffix: "mmproj-" + mm + ".gguf", sizeMB: 0, isMMProj: true)
                                vm.downloadModel(m.name, repo: m.mmprojRepo, opt: opt, fileName: m.mmprojFile, mmprojRepo: "", mmprojFile: "")
                            } label: {
                                Text(mm).font(.system(size: 8, design: .monospaced))
                                    .padding(.horizontal, 6).padding(.vertical, 4)
                                    .background(Capsule().fill(.orange.opacity(0.12)))
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                        }
                    }.padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 12)

            Spacer()
        }
        .frame(width: 440, height: 500)
    }

    func detailSpec(_ icon: String, _ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(.purple.opacity(0.6))
            Text(value).font(.system(size: 11.5, weight: .semibold, design: .rounded))
            Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }
}

// ── Local Models ──
struct LocalModelRow: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    let name: String; let isDefault: Bool; let isSelected: Bool; let selectMode: Bool
    let onToggle: () -> Void
    let fileSize: String; let fileDate: Date?
    @EnvironmentObject var vm: PetViewModel

    var body: some View {
        HStack {
            if selectMode {
                Button(action: onToggle) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12)).foregroundStyle(isSelected ? .blue : .secondary)
                }.buttonStyle(.plain)
            }
            Image(systemName: "shippingbox.fill").foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).font(.system(size: 12, design: .rounded))
                HStack(spacing: 4) {
                    Text("GGUF").font(.system(size: 8.5)).foregroundStyle(.tertiary)
                    Text("·").foregroundStyle(.tertiary)
                    Text(fileSize).font(.system(size: 8.5, design: .monospaced)).foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.tertiary)
                    if let d = fileDate {
                        Text(d, format: .dateTime.month(.abbreviated).day()).font(.system(size: 8.5)).foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
            Circle().fill(isDefault ? .blue : .green).frame(width: 6, height: 6)
            if !selectMode {
                Menu {
                    Button { vm.chatModel = name } label: { Label(i18n["ui.set_default"], systemImage: "checkmark.circle") }
                    Button {
                        let f = ModelDownloadManager.modelsDir + "/" + name + ".gguf"
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: f)])
                    } label: { Label("在 Finder 中显示", systemImage: "folder") }
                    Divider()
                    Button(role: .destructive) {
                        vm.downloadedModels.removeAll { $0 == name }
                        try? FileManager.default.removeItem(atPath: ModelDownloadManager.modelsDir + "/" + name + ".gguf")
                    } label: { Label(i18n["ui.delete"], systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 11)).foregroundStyle(.secondary)
                }.buttonStyle(.plain).frame(width: 24)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cr: 8).fill(
    isSelected ? AnyShapeStyle(.blue.opacity(0.08)) : AnyShapeStyle(.ultraThinMaterial.opacity(0.35))))
        .padding(.horizontal, 12)
        .onDrag { NSItemProvider(object: (ModelDownloadManager.modelsDir + "/" + name + ".gguf") as NSString) }
        .contextMenu {
            Button { vm.chatModel = name } label: { Label(i18n["models.set_default"], systemImage: "checkmark.circle") }
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: ModelDownloadManager.modelsDir + "/" + name + ".gguf")])
            } label: { Label("在 Finder 中显示", systemImage: "folder") }
            Divider()
            Button { NSWorkspace.shared.open(URL(fileURLWithPath: ModelDownloadManager.modelsDir)) } label: {
                Label("打开 Models 文件夹", systemImage: "folder.badge.gearshape")
            }
            Divider()
            Button(role: .destructive) {
                vm.downloadedModels.removeAll { $0 == name }
                try? FileManager.default.removeItem(atPath: ModelDownloadManager.modelsDir + "/" + name + ".gguf")
            } label: { Label(i18n["models.delete_files"], systemImage: "trash") }
        }
    }
}


struct LocalModelsView: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    @EnvironmentObject var vm: PetViewModel
    @State private var sortMode = 0  // 0=name, 1=size, 2=date
    @State private var selectMode = false
    @State private var selected: Set<String> = []

    var body: some View {
        let both = Set(vm.downloadedModels).union(vm.downloadManager.completedModels.map {
            $0.modelName + "-" + $0.quantLabel
        })
        let raw = Array(both)
        let sorted = sortMode == 0 ? raw.sorted() :
                     sortMode == 1 ? raw.sorted(by: { (modelSize($0) ?? 0) > (modelSize($1) ?? 0) }) :
                     raw.sorted(by: { (modelDate($0) ?? Date.distantPast) > (modelDate($1) ?? Date.distantPast) })

        // Total storage
        let totalBytes: Int64 = sorted.reduce(0) { $0 + Int64(modelSize($1) ?? 0) }

        if sorted.isEmpty {
            est("tray", i18n["models.no_local"], i18n["models.import_hint"])
        } else {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("已下载 (\(sorted.count))").font(.system(size: 11, weight: .semibold)).foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.tertiary)
                    Text(formatStorage(totalBytes)).font(.system(size: 9.5, design: .monospaced)).foregroundStyle(.blue)
                    Spacer()
                    // Sort picker
                    Picker("", selection: $sortMode) {
                        Text(i18n["models.name"]).tag(0); Text("大小").tag(1); Text(i18n["models.date"]).tag(2)
                    }.pickerStyle(.menu).frame(width: 55)
                    .font(.system(size: 9)).foregroundStyle(.secondary)

                    // Batch actions
                    if selectMode {
                        Button(i18n["ui.cancel"]) { selectMode = false; selected.removeAll() }
                            .font(.system(size: 9)).foregroundStyle(.orange)
                        if !selected.isEmpty {
                            Button("删除 \(selected.count) 个", role: .destructive) {
                                for n in selected {
                                    vm.downloadedModels.removeAll { $0 == n }
                                    try? FileManager.default.removeItem(atPath: ModelDownloadManager.modelsDir + "/" + n + ".gguf")
                                }
                                selected.removeAll(); selectMode = false
                            }.font(.system(size: 9))
                        }
                    }
                    Button { selectMode.toggle(); selected.removeAll() } label: {
                        Image(systemName: selectMode ? "checkmark.circle.fill" : "checklist")
                            .font(.system(size: 11)).foregroundStyle(selectMode ? .orange : .secondary)
                    }.buttonStyle(.plain).help(i18n["ui.batch_select"])
                    
                    Button {
                        NSWorkspace.shared.open(URL(fileURLWithPath: ModelDownloadManager.modelsDir))
                    } label: {
                        Image(systemName: "folder").font(.system(size: 11)).foregroundStyle(.secondary).padding(.leading, 4)
                    }.buttonStyle(.plain).help("打开 Models 文件夹")
                    
                    Button { 
                        vm.scanDownloadedModels()
                        vm.showToast("🔄 已刷新")
                    } label: {
                        Image(systemName: "arrow.clockwise").font(.system(size: 10)).foregroundStyle(.secondary).padding(.leading, 2)
                    }.buttonStyle(.plain).help(i18n["ui.refresh"])
                    
                    Button { importModel() } label: {
                        Image(systemName: "plus").font(.system(size: 11)).foregroundStyle(.purple).padding(.leading, 4)
                    }.buttonStyle(.plain)
                }.padding(.horizontal, 10).padding(.top, 10).padding(.bottom, 6)

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(sorted, id: \.self) { n in
                            LocalModelRow(name: n, isDefault: vm.chatModel == n,
                                          isSelected: selected.contains(n), selectMode: selectMode,
                                          onToggle: { if selected.contains(n) { selected.remove(n) } else { selected.insert(n) } },
                                          fileSize: modelSize(n).map { formatFileSize(Int64($0)) } ?? "—",
                                          fileDate: modelDate(n))
                        }
                    }.padding(.vertical, 8)
                }
                    .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    for p in providers {
                        p.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, _) in
                            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil),
                                  url.pathExtension.lowercased() == "gguf" else { return }
                            DispatchQueue.main.async {
                                let dest = URL(fileURLWithPath: ModelDownloadManager.modelsDir).appendingPathComponent(url.lastPathComponent)
                                try? FileManager.default.copyItem(at: url, to: dest)
                                let base = url.deletingPathExtension().lastPathComponent
                                if !vm.downloadedModels.contains(base) { vm.downloadedModels.append(base) }
                                vm.scanDownloadedModels()
                                vm.showToast("✅ 已导入 \(url.lastPathComponent)")
                            }
                        }
                    }
                    return true
                }
            }
        }
    }

    func modelSize(_ name: String) -> Int? {
        let path = ModelDownloadManager.modelsDir + "/" + name + ".gguf"
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        return (attrs[.size] as? NSNumber)?.intValue
    }

    func modelDate(_ name: String) -> Date? {
        let path = ModelDownloadManager.modelsDir + "/" + name + ".gguf"
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        return attrs[.modificationDate] as? Date
    }

    func formatStorage(_ b: Int64) -> String {
        if b < 1024 { return "\(b) B" }
        if b < 1048576 { return String(format: "%.1f KB", Double(b)/1024) }
        if b < 1073741824 { return String(format: "%.1f MB", Double(b)/1048576) }
        return String(format: "%.2f GB", Double(b)/1073741824)
    }

    func formatFileSize(_ b: Int64) -> String {
        if b < 1024 { return "\(b) B" }
        if b < 1048576 { return String(format: "%.1f KB", Double(b)/1024) }
        if b < 1073741824 { return String(format: "%.1f MB", Double(b)/1048576) }
        return String(format: "%.2f GB", Double(b)/1073741824)
    }



    func importModel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = []
        panel.title = i18n["models.import_desc"]
        panel.begin { resp in
            guard resp == .OK else { return }
            let dest = ModelDownloadManager.modelsDir
            try? FileManager.default.createDirectory(atPath: dest, withIntermediateDirectories: true)
            for url in panel.urls {
                let name = url.lastPathComponent
                let destURL = URL(fileURLWithPath: dest).appendingPathComponent(name)
                try? FileManager.default.copyItem(at: url, to: destURL)
                let base = (name as NSString).deletingPathExtension
                if !vm.downloadedModels.contains(base) {
                    vm.downloadedModels.append(base)
                }
            }
            vm.scanDownloadedModels()
        }
    }
}

struct LMStudioModelsView: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    var body: some View { est("app.connected.to.app.below.fill", "LM Studio", i18n["models.auto_discover"]) }
}

struct HistoryView: View {
    @EnvironmentObject var i18n: I18NManager
    private var navItems: [NavItem] {
        [
            NavItem(icon: "person.2.fill", title: i18n["sidebar.pets"], tab: .characters),
            NavItem(icon: "bubble.left.and.bubble.right.fill", title: i18n["sidebar.chat"], tab: .chat),
            NavItem(icon: "cpu.fill", title: i18n["sidebar.models"], tab: .models),
            NavItem(icon: "clock.arrow.circlepath", title: i18n["sidebar.history"], tab: .history),
            NavItem(icon: "gearshape.fill", title: i18n["sidebar.settings"], tab: .settings),
        ]
    }

    var body: some View { est("clock.arrow.circlepath", i18n["chat.no_history"], i18n["chat.history_hint"]) } }

func est(_ icon: String, _ t: String, _ s: String) -> some View {
    VStack(spacing: 10) {
        Spacer()
        Image(systemName: icon).font(.system(size: 34)).foregroundStyle(.secondary.opacity(0.35))
        Text(t).font(.system(size: 12.5, design: .rounded)).foregroundStyle(.secondary)
        Text(s).font(.system(size: 10.5, design: .rounded)).foregroundStyle(.tertiary)
        Spacer()
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
}

// ── Helpers ──
// AboutView is in separate file AboutView.swift

extension RoundedRectangle { init(cr: CGFloat) { self.init(cornerRadius: cr, style: .continuous) } }
func c(_ h: String) -> Color { Color(hex: h) }
extension Color {
    init(hex h: String) {
        let h = h.trimmingCharacters(in: .alphanumerics.inverted)
        var i: UInt64 = 0
        Scanner(string: h).scanHexInt64(&i)
        self.init(red: Double((i>>16)&0xFF)/255, green: Double((i>>8)&0xFF)/255, blue: Double(i&0xFF)/255)
    }
}
