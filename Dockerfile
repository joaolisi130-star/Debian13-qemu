FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    curl wget aria2 \
    qemu-system-x86 qemu-utils \
    iproute2 iputils-ping \
    bash sudo \
    ca-certificates \
    git build-essential cmake \
    libjson-c-dev libwebsockets-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/tsl0922/ttyd.git /ttyd && \
    cd /ttyd && mkdir build && cd build && \
    cmake .. && make && make install

RUN curl -fsSL https://tailscale.com/install.sh | sh

WORKDIR /app

RUN aria2c -x 16 -s 16 -o /app/debian.iso \
https://debian.c3sl.ufpr.br/debian-cd/current/amd64/iso-cd/debian-13.5.0-amd64-netinst.iso

RUN qemu-img create -f qcow2 /app/disk.qcow2 500G

EXPOSE 7681

CMD bash -c "tailscaled --tun=userspace-networking & sleep 2; \
if [ ! -z \"$TAILSCALE_AUTHKEY\" ]; then \
tailscale up --authkey=$TAILSCALE_AUTHKEY --hostname=railway-qemu --accept-dns=true; \
fi; \
qemu-system-x86_64 -m 4096 -smp 2 -cpu qemu64 -accel tcg \
-hda /app/disk.qcow2 -cdrom /app/debian.iso -boot d \
-net nic -net user -vnc :1 -display none & \
ttyd -p 7681 -W bash"
