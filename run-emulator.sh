#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
DEPLOY_DIR="${BUILD_DIR}/tmp/deploy/images/emulator"
PREPARE_BUILD="${SCRIPT_DIR}/prepare-build.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[emulator]${NC} $*"; }
warn()  { echo -e "${YELLOW}[emulator]${NC} $*"; }
error() { echo -e "${RED}[emulator]${NC} $*" >&2; }

usage() {
    echo "Usage: $0 [--force-build|--launch-only|--help]"
    echo ""
    echo "  (no args)      Build image if not found, then launch emulator"
    echo "  --force-build  Force rebuild the image, then launch"
    echo "  --launch-only  Launch only (skip build, image must exist)"
    echo "  --help         Show this help"
    echo ""
    echo "SSH access:   ssh -p 2222 root@127.0.0.1"
    exit 0
}

find_image() {
    if [ ! -d "${DEPLOY_DIR}" ]; then
        return 1
    fi
    ROOTFS=$(ls -t "${DEPLOY_DIR}"/asteroid-image-emulator.rootfs-*.ext4 2>/dev/null | head -1)
    KERNEL=$(ls -t "${DEPLOY_DIR}"/bzImage 2>/dev/null | head -1)
    if [ -z "${ROOTFS:-}" ] || [ -z "${KERNEL:-}" ]; then
        return 1
    fi
    return 0
}

build_image() {
    info "Building AsteroidOS emulator image..."
    info "This may take a while on first build."

    if [ ! -f "${PREPARE_BUILD}" ]; then
        error "prepare-build.sh not found at ${PREPARE_BUILD}"
        exit 1
    fi

    # prepare-build.sh fetches sources and sets up build/conf if needed
    cd "${SCRIPT_DIR}"
    bash "${PREPARE_BUILD}" emulator

    bash -c "
        source '${SCRIPT_DIR}/src/oe-core/oe-init-build-env' '${BUILD_DIR}' > /dev/null
        bitbake asteroid-image
    "

    if ! find_image; then
        error "Build completed but image artifacts not found in ${DEPLOY_DIR}"
        exit 1
    fi

    info "Build complete!"
    info "  Root FS: ${ROOTFS}"
    info "  Kernel:  ${KERNEL}"
}

find_qemu() {
    # The emulator image is 32-bit (core2-32), so we need qemu-system-i386.
    if command -v qemu-system-i386 &>/dev/null; then
        QEMU_BIN="qemu-system-i386"
    elif [ -x "${BUILD_DIR}/tmp/work/x86_64-linux/qemu-helper-native/1.0/recipe-sysroot-native/usr/bin/qemu-system-i386" ]; then
        QEMU_BIN="${BUILD_DIR}/tmp/work/x86_64-linux/qemu-helper-native/1.0/recipe-sysroot-native/usr/bin/qemu-system-i386"
    else
        error "qemu-system-i386 not found."
        error "Install QEMU or build it with: bitbake qemu-helper-native"
        exit 1
    fi

    DISPLAY_BACKENDS=$("${QEMU_BIN}" -display help 2>&1 | grep -oP '^\w+' || true)
    DISPLAY_OPT=""
    GPU_DEVICE=""

    if echo "${DISPLAY_BACKENDS}" | grep -q '^gtk$'; then
        DISPLAY_OPT="-display gtk,gl=on,show-cursor=on"
        GPU_DEVICE="-vga none -device virtio-vga-gl"
        info "Using GTK display with virgl 3D acceleration"
    elif echo "${DISPLAY_BACKENDS}" | grep -q '^sdl$'; then
        DISPLAY_OPT="-display sdl,gl=on"
        GPU_DEVICE="-vga none -device virtio-vga-gl"
        info "Using SDL display with virgl 3D acceleration"
    else
        warn "No GTK/SDL display backend found, trying fallback..."
        if "${QEMU_BIN}" -device help 2>&1 | grep -q 'virtio-vga-gl'; then
            GPU_DEVICE="-vga none -device virtio-vga-gl"
        elif "${QEMU_BIN}" -device help 2>&1 | grep -q 'virtio-vga'; then
            GPU_DEVICE="-vga none -device virtio-vga"
        else
            GPU_DEVICE="-vga none -device virtio-gpu-pci"
        fi
        for backend in gtk sdl spice-app; do
            if echo "${DISPLAY_BACKENDS}" | grep -q "^${backend}$"; then
                DISPLAY_OPT="-display ${backend}"
                break
            fi
        done
        if [ -z "${DISPLAY_OPT}" ]; then
            error "No graphical display backend available in ${QEMU_BIN}"
            error "Available backends: ${DISPLAY_BACKENDS}"
            error "Install QEMU with GTK or SDL support."
            exit 1
        fi
    fi

    KVM_OPT=""
    CPU_OPT="-cpu IvyBridge"
    if [ -w /dev/kvm ]; then
        KVM_OPT="-enable-kvm"
        CPU_OPT="-cpu host"
        info "KVM hardware acceleration enabled"
    else
        warn "KVM not available (no /dev/kvm or no permission). Emulation will be slower."
        warn "  To enable: sudo usermod -aG kvm \$USER && newgrp kvm"
    fi
}

