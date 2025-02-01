#!/bin/bash

KERNEL_DIR=./common
OUT_DIR=../../out
DEFCONFIG="gki_defconfig"
LTO=thin  # LTO 设定为 thin

export PATH=/home/lee/ace3pro/origin-work/opace3pro/clang-aosp/bin:$PATH
export CLANG_TRIPLE=aarch64-linux-gnu-
export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64

TOOL_ARGS=("ARCH=${ARCH}" "SUBARCH=${SUBARCH}" "HEADER_ARCH=${HEADER_ARCH}")
CC=clang CXX=clang++ && TOOL_ARGS+=("CC=${CC}" "CXX=${CXX}")
LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
READELF=llvm-readelf OBJSIZE=llvm-size STRIP=llvm-strip && TOOL_ARGS+=("LD=${LD}" "AR=${AR}" "NM=${NM}" "OBJCOPY=${OBJCOPY}" "OBJDUMP=${OBJDUMP}" "STRIP=${STRIP}")
LLVM=1 LLVM_IAS=1 && TOOL_ARGS+=("LLVM=${LLVM}" "LLVM_IAS=${LLVM_IAS}")

cd ${KERNEL_DIR}
THREAD=24

# 配置内核
make -j"$THREAD" "${TOOL_ARGS[@]}" O=${OUT_DIR} ${DEFCONFIG}

# 确认启用 ThinLTO 配置
scripts/config --file ${OUT_DIR}/.config \
    -e LTO_CLANG \
    -d LTO_NONE \
    -e LTO_CLANG_THIN \
    -d LTO_CLANG_FULL \
    -e THINLTO

# 应用新的配置
make -j"$THREAD" O=${OUT_DIR} "${TOOL_ARGS[@]}" olddefconfig

# 编译内核，启用 LTO=thin
THREAD=$(($(nproc --all) - 1))
make -j"$THREAD" O=${OUT_DIR} NOKLEAF_LOCALVERSION=1 LTO=${LTO} "${TOOL_ARGS[@]}"

