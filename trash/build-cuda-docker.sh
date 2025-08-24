#!/bin/bash

# Build argon2-gpu with CUDA in Docker
echo "🚀 Building argon2-gpu with CUDA support in Ubuntu 20.04 Docker..."

# Create output directory
mkdir -p cuda-build-output

# Build Docker image
echo "📦 Building Docker image..."
docker build -f Dockerfile.cuda-build -t argon2-gpu-cuda-builder .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

# Run container to build and extract libraries
echo "🔧 Building libraries in container..."
docker run --rm --gpus all \
    -v $(pwd)/cuda-build-output:/host \
    argon2-gpu-cuda-builder

if [ $? -eq 0 ]; then
    echo "✅ CUDA libraries built successfully!"
    echo "📁 Libraries available in: cuda-build-output/"
    ls -la cuda-build-output/
    
    # Check if CUDA library has symbols
    echo "🔍 Checking CUDA library symbols..."
    nm -D cuda-build-output/libargon2-cuda.so | grep -i global || echo "No GlobalContext symbols found"
    
    # Copy to main directory if successful
    echo "📋 Copying libraries to main directory..."
    cp cuda-build-output/*.so .
    
    echo "🎉 Ready to use CUDA-enabled argon2-gpu!"
else
    echo "❌ Build failed!"
    exit 1
fi