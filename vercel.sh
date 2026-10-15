#!/bin/bash

# =====================================================
# Moonstar ERP - Vercel Build Script
# =====================================================

set -e  # وقف لو حصل أي error

echo "═══════════════════════════════════════"
echo "🚀 Starting Moonstar ERP build"
echo "═══════════════════════════════════════"

# =====================================================
# 1) تثبيت Flutter SDK
# =====================================================
echo ""
echo "📦 Step 1: Installing Flutter SDK..."

if [ -d "flutter" ]; then
  echo "✅ Flutter folder exists, pulling latest..."
  cd flutter
  git pull
  cd ..
else
  echo "⬇️ Cloning Flutter (stable branch)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# =====================================================
# 2) إضافة Flutter للـ PATH
# =====================================================
echo ""
echo "🔧 Step 2: Adding Flutter to PATH..."

export PATH="$PATH:$(pwd)/flutter/bin"

# ⭐ git safe.directory — عشان Vercel بيعمل chown والـ git بيفشل
git config --global --add safe.directory "$(pwd)/flutter" || true

# نتأكد إن Flutter شغال
which flutter
flutter --version

# =====================================================
# 3) تفعيل الويب
# =====================================================
echo ""
echo "🌐 Step 3: Enabling web support..."

flutter config --enable-web

# =====================================================
# 4) جلب الاعتماديات
# =====================================================
echo ""
echo "📚 Step 4: Getting dependencies..."

flutter pub get

# =====================================================
# 5) بناء التطبيق للويب
# ⭐ --base-href / مهم جداً عشان Vercel
# ⭐ --release للـ production
# =====================================================
echo ""
echo "🏗️ Step 5: Building for web (release)..."

flutter build web \
  --release \
  --base-href / \
  --dart-define=FLUTTER_WEB_USE_SKIA=false

# =====================================================
# 6) التحقق من النتيجة
# =====================================================
echo ""
echo "✅ Step 6: Verifying build output..."

if [ -d "build/web" ]; then
  echo "✅ Build output found at build/web"
  echo "📁 Files:"
  ls -la build/web/ | head -20

  # ⭐ نتأكد إن main.dart.js موجود
  if [ -f "build/web/main.dart.js" ]; then
    echo "✅ main.dart.js exists"
  else
    echo "❌ ERROR: main.dart.js not found!"
    exit 1
  fi

  # ⭐ نتأكد إن flutter_bootstrap.js موجود
  if [ -f "build/web/flutter_bootstrap.js" ]; then
    echo "✅ flutter_bootstrap.js exists"
  else
    echo "⚠️ WARNING: flutter_bootstrap.js not found (may be named differently in new Flutter versions)"
  fi

  # ⭐ نصلح الـ base href في index.html لو لسه فيه placeholder
  if grep -q 'FLUTTER_BASE_HREF' build/web/index.html; then
    echo "🔧 Fixing base href in index.html..."
    sed -i 's|\$FLUTTER_BASE_HREF|/|g' build/web/index.html
  fi

  # ⭐ نضيف ملف _redirects عشان Vercel (SPA routing)
  echo "🔧 Adding SPA redirects..."
  echo "/*    /index.html   200" > build/web/_redirects

  # ⭐ نضيف vercel.json جوه الـ build (كـ backup)
  cat > build/web/vercel.json <<'EOF'
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
EOF

  echo "✅ Post-build fixes applied"
else
  echo "❌ ERROR: build/web not found!"
  exit 1
fi

echo ""
echo "═══════════════════════════════════════"
echo "🎉 Build completed successfully!"
echo "═══════════════════════════════════════"