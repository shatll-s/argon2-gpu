cmake_minimum_required(VERSION 3.7)

project(argon2-gpu CXX)
set(BINARY_INSTALL_DIR /usr/local/bin)
set(LIBRARY_INSTALL_DIR /usr/local/lib)
set(INCLUDE_INSTALL_DIR /usr/local/include)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
enable_testing()

set(CUDA_FOUND FALSE)

if(NOT NO_CUDA)
    find_package(CUDA)
endif()

if(CUDA_FOUND)
    message("INFO: Using CUDA version ${CUDA_VERSION}")
    add_definitions(-DHAVE_CUDA=1)
    set(CUDA_NVCC_FLAGS
        ${CUDA_NVCC_FLAGS}
        -std=c++11
        -O3
        --ptxas-options=-v
        -lineinfo

        # SASS (готовые бинарные ядра):
        -gencode arch=compute_61,code=sm_61     # Pascal (GTX 10xx)
        -gencode arch=compute_70,code=sm_70     # Volta  (V100)
        -gencode arch=compute_75,code=sm_75     # Turing (RTX 20xx / Quadro RTX 5000 / CMP 50HX)
        -gencode arch=compute_86,code=sm_86     # Ampere (RTX 30xx / RTX A5000)
        -gencode arch=compute_89,code=sm_89     # Ada    (RTX 40xx / RTX 5000 Ada)
        # Blackwell (consumer/pro) = CC 12.0
        -gencode arch=compute_120,code=sm_120
        -gencode arch=compute_120,code=compute_120   # PTX для JIT вперёд

        # (опционально) Blackwell datacenter = CC 10.0
        # -gencode arch=compute_100,code=sm_100
        # PTX для JIT вперёд:
        -gencode arch=compute_75,code=compute_75

        -Xptxas=-dlcm=ca
        -Xptxas=-dscm=wt
        -maxrregcount=64
    )
    # зафиксировать флаги в кэше, чтобы подкаталоги не перетёрли:
    set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS}" CACHE STRING "nvcc flags" FORCE)
else()
    message("INFO: Building without CUDA support")
    add_definitions(-DHAVE_CUDA=0)
endif()



add_subdirectory(ext/argon2)

add_library(argon2-gpu-common SHARED
    lib/argon2-gpu-common/argon2params.cpp
    lib/argon2-gpu-common/blake2b.cpp
)
target_include_directories(argon2-gpu-common INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_include_directories(argon2-gpu-common PRIVATE
    include/argon2-gpu-common
    lib/argon2-gpu-common
)

if(CUDA_FOUND)
    cuda_add_library(argon2-cuda SHARED
        lib/argon2-cuda/device.cpp
        lib/argon2-cuda/globalcontext.cpp
        lib/argon2-cuda/programcontext.cpp
        lib/argon2-cuda/processingunit.cpp
        lib/argon2-cuda/kernels.cu
    )
else()
    add_library(argon2-cuda SHARED
        lib/argon2-cuda/nocuda.cpp
    )
endif()

target_include_directories(argon2-cuda PRIVATE
    include/argon2-cuda
    lib/argon2-cuda
)
target_include_directories(argon2-cuda INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_link_libraries(argon2-cuda argon2-gpu-common)

add_library(argon2-opencl SHARED
    lib/argon2-opencl/device.cpp
    lib/argon2-opencl/globalcontext.cpp
    lib/argon2-opencl/kernelloader.cpp
    lib/argon2-opencl/programcontext.cpp
    lib/argon2-opencl/processingunit.cpp
    lib/argon2-opencl/kernelrunner.cpp
)
target_include_directories(argon2-opencl INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)
target_include_directories(argon2-opencl PRIVATE
    include/argon2-opencl
    lib/argon2-opencl
)
target_link_libraries(argon2-opencl
    argon2-gpu-common -lOpenCL
)

add_executable(argon2-gpu-test
    src/argon2-gpu-test/main.cpp
    src/argon2-gpu-test/testcase.cpp
)
target_include_directories(argon2-gpu-test PRIVATE src/argon2-gpu-test)
target_link_libraries(argon2-gpu-test
    argon2-cuda argon2-opencl argon2 -lOpenCL
)

add_executable(argon2-gpu-bench
    src/argon2-gpu-bench/cpuexecutive.cpp
    src/argon2-gpu-bench/cudaexecutive.cpp
    src/argon2-gpu-bench/openclexecutive.cpp
    src/argon2-gpu-bench/benchmark.cpp
    src/argon2-gpu-bench/main.cpp
)
target_include_directories(argon2-gpu-bench PRIVATE src/argon2-gpu-bench)
target_link_libraries(argon2-gpu-bench
    argon2-cuda argon2-opencl argon2 -lOpenCL
)

add_test(argon2-gpu-test-opencl argon2-gpu-test -m opencl)
add_test(argon2-gpu-test-cuda argon2-gpu-test -m cuda)

install(
    TARGETS argon2-gpu-common argon2-opencl argon2-cuda
    DESTINATION ${LIBRARY_INSTALL_DIR}
)
install(FILES
    include/argon2-gpu-common/argon2-common.h
    include/argon2-gpu-common/argon2params.h
    include/argon2-opencl/cl.hpp
    include/argon2-opencl/opencl.h
    include/argon2-opencl/device.h
    include/argon2-opencl/globalcontext.h
    include/argon2-opencl/programcontext.h
    include/argon2-opencl/processingunit.h
    include/argon2-opencl/kernelrunner.h
    include/argon2-cuda/cudaexception.h
    include/argon2-cuda/kernels.h
    include/argon2-cuda/device.h
    include/argon2-cuda/globalcontext.h
    include/argon2-cuda/programcontext.h
    include/argon2-cuda/processingunit.h
    DESTINATION ${INCLUDE_INSTALL_DIR}
)
install(
    TARGETS argon2-gpu-bench argon2-gpu-test
    DESTINATION ${BINARY_INSTALL_DIR}
)
