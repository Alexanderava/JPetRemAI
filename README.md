# JPetRemAI

🤖 **macOS AI Desktop Pet — SwiftUI + ShimejiEE + Local LLM**

![Platform](https://img.shields.io/badge/platform-macOS%2015+-arm64-blue)
![Swift](https://img.shields.io/badge/Swift-5.x-FA7343)
![Java](https://img.shields.io/badge/Java-17-orange)
![License](https://img.shields.io/badge/license-MIT-green)

[日本語](./README_ja.md) | [中文](./README_zh.md)

---

## ✨ Features

### 🤖 AI Chat
- **Dual Inference Engines**: llama.cpp (GGUF) + Apple MLX (Apple Silicon native)
- **OpenAI-compatible API**: Both engines expose `/v1/chat/completions` on localhost
- **Streaming Output**: Token-by-token streaming with typing animation
- **Full Rem Persona**: Pre-configured Rem character system prompt
- **Model Management**: Browse/download GGUF & MLX models from HuggingFace Hub

### 🐾 Desktop Pet
- **17 Characters**: Rem, Ram, Mikasa, Hatsune Miku, Naruto, Killua, Kurama & more
- **Physics Animation**: ShimejiEE engine with 46-frame animation sequences
- **Interactive Behaviors**: Walking, jumping, climbing, window attachment
- **Multi-Summon**: Deploy multiple pets simultaneously on desktop

### 🎨 Modern UI
- **Glass Morphism Design**: Ultra-thin material with translucent effects
- **8-Language i18n**: en-US (default), zh-CN, zh-TW, ja-JP, ko-KR, de-DE, fr-FR, es-ES
- **Dark/Light Theme**: Adaptive color scheme
- **Compact Chat**: Modern messaging interface with code block copy

## 📦 Architecture

```
JPetRemAI.app/
├── MacOS/JPetRemAI              # SwiftUI frontend (5.3MB arm64)
├── Resources/
│   ├── llama/                   # llama.cpp inference engine
│   │   ├── bin/llama-server     #   arm64, no external deps
│   │   └── lib/*.dylib          #   8 internal libraries
│   ├── python3/                 # Python 3.12 + MLX engine (built-in, no system Python required)
│   │   └── lib/python3.12/site-packages/
│   │       └── mlx/ mlx_lm/     #   Apple Silicon native
│   ├── img/                     # Character icons for UI
│   ├── I18N.json                # 191 keys × 8 languages
│   └── ShimejiEE.jar           # Java pet engine
├── Java/Home/                   # JRE 17 (jlink minimal)
└── ...
```

- **SwiftUI ↔ TCP(17521) ↔ ShimejiEE Java Engine**: Pet summon/dismiss control
- **SwiftUI ↔ HTTP(8080/8081) ↔ llama-server/MLX**: AI chat inference
- **Fully Self-Contained**: No Homebrew, JDK, or Python3 required on target machine

## 🚀 Quick Start

### Download (macOS arm64)
Download the latest `JPetRemAI.dmg` from [Releases](https://github.com/Alexanderava/JPetRemAI/releases), mount and drag to `/Applications`.

### First Run
1. Launch JPetRemAI from Applications
2. Go to **Models** tab → download a model (GGUF or MLX)
3. Switch to **Chat** tab → start chatting with Rem
4. Go to **Pets** tab → summon desktop companions

## 🔨 Build from Source

```bash
git clone https://github.com/Alexanderava/JPetRemAI.git
cd JPetRemAI

# 1. Set up engine components (see engine/README.md)
# 2. Build
./build.sh
```

Prerequisites for building:
- macOS 15+ with Xcode CLT
- JDK 17 (for JRE bundling via jlink)
- cmake (for llama-server build)
- uv (for Python/MLX bundling)

See [engine/README.md](engine/README.md) for detailed build instructions.

## 📁 Project Structure

```
JPetRemAI/
├── Sources/
│   ├── JPetRemAI/           # SwiftUI app source
│   │   ├── ContentView.swift    # Main UI
│   │   ├── SettingsView.swift   # Settings & i18n
│   │   ├── PetViewModel.swift   # Pet & chat state
│   │   ├── JavaBridge.swift     # TCP to ShimejiEE
│   │   ├── LlamaBridge.swift    # llama.cpp HTTP API
│   │   ├── MLXBridge.swift      # MLX HTTP API
│   │   ├── ModelDownloadManager.swift
│   │   ├── I18N.swift           # i18n manager
│   │   ├── JPetRemAIApp.swift   # App entry point
│   │   ├── AboutView.swift
│   │   ├── AccessibilityBridge.swift
│   │   └── Resources/           # Icons, I18N.json, assets
│   └── custom/                  # Java bytecode patches
├── engine/                     # Engine build scripts & docs (binaries excluded from git)
├── build.sh                    # Swift compile + DMG packaging
├── screenshots/
├── README.md
└── LICENSE
```

## 🌐 i18n

| Key | en-US | zh-CN | ja-JP |
|-----|-------|-------|-------|
| `char.蕾姆` | Rem | 蕾姆 | レム |
| `char.拉姆` | Ram | 拉姆 | ラム |
| `chat.send` | Send | 发送 | 送信 |
| `settings.general` | General | 通用 | 一般 |

Full translation table: `Sources/JPetRemAI/Resources/I18N.json` (191 keys × 8 languages)

## 📄 License

MIT License — See [LICENSE](LICENSE) for details.

ShimejiEE engine is based on [Shimeji-ee](https://github.com/nick-fedesna/Shimeji-ee) (GPLv3-compatible).