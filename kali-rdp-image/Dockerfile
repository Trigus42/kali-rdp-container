FROM kalilinux/kali-rolling

ENV LANG=en_US.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

# Basic Kali Linux setup
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        kali-defaults \
        kali-linux-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Desktop environment and remote access setup
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ## Essentials for XRDP and SSH
        ## https://github.com/heywoodlh/dockerfiles/blob/master/rdp-kali-linux/Dockerfile
        dbus-x11 \
        locales \
        sudo \
        x11-xserver-utils \
        xfce4 \
        xfce4-goodies \
        fonts-dejavu \
        xorgxrdp \
        tigervnc-standalone-server \
        xrdp \
        iproute2 \
        dnsutils \
        openssh-server \
        supervisor \
        # Desktop environment
        kali-desktop-xfce \
        kali-themes \
        kali-wallpapers-2025 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Tools and services setup
ARG DEBIAN_CODENAME=trixie
RUN \
    apt-get update && \
    # Docker repository setup
    apt-get install -y ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "Types: deb\n\
URIs: https://download.docker.com/linux/debian\n\
Suites: ${DEBIAN_CODENAME}\n\
Components: stable\n\
Signed-By: /etc/apt/keyrings/docker.asc" > /etc/apt/sources.list.d/docker.sources && \
    # VS Code repository setup
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get update && \
    # Install
    apt-get install -y --no-install-recommends \
        # Docker
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
        fuse-overlayfs \
        # gocryptfs for encrypted host volume
        gocryptfs \
        fuse3 \
        # Syncthing
        syncthing \
        # Additonal tools
        git \
        git-lfs \
        starship \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        nano \
        # Pentesting tools
        sliver \
        ffuf \
        burpsuite \
        bloodhound \
        crackmapexec \
        evil-winrm \
        hashcat && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# uv tools
COPY --from=ghcr.io/astral-sh/uv:0.10.10 /uv /uvx /bin/
RUN uv tool install --no-cache \
    git+https://github.com/Trigus42/jwt_tool.git

COPY .zshrc /home/kali/.zshrc
COPY .zshrc /root/.zshrc
RUN \
    # User setup
    useradd -m -s /bin/zsh -G sudo kali && \
    echo 'kali:kali' | chpasswd && \
    echo 'kali ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    chown -R kali:kali /home/kali/ && \
    chsh -s /bin/zsh kali && \
    chsh -s /bin/zsh root && \
    chown -R kali:kali /home/kali/.zshrc && \
    chown -R root:root /root/.zshrc && \
    # SSH setup
    sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config \
    && echo 'AuthorizedKeysFile ~/.ssh/authorized_keys' >> /etc/ssh/sshd_config \
    && mkdir -p /run/sshd

# Services
COPY startup /startup
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Fixes
RUN \
    # Disable screen locking and power management
    rm -f /etc/xdg/autostart/xfce4-screensaver.desktop && \
    rm -f /etc/xdg/autostart/light-locker.desktop && \
    rm -f /etc/xdg/autostart/xfce4-power-manager.desktop && \
    # Force Xvnc to be the default XRDP session to fix Kali scrolling bug
    sed -i '/^\[Xorg\]/i [Xvnc-Default]\nname=Xvnc-Default\nlib=libvnc.so\nusername=ask\npassword=ask\nip=127.0.0.1\nport=-1\n' /etc/xrdp/xrdp.ini && \
    # WORKAROUND: Allow bwrap to use SUID to fix XFCE/XRDP session crashes.
    # WHY: Containers block the unprivileged user namespaces that bwrap needs 
    # to sandbox SVG icon rendering. SUID allows it to bypass this restriction.
    chmod u+s /usr/bin/bwrap

EXPOSE 22/tcp
EXPOSE 3389/tcp

ENTRYPOINT ["/usr/bin/supervisord", "--configuration", "/etc/supervisor/conf.d/supervisord.conf"]
