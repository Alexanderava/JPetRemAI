#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# JPetRemAI v6 — SwiftUI + ShimejiEE 桌面宠物 AI 应用
# ═══════════════════════════════════════════════════════════════════
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/Sources/JPetRemAI"
OUT="$SCRIPT_DIR/output"
ENGINE="$SCRIPT_DIR/engine"
APP_NAME="JPetRemAI"
BUNDLE_ID="com.jpetrem.app.v6"
VERSION="6.0.0"
APP_BUNDLE="$OUT/$APP_NAME.app"

echo "╔══════════════════════════════════════════════════════╗"
echo "║  JPetRemAI v6 — SwiftUI + ShimejiEE 宠物 AI        ║"
echo "╚══════════════════════════════════════════════════════╝"

# ── 1. 环境 ──
if command -v xcodebuild &>/dev/null; then
    SWIFT_SDK=$(xcrun --sdk macosx --show-sdk-path)
    echo "✅ Xcode $(xcodebuild -version 2>&1 | head -1)"
else
    echo "❌ xcodebuild 不可用"; exit 1
fi

# ── 2. 准备目录 ──
rm -rf "$OUT"
mkdir -p "$OUT" "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"

# ── 3. 编译 Swift ──
echo ""
echo ">>> [1] 编译 Swift 源码..."
SWIFT_FILES=$(find "$SRC" -name "*.swift" -type f)
echo "   源文件: $(echo "$SWIFT_FILES" | wc -l | tr -d ' ') 个"

EXECUTABLE="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
swiftc -sdk "$SWIFT_SDK" -target arm64-apple-macos26 \
  -framework SwiftUI -framework AppKit -framework Foundation \
  -framework Combine -framework UserNotifications \
  -parse-as-library -o "$EXECUTABLE" $SWIFT_FILES

echo "   ✅ 编译完成: $(du -sh "$EXECUTABLE" | cut -f1)"

# ── 4. Info.plist ──
echo ""
echo ">>> [2] 配置 Info.plist..."
cp "$SRC/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# ── 5. 复制引擎 + 资源 ──
echo ""
echo ">>> [3] 复制资源..."

# ShimejiEE 引擎
if [ -d "$ENGINE" ]; then
    cp "$ENGINE/ShimejiEE.jar" "$APP_BUNDLE/Contents/Resources/"
    cp "$ENGINE/flatlaf-3.5.1.jar" "$APP_BUNDLE/Contents/Resources/"
    cp -R "$ENGINE/lib/" "$APP_BUNDLE/Contents/Resources/lib/" 2>/dev/null
    cp -R "$ENGINE/conf/" "$APP_BUNDLE/Contents/Resources/conf/" 2>/dev/null
    cp -R "$ENGINE/img/" "$APP_BUNDLE/Contents/Resources/img/" 2>/dev/null
    echo "   ✅ ShimejiEE 引擎 ($(ls "$ENGINE/img/" | wc -l | tr -d ' ') 角色)"
fi

# llama.cpp AI 推理引擎 (llama-server + dylibs, arm64)
if [ -d "$ENGINE/llama" ] && [ -f "$ENGINE/llama/bin/llama-server" ]; then
    rm -rf "$APP_BUNDLE/Contents/Resources/llama" 2>/dev/null
    cp -R "$ENGINE/llama/" "$APP_BUNDLE/Contents/Resources/llama/"
    echo "   ✅ llama-server ($(du -sh "$ENGINE/llama" | cut -f1))"
fi

# 内置 Python3.12 + MLX (Apple Silicon AI 引擎)
if [ -d "$ENGINE/python3" ] && [ -f "$ENGINE/python3/bin/python3.12" ]; then
    rm -rf "$APP_BUNDLE/Contents/Resources/python3" 2>/dev/null
    cp -R "$ENGINE/python3/" "$APP_BUNDLE/Contents/Resources/python3/"
    chmod +x "$APP_BUNDLE/Contents/Resources/python3/bin/python3.12" 2>/dev/null || true
    echo "   ✅ Python3.12 + MLX ($(du -sh "$ENGINE/python3" | cut -f1))"
fi

# JRE
if [ -d "$ENGINE/jre" ]; then
    rm -rf "$APP_BUNDLE/Contents/Java" 2>/dev/null
    cp -R "$ENGINE/jre/" "$APP_BUNDLE/Contents/Java/"
    echo "   ✅ JRE"
fi

# StartupLoader
if [ -f "$ENGINE/StartupLoader.class" ]; then
    cp "$ENGINE/StartupLoader.class" "$APP_BUNDLE/Contents/Resources/" && echo "   ✅ StartupLoader"
