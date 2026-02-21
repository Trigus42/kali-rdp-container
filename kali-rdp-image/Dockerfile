FROM kalilinux/kali-rolling

ENV LANG en_US.UTF-8
ARG DEBIAN_FRONTEND=noninteractive

# Basic Kali Linux setup
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        kali-defaults \
        kali-linux-headless

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ## Essentials for getting XRDP and SSH going
        ## https://github.com/heywoodlh/dockerfiles/blob/master/rdp-kali-linux/Dockerfile
        dbus-x11 \
        locales \
        sudo \
        x11-xserver-utils \
        xfce4 \
        xfce4-goodies \
        fonts-dejavu \
        xorgxrdp \
        xrdp \
        iproute2 \
        dnsutils \
        openssh-server \
        supervisor \
        # Desktop environment
        kali-desktop-xfce \
        kali-themes \
        kali-wallpapers-2025 \
        # Additional useful tools
        rlwrap \
        iputils-ping \
        nano \
    && apt-get clean

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        sliver \
        ffuf \
        burpsuite \
        bloodhound \
        crackmapexec \
        evil-winrm \
        hashcat \
        seclists

# User setup
RUN useradd -m -s /bin/zsh -G sudo kali \
    && echo 'kali:kali' | chpasswd \
    && echo 'kali ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && cp /etc/skel/. /home/kali/ -a \
    && chown -R kali:kali /home/kali/
RUN cp /etc/skel/. /root/ -a

# Docker CLI setup
COPY --from=docker:dind /usr/local/bin/docker* /usr/local/bin/

# uv tools
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
RUN uv tool install --no-cache \
    git+https://github.com/Trigus42/jwt_tool.git

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

EXPOSE 22/tcp
EXPOSE 3389/tcp

ENTRYPOINT ["/usr/bin/supervisord", "--configuration", "/etc/supervisor/conf.d/supervisord.conf"]
