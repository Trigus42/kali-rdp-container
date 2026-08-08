FROM kali-rdp-base

# bwrap passthrough shim: glycin sandboxes SVG loading via bwrap with a
# seccomp filter that blocks syscalls inside a container, causing GTK to
# SIGABRT. The shim execs the loader directly without sandboxing.
# dpkg-divert keeps this working across bubblewrap package upgrades.
COPY rootfs/ /
RUN \
    # Give the software H.264 encoder more threads for lower latency at high resolution.
    sed -i 's/^threads = 1/threads = 2/' /etc/xrdp/gfx.toml && \
    dpkg-divert --add --rename --divert /usr/bin/bwrap.real /usr/bin/bwrap && \
    install -m 0755 /usr/local/bin/bwrap-shim /usr/bin/bwrap

EXPOSE 22/tcp
EXPOSE 3389/tcp

ENTRYPOINT ["/usr/bin/supervisord", "--configuration", "/etc/supervisor/conf.d/supervisord.conf"]
