#!/bin/bash

echo "🚀 Building WebDollar/argon2-gpu with CUDA 12.4 and submodules..."

# Build Docker image
echo "📦 Building Docker image..."
docker build -t webdollar-argon2-gpu -f Dockerfile.webdollar-build .

if [ $? -eq 0 ]; then
    echo "🔧 Building libraries in container..."
    
    # Create output directory
    mkdir -p webdollar-build-output
    
    # Run container to build and extract libraries
    docker run --rm -v $(pwd)/webdollar-build-output:/host webdollar-argon2-gpu
    
    echo "✅ WebDollar/argon2-gpu built successfully!"
    echo "📁 Libraries available in: webdollar-build-output/"
    ls -la webdollar-build-output/
    
    if [ -f "webdollar-build-output/libargon2-cuda.so" ]; then
        echo "🔍 Checking CUDA library symbols..."
        nm -D webdollar-build-output/libargon2-cuda.so | grep -i global | head -5
        
        echo "📋 Copying libraries to main directory..."
        cp webdollar-build-output/lib*.so .
        
        echo "🎉 Ready to use WebDollar CUDA-enabled argon2-gpu!"
    else
        echo "❌ Build failed - no CUDA library found"
        exit 1
    fi
else
    echo "❌ Docker build failed"
    exit 1
fi