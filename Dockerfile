FROM debian:bookworm

RUN apt update && apt install -y \
    qemu-system-x86 \
    qemu-utils \
    aria2 \
    curl \
    procps \
    net-tools \
    iproute2 \
    ca-certificates \
    && apt clean

# Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

WORKDIR /root

# ISO Debian (opcional)
RUN aria2c -x 16 -s 16 \
    -o debian.iso \
    https://debian.c3sl.ufpr.br/debian-cd/current/amd64/iso-cd/debian-13.5.0-amd64-netinst.iso || true

# DISCO VIRTUAL (500GB SIMULADO)
RUN qemu-img create -f qcow2 debian.img 500G

# start script
RUN echo '#!/bin/bash\n\
echo "============================"\n\
echo " QEMU STARTING "\n\
echo " RAM: 10GB (10240MB)"\n\
echo " DISCO: 500GB (qcow2)"\n\
echo " VNC :1 -> 5901"\n\
echo "============================"\n\
\n\
hostname -i\n\
\n\
# Tailscale userspace\n\
tailscaled --tun=userspace-networking &\n\
sleep 3\n\
\n\
if [ ! -z \"$TAILSCALE_AUTHKEY\" ]; then\n\
  tailscale up --authkey=$TAILSCALE_AUTHKEY --hostname=debian13-qemu\n\
  echo "Tailscale IP:"\n\
  tailscale ip -4\n\
fi\n\
\n\
exec qemu-system-x86_64 \\\n\
-m 10240 \\\n\
-smp 4 \\\n\
-hda debian.img \\\n\
-cdrom debian.iso \\\n\
-boot d \\\n\
-net nic -net user \\\n\
-vga std \\\n\
-display vnc=:1' > start.sh

RUN chmod +x start.sh

EXPOSE 5901

CMD ["/root/start.sh"]
