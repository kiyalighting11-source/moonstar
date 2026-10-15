#!/bin/bash

set -e

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
# ⚠️ مهم: من غير --base-href
# =====================================================
echo ""
echo "🏗️ Step 5: Building for web (release)..."

flutter build web --release

# =====================================================
# 6) التحقق من النتيجة
# =====================================================
echo ""
echo "✅ Step 6: Verifying build output..."

if [ -d "build/web" ]; then
  echo "✅ Build output found at build/web"
  ls -la build/web/ | head -20

  if [ -f "build/web/main.dart.js" ]; then
    echo "✅ main.dart.js exists"
  else
    echo "❌ ERROR: main.dart.js not found!"
    exit 1
  fi

  # ⭐ نضيف _redirects عشان Vercel SPA routing
  echo "🔧 Adding SPA redirects..."
  echo "/*    /index.html   200" > build/web/_redirects

  echo "✅ Post-build fixes applied"
else
  echo "❌ ERROR: build/web not found!"
  exit 1
fi

echo ""
echo "═══════════════════════════════════════"
echo "🎉 Build completed successfully!"
echo "═══════════════════════════════════════"