elif [ -x "$APP_BUNDLE/Contents/Java/Home/bin/javac" ] && [ -f "$SCRIPT_DIR/Sources/custom/StartupLoader.java" ]; then
    CP="$APP_BUNDLE/Contents/Resources/ShimejiEE.jar"
    TMPD=$(mktemp -d)
    "$APP_BUNDLE/Contents/Java/Home/bin/javac" -cp "$CP" "$SCRIPT_DIR/Sources/custom/StartupLoader.java" -d "$TMPD" 2>/dev/null && \
      mv "$TMPD/StartupLoader.class" "$APP_BUNDLE/Contents/Resources/" && \
      echo "   ✅ StartupLoader (编译)"
    rm -rf "$TMPD"
fi
# 头像 + 图标
if [ -f "$SRC/Resources/avatar.jpg" ]; then
    cp "$SRC/Resources/avatar.jpg" "$APP_BUNDLE/Contents/Resources/" && echo "   ✅ avatar.jpg"
fi
# 收款码
if [ -f "$SRC/Resources/qrcode_author.png" ]; then
    cp "$SRC/Resources/qrcode_author.png" "$APP_BUNDLE/Contents/Resources/" && echo "   ✅ QR Code"
fi

# I18N 多语言文件
if [ -f "$SRC/Resources/I18N.json" ]; then
    cp "$SRC/Resources/I18N.json" "$APP_BUNDLE/Contents/Resources/" && echo "   ✅ I18N.json"
fi

if [ -f "$SRC/Resources/appicon.icns" ]; then
    cp "$SRC/Resources/appicon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns" && echo "   ✅ appicon.icns"
fi



# ── 6. 权限 ──
echo ""
echo ">>> [4] 权限修复..."
chmod -R a+rX "$APP_BUNDLE"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
find "$APP_BUNDLE/Contents/Java/Home/bin" -type f -exec chmod +x {} \; 2>/dev/null || true
find "$APP_BUNDLE/Contents/Resources" -name "*.dylib" -exec chmod +x {} \; 2>/dev/null || true
chmod +x "$APP_BUNDLE/Contents/Resources/llama/bin/llama-server" 2>/dev/null || true
echo "   ✅ 完成"

# ── 7. 签名 ──
echo ""
echo ">>> [5] 代码签名..."
DEV_ID=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | sed 's/.*"\(.*\)"/\1/' || true)
SIGN_ID=${DEV_ID:-"-"}
codesign -f -s "$SIGN_ID" --timestamp "$APP_BUNDLE" 2>/dev/null && \
  echo "   ✅ 签名完成" || echo "   ⚠️ ad-hoc 签名"

# ── 8. PKG ──
echo ""
echo ">>> [6] 创建 PKG..."
PKG_STAGING="$OUT/pkg_staging"; mkdir -p "$PKG_STAGING/Applications"
cp -R "$APP_BUNDLE" "$PKG_STAGING/Applications/"
cat > "$OUT/postinstall" << 'PI'
#!/bin/bash
APP="/Applications/JPetRemAI.app"
xattr -rd com.apple.quarantine "$APP" 2>/dev/null || true
chmod +x "$APP/Contents/MacOS/JPetRemAI" 2>/dev/null || true
find "$APP/Contents/Java" -type f -exec chmod +x {} \; 2>/dev/null || true
find "$APP/Contents/Resources" -name "*.dylib" -exec chmod +x {} \; 2>/dev/null || true
echo "✅ JPetRemAI v6 安装完成"
PI
chmod +x "$OUT/postinstall"
pkgbuild --root "$PKG_STAGING" --scripts "$OUT" --identifier "$BUNDLE_ID" \
  --version "$VERSION" --install-location "/" "$OUT/$APP_NAME.pkg" 2>&1
rm -rf "$PKG_STAGING" "$OUT/postinstall"
echo "   ✅ PKG: $(du -sh "$OUT/$APP_NAME.pkg" | cut -f1)"

# ── 9. DMG ──
echo ""
echo ">>> [7] 创建 DMG..."
DMG_STAGING="$OUT/dmg_staging"; mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -sf /Applications "$DMG_STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_STAGING" \
  -ov -format UDZO "$OUT/$APP_NAME.dmg" 2>&1
rm -rf "$DMG_STAGING"
echo "   ✅ DMG: $(du -sh "$OUT/$APP_NAME.dmg" | cut -f1)"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✅ 构建完成 (v$VERSION)                          ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "📦 输出:"
ls -lh "$OUT"/*.dmg "$OUT"/*.pkg 2>/dev/null || true
echo ""
echo "📱 App: $APP_BUNDLE ($(du -sh "$APP_BUNDLE" | cut -f1))"
