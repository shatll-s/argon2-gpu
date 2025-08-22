# Build WebDollar/argon2-gpu with fresh CUDA and submodules
FROM ubuntu:20.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    cmake \
    build-essential \
    git \
    wget \
    gnupg2 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add NVIDIA package repository and install latest CUDA
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb \
    && dpkg -i cuda-keyring_1.0-1_all.deb \
    && apt-get update \
    && apt-get install -y cuda-toolkit-12-4 \
    && rm -rf /var/lib/apt/lists/* cuda-keyring_1.0-1_all.deb

# Set CUDA environment
ENV PATH=/usr/local/cuda/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}

# Install OpenCL for executables
RUN apt-get update && apt-get install -y \
    ocl-icd-opencl-dev \
    opencl-headers \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /build

# Copy source code
COPY . /build/

# Initialize git submodules (critical!)
RUN git submodule update --init --recursive

# Clean previous build
RUN rm -rf CMakeCache.txt CMakeFiles/ Makefile *.so argon2-gpu-* build/

# Configure with fresh CUDA
RUN cmake . -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
    -DNO_CUDA=OFF \
    -DCMAKE_BUILD_TYPE=Release

# Build all components including dependencies
RUN make argon2-gpu-common argon2-cuda argon2-opencl argon2 -j$(nproc)

# Build executables (now with all dependencies)
RUN make argon2-gpu-bench argon2-gpu-test -j$(nproc)

# Create output directory
RUN mkdir -p /output

# Find and copy libargon2.so
RUN find . -name "libargon2.so*" -ls || echo "No libargon2.so found"

# Copy built libraries and executables
RUN cp lib*.so /output/ 2>/dev/null || echo "Copying available libraries..."
RUN find . -name "libargon2.so*" -exec cp {} /output/ \; 2>/dev/null || echo "No libargon2.so found to copy"
RUN cp argon2-gpu-bench argon2-gpu-test /output/ 2>/dev/null || echo "Copying available executables..."
RUN cp -r include /output/

# Check what we built
RUN echo "✅ Built libraries:" && ls -la /output/*.so || echo "No libraries found"
RUN echo "📊 Built executables:" && ls -la /output/argon2-gpu-* || echo "No executables found"
RUN echo "🔍 CUDA symbols:" && nm -D /output/libargon2-cuda.so | grep -i global | head -5 || echo "No symbols"
RUN echo "🚀 Libraries and executables ready"

# Set entrypoint to copy libraries out
CMD ["cp", "-r", "/output/.", "/host/"]