launch_emulator() {
    info "Launching AsteroidOS emulator..."
    info "  Root FS: $(basename "${ROOTFS}")"
    info "  Kernel:  $(basename "${KERNEL}")"
    info ""
    info "  SSH:     ssh -p 2222 root@127.0.0.1"
    info ""
    info "Close the QEMU window or press Ctrl+C to stop."
    echo ""

    # On Wayland compositors (Hyprland), the QEMU window size determines the
    # guest display resolution. We set window rules to float and resize QEMU to
    # 800x827 (800x800 render area + GTK menu bar) so AsteroidOS gets a square
    # viewport matching real watch displays.
    if [ -f "${SCRIPT_DIR}/resize_qemu.py" ]; then
        python3 "${SCRIPT_DIR}/resize_qemu.py" || true
    fi

    # GPU flags mirror emulator.conf QB_GRAPHICS / QB_OPT_APPEND so this script
    # works the same way as Yocto's runqemu but without requiring the OE
    # environment to be sourced.
    exec "${QEMU_BIN}" \
        -device virtio-net-pci,netdev=net0,mac=52:54:00:12:35:02 \
        -netdev user,id=net0,hostfwd=tcp:127.0.0.1:2222-:22 \
        -object rng-random,filename=/dev/urandom,id=rng0 -device virtio-rng-pci,rng=rng0 \
        -drive file="${ROOTFS}",if=virtio,format=raw,snapshot=on \
        -usb -device usb-tablet -usb -device usb-kbd \
        ${CPU_OPT} -machine q35,i8042=off ${KVM_OPT} -smp 4 -m 512 \
        ${GPU_DEVICE} \
        ${DISPLAY_OPT} \
        -kernel "${KERNEL}" \
        -append "root=/dev/vda rw ip=dhcp"
}

FORCE_BUILD=false
LAUNCH_ONLY=false

case "${1:-}" in
    --force-build)  FORCE_BUILD=true ;;
    --launch-only)  LAUNCH_ONLY=true ;;
    --help|-h) usage ;;
    "") ;;
    *) error "Unknown option: $1"; usage ;;
esac

if [ "${LAUNCH_ONLY}" = true ]; then
    if ! find_image; then
        error "No emulator image found. Run without --launch-only to build first."
        exit 1
    fi
elif [ "${FORCE_BUILD}" = true ] || ! find_image; then
    if ! find_image; then
        info "No existing image found, building..."
    fi
    build_image
else
    info "Using existing image (use --force-build to force rebuild)"
fi

find_qemu
launch_emulator
