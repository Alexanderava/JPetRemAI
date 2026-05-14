# JPetRemAI Engine Components

This directory contains the runtime engines that power JPetRemAI. These are **large binary assets** (~450MB total) excluded from git tracking — build them from source on your machine.

## Components

| Component | Size | Purpose |
|-----------|------|---------|
| `jre/` | ~102M | JRE 17 (jlink minimal) — runs ShimejiEE Java pet engine |
| `llama/` | ~19M | llama.cpp server arm64 — GGUF model inference (port 8080) |
| `python3/` | ~320M | Python 3.12 + MLX — Apple Silicon native inference (port 8081) |
| `ShimejiEE.jar` | ~6M | Desktop pet physics/rendering engine |
| `img/` | ~15M | 17 character sprite sets (Rem, Ram, Mikasa, etc.) |

## Quick Build (all components)

```bash
cd engine

# 1. Java Runtime (JDK 17 required)
#    → jlink --add-modules java.base,java.desktop,jdk.dynalink,... → jre/

# 2. llama.cpp server (cmake required)
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 -DLLAMA_NATIVE=OFF -DGGML_NATIVE=OFF \
  -DLLAMA_METAL=ON -DLLAMA_ACCELERATE=ON -DLLAMA_OPENSSL=OFF \
  -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release ..
cmake --build . -j$(sysctl -n hw.ncpu)
#    → copy bin/llama-server + lib/*.dylib → engine/llama/
#    → install_name_tool -add_rpath @executable_path/../lib engine/llama/bin/llama-server

# 3. Python 3.12 + MLX (uv required)
uv python install 3.12
#    → copy standalone Python → engine/python3/
#    → pip install mlx mlx-lm → engine/python3/lib/python3.12/site-packages/
#    → install_name_tool fix @rpath/libpython3.12.dylib

# 4. ShimejiEE (download from upstream)
#    → download ShimejiEE.jar + character img/ folders
```

## Build & Test

After building all components, verify:

```bash
# From project root
chmod +x build.sh
./build.sh

# Test the built app
open output/JPetRemAI.app
```

## Notes

- **Total engine weight**: ~450MB unpacked, ~200MB compressed (DMG)
- **Cross-machine portability**: All engine components use relative paths (`@executable_path/../lib`) — no hardcoded `/usr/local` or Homebrew paths
- **LLM models**: NOT included in engine — users download GGUF/MLX models via the in-app model manager
- **China mirrors**: Build scripts use `HF_ENDPOINT=https://hf-mirror.com` for HuggingFace downloads
- **Security**: Only binds to `127.0.0.1` (localhost) — no remote exposure