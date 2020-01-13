#!/usr/bin/env bash

set -e

SCRIPT_ROOT=$(cd "$(dirname "$0")"; pwd -P)
PATH_TO_SWIFT_TOOLCHAIN="$SCRIPT_ROOT/swift-flowkey.xctoolchain"
UNAME=`uname`

log() {
    echo "[swift-android-toolchain] $*"
}

if [[ $1 = "--clean" ]]; then
    log "Let's start from scratch ..."
    clean
fi

clean() {
    git -C $SCRIPT_ROOT clean -xdf
}

rm -rf $SCRIPT_ROOT/temp
mkdir -p $SCRIPT_ROOT/temp
cd $SCRIPT_ROOT/temp

downloadArtifacts() {
    log "Downloading Toolchain Artifacts..."

    mkdir -p $SCRIPT_ROOT/temp
    cd $SCRIPT_ROOT/temp

    BASEPATH="https://swift-toolchain-artifacts.flowkeycdn.com"
    VERSION="20200112.1"

    curl -JO ${BASEPATH}/${VERSION}/${UNAME}.zip
    unzip -qq $SCRIPT_ROOT/temp/${UNAME}.zip

    mv $SCRIPT_ROOT/temp/${UNAME}/swift-flowkey.xctoolchain $SCRIPT_ROOT
    mv $SCRIPT_ROOT/temp/${UNAME}/Android.sdk-* $SCRIPT_ROOT

    mv $SCRIPT_ROOT/temp/${UNAME}/libs/armeabi-v7a/*.so $SCRIPT_ROOT/libs/armeabi-v7a
    mv $SCRIPT_ROOT/temp/${UNAME}/libs/arm64-v8a/*.so $SCRIPT_ROOT/libs/arm64-v8a
    mv $SCRIPT_ROOT/temp/${UNAME}/libs/x86_64/*.so $SCRIPT_ROOT/libs/x86_64
}

setup() {
    # fix ndk paths of downloaded android sdks
    sed -i -e s~C:/Microsoft/AndroidNDK64/android-ndk-r16b~${ANDROID_NDK_PATH}~g $SCRIPT_ROOT/Android.sdk-*/usr/lib/swift/android/*/glibc.modulemap

    HOST_SWIFT_BIN_PATH="$PATH_TO_SWIFT_TOOLCHAIN/usr/bin"
    if [ ! -f "$HOST_SWIFT_BIN_PATH/swiftc" ]; then
        log "Couldn't find swift in ${HOST_SWIFT_BIN_PATH}"
        exit 1
    fi

    for arch in armeabi-v7a arm64-v8a x86_64
    do
        ANDROID_SDK="${SCRIPT_ROOT}/Android.sdk-$arch"
        TOOLCHAIN_BIN_DIR="${ANDROID_SDK}/usr/bin"
        mkdir -p "${TOOLCHAIN_BIN_DIR}"
        ln -fs "$HOST_SWIFT_BIN_PATH"/swift* "${TOOLCHAIN_BIN_DIR}"

        # Make a hardlink (not symlink!) to `swift` to make the compiler think it's in this install path
        # This allows it to find the Android swift stdlib in ${SCRIPT_ROOT}/usr/lib/swift/android
        ln -f "$HOST_SWIFT_BIN_PATH/swift" "${TOOLCHAIN_BIN_DIR}/swiftc"
    done

    rm -rf $SCRIPT_ROOT/temp/
    log "Setup finished"
}

if [[ ! -d $PATH_TO_SWIFT_TOOLCHAIN ]] || [[ ! -d $SCRIPT_ROOT/Android.sdk-armeabi-v7a ]] || [[ ! -f $SCRIPT_ROOT/libs/armeabi-v7a/libicuuc64.so ]]; then
    clean
    downloadArtifacts
fi

setup

rm -rf $SCRIPT_ROOT/temp
