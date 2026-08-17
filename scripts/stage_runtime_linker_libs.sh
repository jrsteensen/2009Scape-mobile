#!/usr/bin/env bash
set -euo pipefail

runtime_dir="${1:-app_pojavlauncher/src/main/assets/components/jre}"
jni_libs_dir="${2:-app_pojavlauncher/src/main/jniLibs}"

stage_library() {
    local archive_name="$1"
    local archive_member="$2"
    local android_abi="$3"
    local archive_path="$runtime_dir/$archive_name"
    local destination_dir="$jni_libs_dir/$android_abi"
    local temporary_file

    test -s "$archive_path"
    mkdir -p "$destination_dir"
    temporary_file="$(mktemp)"
    trap 'rm -f "$temporary_file"' RETURN

    tar -xJOf "$archive_path" "$archive_member" > "$temporary_file"
    test -s "$temporary_file"
    install -m 0644 "$temporary_file" "$destination_dir/libfreetype.so"
    rm -f "$temporary_file"
    trap - RETURN
}

# Java's libfontmanager.so declares libfreetype.so as a DT_NEEDED dependency.
# Android class-loader namespaces only resolve that dependency reliably when it
# is installed with the application's native libraries.
stage_library bin-arm.tar.xz ./lib/aarch32/libfreetype.so armeabi-v7a
stage_library bin-arm64.tar.xz ./lib/aarch64/libfreetype.so arm64-v8a
stage_library bin-x86.tar.xz ./lib/i386/libfreetype.so.6 x86
stage_library bin-x86_64.tar.xz ./lib/amd64/libfreetype.so.6 x86_64

for abi in armeabi-v7a arm64-v8a x86 x86_64; do
    test -s "$jni_libs_dir/$abi/libfreetype.so"
done
