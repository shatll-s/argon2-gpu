#!/bin/bash
BUILD_DIR="docker-build"

echo "🧹 Cleaning previous build output..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# Build Docker image
echo "📦 Building Docker image..."
docker build -t webdollar-argon2-gpu -f Dockerfile .

if [ $? -eq 0 ]; then
    echo "🔧 Building libraries in container..."
    
    # Run container to build and extract libraries with current user permissions
    docker run --rm --user $(id -u):$(id -g) -v $(pwd)/$BUILD_DIR:/host webdollar-argon2-gpu
    
    echo "📁 Libraries available in: $BUILD_DIR"
    ls -la $BUILD_DIR
    
    if [ -f "$BUILD_DIR/libargon2-cuda.so" ]; then
        echo "🔍 Checking CUDA library symbols..."
        nm -D $BUILD_DIR/libargon2-cuda.so | grep -i global | head -5
        
        echo "✅ Build completed successfully!"
        echo ""
        echo "📊 Available executables in docker-build/:"
        ls -la $BUILD_DIR/argon2-gpu-bench $BUILD_DIR/argon2-gpu-test 2>/dev/null || echo "No executables found"
        echo ""
        echo "💡 To run executables, use:"
        echo "   LD_LIBRARY_PATH=$BUILD_DIR ./$BUILD_DIR/argon2-gpu-bench"
        echo "   LD_LIBRARY_PATH=$BUILD_DIR ./$BUILD_DIR/argon2-gpu-test"
    else
        echo "❌ Build failed - no CUDA library found"
        exit 1
    fi
else
    echo "❌ Docker build failed"
    exit 1
fi
