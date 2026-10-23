#!/bin/zsh
set -eu
cd "${0:A:h:h}"
swift build -c release
APP="${1:-dist/Usage Glass.app}"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/UsageGlass "$APP/Contents/MacOS/UsageGlass"
cp Sources/UsageGlass/Resources/usageglass_backend.py "$APP/Contents/Resources/usageglass_backend.py"
if [[ -f Assets/AppIcon.png ]]; then
    ICONSET=".build/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for size in 16 32 128 256 512; do
        sips -z "$size" "$size" Assets/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
        double=$((size * 2))
        sips -z "$double" "$double" Assets/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
fi
for bundle in .build/release/*.bundle; do
    [[ -d "$bundle" ]] && cp -R "$bundle" "$APP/Contents/Resources/"
done
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>UsageGlass</string>
<key>CFBundleIdentifier</key><string>local.usageglass.app</string>
<key>CFBundleName</key><string>Usage Glass</string>
<key>CFBundleDisplayName</key><string>Usage Glass</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>26.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
# Remove Finder metadata only from the generated application bundle.
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
echo "$APP"
