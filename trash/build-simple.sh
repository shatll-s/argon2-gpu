#!/bin/bash

echo "🔧 Building argon2-gpu locally without CUDA restrictions..."

# Clean previous build
rm -rf CMakeCache.txt CMakeFiles/ Makefile argon2-gpu-*

# Configure without NO_CUDA restriction  
cmake . -DNO_CUDA=OFF -DCMAKE_BUILD_TYPE=Release

if [ $? -ne 0 ]; then
    echo "❌ CMake configuration failed, trying with CUDA disabled..."
    cmake . -DNO_CUDA=ON -DCMAKE_BUILD_TYPE=Release
fi

# Build
make -j$(nproc)

# Check what we got
echo "📋 Built libraries:"
ls -la lib*.so 2>/dev/null || echo "No .so files found"

# Check symbols
echo "🔍 Checking CUDA library symbols:"
if [ -f libargon2-cuda.so ]; then
    nm -D libargon2-cuda.so | head -10
    objdump -T libargon2-cuda.so | grep -i global | head -5
else
    echo "❌ libargon2-cuda.so not found"
fi

echo "✅ Local build complete!"