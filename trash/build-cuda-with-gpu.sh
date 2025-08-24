#!/bin/bash

# Two-stage build: first build image, then compile with GPU access

echo "🚀 Building argon2-gpu with real GPU access..."

# Step 1: Build Docker image (without running compilation)
echo "📦 Building Docker image..."
docker build -f Dockerfile.cuda-build -t argon2-gpu-cuda-builder .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

# Step 2: Run interactive container with GPU access to compile
echo "🔧 Starting container with GPU access for compilation..."
docker run --rm --gpus all \
    -v $(pwd):/source \
    -v $(pwd)/cuda-build-output:/output \
    -w /source \
    argon2-gpu-cuda-builder bash -c "
        echo '🧹 Cleaning previous build...'
        rm -rf CMakeCache.txt CMakeFiles/ Makefile *.so
        
        echo '⚙️ Configuring with CUDA...'
        cmake . -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
                -DNO_CUDA=OFF \
                -DCMAKE_BUILD_TYPE=Release
        
        echo '🔨 Building CUDA libraries...'
        make argon2-gpu-common argon2-cuda -j\$(nproc)
        
        echo '📋 Copying libraries to output...'
        cp libargon2-cuda.so libargon2-gpu-common.so /output/
        cp -r include /output/
        
        echo '✅ Build complete!'
        echo '🔍 Checking CUDA device detection...'
        nvidia-smi
    "

if [ $? -eq 0 ]; then
    echo "✅ CUDA libraries built with GPU access!"
    echo "📁 Libraries available in: cuda-build-output/"
    ls -la cuda-build-output/
    
    # Copy to main directory
    echo "📋 Copying libraries to main directory..."
    cp cuda-build-output/*.so .
    
    echo "🎉 Ready to use CUDA-enabled argon2-gpu!"
else
    echo "❌ Build failed!"
    exit 1
fi