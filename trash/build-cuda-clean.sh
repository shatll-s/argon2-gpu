#!/bin/bash

echo "🚀 Building CUDA-only argon2-gpu libraries (RTX 3070/4060 support)..."

mkdir -p cuda-clean-output

# Build only CUDA components
docker build -f Dockerfile.cuda-clean -t argon2-cuda-clean .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

# Extract libraries
docker run --rm -v $(pwd)/cuda-clean-output:/host argon2-cuda-clean

if [ $? -eq 0 ]; then
    echo "✅ CUDA libraries built successfully!"
    echo "📁 Built libraries:"
    ls -la cuda-clean-output/
    
    # Copy to main directory
    cp cuda-clean-output/*.so .
    
    echo "🎉 Ready! Libraries support RTX 3070 (sm_86) and RTX 4060 (sm_75)"
    echo "📋 Available libraries:"
    ls -la lib*.so
else
    echo "❌ Build failed!"
    exit 1
fi