# syntax=docker/dockerfile:1
# The overlay: sbx-host on PATH. The launcher runs the client the sandbox's
# daemon serves, so the client always matches the daemon it talks to.
FROM scratch
COPY --chmod=0755 files/usr/local/bin/sbx-host /usr/local/bin/sbx-host
