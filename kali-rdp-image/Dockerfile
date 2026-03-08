FROM kalilinux/kali-rolling

ENV LANG en_US.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

# Basic Kali Linux setup
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        kali-defaults \
        kali-linux-headless

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
    && apt-get clean

# Docker setup
ARG DEBIAN_CODENAME=trixie
RUN apt-get update && apt-get install -y ca-certificates curl && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "Types: deb\n\
URIs: https://download.docker.com/linux/debian\n\
Suites: ${DEBIAN_CODENAME}\n\
Components: stable\n\
Signed-By: /etc/apt/keyrings/docker.asc" > /etc/apt/sources.list.d/docker.sources && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin fuse-overlayfs && \
    apt-get clean

# Additional tools
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        git-lfs \
        starship \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
    && apt-get clean

# Pentesting tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sliver \
        ffuf \
        burpsuite \
        bloodhound \
        crackmapexec \
        evil-winrm \
        hashcat \
        seclists \
    && apt-get clean

# uv tools
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
RUN uv tool install --no-cache \
    git+https://github.com/Trigus42/jwt_tool.git

# User setup
RUN useradd -m -s /bin/zsh -G sudo kali \
    && echo 'kali:kali' | chpasswd \
    && echo 'kali ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && chown -R kali:kali /home/kali/

# Shell setup
# Default from /etc/skell often borks the terminal so we use our own
COPY .zshrc /home/kali/.zshrc
COPY .zshrc /root/.zshrc
RUN \
    chsh -s /bin/zsh kali && \
    chsh -s /bin/zsh root && \
    chown -R kali:kali /home/kali/.zshrc

# SSH setup
RUN sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config
RUN echo 'AuthorizedKeysFile ~/.ssh/authorized_keys' >> /etc/ssh/sshd_config
RUN mkdir -p /run/sshd

# Services
COPY startup /startup
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Disable screen locking and power management
RUN rm -f /etc/xdg/autostart/xfce4-screensaver.desktop \
    && rm -f /etc/xdg/autostart/light-locker.desktop \
    && rm -f /etc/xdg/autostart/xfce4-power-manager.desktop

# Force Xvnc to be the default XRDP session to fix Kali scrolling bug
RUN sed -i '/^\[Xorg\]/i [Xvnc-Default]\nname=Xvnc-Default\nlib=libvnc.so\nusername=ask\npassword=ask\nip=127.0.0.1\nport=-1\n' /etc/xrdp/xrdp.ini

EXPOSE 22/tcp
EXPOSE 3389/tcp

ENTRYPOINT ["/usr/bin/supervisord", "--configuration", "/etc/supervisor/conf.d/supervisord.conf"]
