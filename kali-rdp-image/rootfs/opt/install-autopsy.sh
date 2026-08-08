#!/usr/bin/env bash
# Install Autopsy into a persistent volume.
# Run once manually: docker exec kali-rdp /opt/install-autopsy.sh
#
# NOTE: Autopsy requires Java 21 to run (libsleuthkit-java from apt is compiled
# with Java 21). Install it before launching: mise use -g java@21
set -e

AUTOPSY_VERSION="${AUTOPSY_VERSION:-4.22.1}"
AUTOPSY_DATA_DIR="${AUTOPSY_DATA_DIR:-/mnt/autopsy}"
AUTOPSY_INSTALL="${AUTOPSY_DATA_DIR}/autopsy-${AUTOPSY_VERSION}"
SETUP_DONE="${AUTOPSY_INSTALL}/.setup_done"

if [[ -f "${SETUP_DONE}" ]]; then
    echo "Autopsy ${AUTOPSY_VERSION} already installed at ${AUTOPSY_INSTALL}."
else
    TMPDIR=$(mktemp -d)
    trap "rm -rf ${TMPDIR}" EXIT

    echo "Downloading Autopsy ${AUTOPSY_VERSION}..."
    curl -fsSL --progress-bar "https://github.com/sleuthkit/autopsy/releases/download/autopsy-${AUTOPSY_VERSION}/autopsy-${AUTOPSY_VERSION}_v2.zip" \
        -o "${TMPDIR}/autopsy.zip"

    mkdir -p "${AUTOPSY_DATA_DIR}"
    unzip -q "${TMPDIR}/autopsy.zip" -d "${TMPDIR}/autopsy-extracted"
    mv "${TMPDIR}/autopsy-extracted/autopsy-${AUTOPSY_VERSION}" "${AUTOPSY_INSTALL}"

    # Fix Windows line endings in config files
    find "${AUTOPSY_INSTALL}/etc" -type f | xargs dos2unix -q

    # Patch the sleuthkit jar to include the aarch64 native lib.
    # The upstream jar only ships x86 libs; aarch64 support was never merged
    # (sleuthkit PR #2889). Without this, LibraryUtils.loadSleuthkitJNI() always
    # fails on ARM64 and Autopsy shows "Problem with Sleuth Kit JNI".
    if [[ "$(uname -m)" == "aarch64" ]]; then
        JNI_SO=$(find /usr/lib -name "libtsk_jni.so" 2>/dev/null | head -1)
        if [[ -n "${JNI_SO}" ]]; then
            echo "Patching sleuthkit jar with aarch64 native lib..."
            PATCH_TMP=$(mktemp -d)
            mkdir -p "${PATCH_TMP}/NATIVELIBS/aarch64/linux"
            cp "${JNI_SO}" "${PATCH_TMP}/NATIVELIBS/aarch64/linux/libtsk_jni.so"
            (cd "${PATCH_TMP}" && zip -q "${AUTOPSY_INSTALL}/autopsy/modules/ext/sleuthkit-4.14.0.jar" \
                "NATIVELIBS/aarch64/linux/libtsk_jni.so")
            rm -rf "${PATCH_TMP}"
        fi
    fi

    echo "Running Autopsy setup..."
    cd "${AUTOPSY_INSTALL}"
    # unix_setup.sh only checks java exists, doesn't run it — system java is fine here
    JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) bash unix_setup.sh

    touch "${SETUP_DONE}"
    echo "Done. Autopsy ${AUTOPSY_VERSION} installed at ${AUTOPSY_INSTALL}."
fi

# Write launcher (idempotent)
cat > /usr/local/bin/autopsy <<'EOF'
#!/usr/bin/env bash
find_java21() {
    for base in /mnt/mise-data /home/kali/.local/share/mise "${MISE_DATA_DIR}"; do
        [[ -z "$base" ]] && continue
        bin=$(find "${base}/installs/java/21"* -name java -path '*/bin/java' 2>/dev/null | head -1)
        [[ -n "$bin" ]] && echo "$bin" && return
    done
}
JAVA_BIN=$(find_java21)
if [[ -z "${JAVA_BIN}" ]]; then
    echo 'autopsy: Java 21 not found. Install it with: mise use -g java@21' >&2
    exit 1
fi
JAVA_HOME=$(dirname $(dirname $(readlink -f "${JAVA_BIN}")))
JNI_LIB=$(dirname $(find /usr/lib -name 'libtsk_jni.so' 2>/dev/null | head -1))
export LD_LIBRARY_PATH="${JNI_LIB}:/usr/lib/$(uname -m)-linux-gnu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
# Remove stale lock files left by previous runs as a different user
rm -f /tmp/libtsk_jni_*.so
exec "AUTOPSY_INSTALL/bin/autopsy" --jdkhome "${JAVA_HOME}" "$@"
EOF
sed -i "s|AUTOPSY_INSTALL|${AUTOPSY_INSTALL}|g" /usr/local/bin/autopsy
chmod +x /usr/local/bin/autopsy
chown -R kali:kali "${AUTOPSY_DATA_DIR}"
echo "Launcher written to /usr/local/bin/autopsy"
echo "Run 'mise use -g java@21' to install Java 21 before launching Autopsy."
