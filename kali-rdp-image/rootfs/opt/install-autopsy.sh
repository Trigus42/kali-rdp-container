#!/usr/bin/env bash
# Install Autopsy into a persistent volume.
# Run once manually: docker exec kali-rdp /opt/install-autopsy.sh
set -e

AUTOPSY_VERSION="${AUTOPSY_VERSION:-4.23.1}"
TSK_VERSION="4.15.0"
AUTOPSY_DATA_DIR="${AUTOPSY_DATA_DIR:-/mnt/autopsy}"
AUTOPSY_INSTALL="${AUTOPSY_DATA_DIR}/autopsy-${AUTOPSY_VERSION}"
SETUP_DONE="${AUTOPSY_INSTALL}/.setup_done"

if [[ -f "${SETUP_DONE}" ]]; then
    echo "Autopsy ${AUTOPSY_VERSION} already installed at ${AUTOPSY_INSTALL}."
else
    echo "Installing build dependencies..."
    apt-get update -qq
    apt-get install -y --no-install-recommends \
        testdisk \
        default-jdk \
        unzip \
        build-essential \
        libafflib-dev \
        libewf-dev \
        libvhdi-dev \
        libvmdk-dev \
        ant
    apt-get clean && rm -rf /var/lib/apt/lists/*

    TMPDIR=$(mktemp -d)
    trap "rm -rf ${TMPDIR}" EXIT

    # Build Sleuth Kit Java bindings (jar must match Autopsy's expected TSK version)
    echo "Building Sleuth Kit ${TSK_VERSION} Java bindings..."
    curl -fsSL "https://github.com/sleuthkit/sleuthkit/releases/download/sleuthkit-${TSK_VERSION}/sleuthkit-${TSK_VERSION}.tar.gz" \
        -o "${TMPDIR}/sleuthkit.tar.gz"
    tar -xzf "${TMPDIR}/sleuthkit.tar.gz" -C "${TMPDIR}"
    cd "${TMPDIR}/sleuthkit-${TSK_VERSION}"
    ./configure --disable-static
    make -j$(nproc)
    make install
    cd bindings/java && ant -q dist
    cp dist/sleuthkit-${TSK_VERSION}.jar /usr/share/java/

    # Download and set up Autopsy
    echo "Downloading Autopsy ${AUTOPSY_VERSION}..."
    curl -fsSL "https://github.com/sleuthkit/autopsy/releases/download/autopsy-${AUTOPSY_VERSION}/autopsy-${AUTOPSY_VERSION}.zip" \
        -o "${TMPDIR}/autopsy.zip"
    mkdir -p "${AUTOPSY_DATA_DIR}"
    unzip -q "${TMPDIR}/autopsy.zip" -d "${TMPDIR}/autopsy-extracted"
    mv "${TMPDIR}/autopsy-extracted/autopsy-${AUTOPSY_VERSION}" "${AUTOPSY_INSTALL}"

    echo "Running Autopsy setup..."
    cd "${AUTOPSY_INSTALL}"
    JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) bash unix_setup.sh

    touch "${SETUP_DONE}"
    echo "Done. Autopsy ${AUTOPSY_VERSION} installed at ${AUTOPSY_INSTALL}."
fi

# Write launcher (idempotent)
JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
cat > /usr/local/bin/autopsy <<EOF
#!/usr/bin/env bash
export JAVA_HOME=${JAVA_HOME}
exec "${AUTOPSY_INSTALL}/bin/autopsy" "\$@"
EOF
chmod +x /usr/local/bin/autopsy
chown -R kali:kali "${AUTOPSY_DATA_DIR}"
echo "Launcher written to /usr/local/bin/autopsy"
