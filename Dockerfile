FROM debian:13

RUN apt-get update && apt-get install -y \
    aria2 \
    curl \
    wget \
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

RUN cat > /start.sh << 'EOF'
#!/bin/bash

echo "================================="
echo "TAILSCALE USERSPACE"
echo "================================="

tailscaled --tun=userspace-networking --state=/tmp/tailscaled.state &
sleep 5

echo ""
echo "Para conectar o Tailscale execute:"
echo "tailscale up --auth-key=tskey-auth-kiEZRbZcV411CNTRL-49TNCWqmeZGXTzvAqhbBaGnmB39AsJm6"
echo ""

echo "================================="
echo "QEMU INICIADO"
echo "VM: Debian 13"
echo "RAM: 8 GB"
echo "CPU: 4 vCPUs"
echo "VNC PORTA: 5901"
echo "================================="

exec qemu-system-x86_64 \
  -m 8192 \
  -smp 4 \
  -drive file=/vm/debian.qcow2,format=qcow2 \
  -vnc :1
EOF

RUN chmod +x /start.sh

EXPOSE 5901

CMD ["/start.sh"]
