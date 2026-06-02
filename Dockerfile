FROM debian:13

RUN apt-get update && apt-get install -y \
    aria2 \
    curl \
    ca-certificates \
    qemu-system-x86 \
    qemu-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://tailscale.com/install.sh | sh

WORKDIR /vm

RUN aria2c \
    -x16 \
    -s16 \
    -k1M \
    -o debian.qcow2 \
    https://cloud.debian.org/images/cloud/trixie/latest/debian-13-generic-amd64.qcow2

RUN qemu-img resize debian.qcow2 500G

EXPOSE 5901

CMD bash -c '\
echo "=================================" && \
echo "TAILSCALE USERSPACE" && \
echo "Execute depois:" && \
echo "tailscale up --auth-key=tskey-auth-kiEZRbZcV411CNTRL-49TNCWqmeZGXTzvAqhbBaGnmB39AsJm6" && \
echo "=================================" && \
tailscaled --tun=userspace-networking --state=/tmp/tailscaled.state & \
sleep 10 && \
echo "=================================" && \
echo "QEMU INICIADO" && \
echo "VNC: IP_TAILSCALE:5901" && \
echo "RAM: 8GB" && \
echo "CPU: 4" && \
echo "=================================" && \
qemu-system-x86_64 \
-accel tcg,thread=multi \
-m 8192 \
-smp 4 \
-drive file=/vm/debian.qcow2,format=qcow2 \
-vnc 0.0.0.0:1'
