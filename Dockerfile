# ------------------------------------------------------------
# Sunshine headless streaming container
# Base: official Ubuntu 24.04 Sunshine image
# ------------------------------------------------------------
ARG SUNSHINE_VERSION=v2025.924.154138
ARG SUNSHINE_OS=ubuntu-24.04
FROM lizardbyte/sunshine:${SUNSHINE_VERSION}-${SUNSHINE_OS} AS sunshine-baee

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Définition de la langue (Français Canada) et du Fuseau horaire (Est / Québec)
ENV LANG=fr_CA.UTF-8
ENV LC_ALL=fr_CA.UTF-8
ENV TZ=America/Toronto

# ------------------------------------------------------------
# Install NVIDIA driver (headless, user space components only)
# ------------------------------------------------------------
USER root
RUN apt-get update && \
    # 1. Installation de tzdata (fuseau horaire) sans prompt interactif
    apt-get install -y tzdata && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    # 2. Installation du paquet locales et génération du fr_CA
    apt-get install -y locales && \
    sed -i -e 's/# fr_CA.UTF-8 UTF-8/fr_CA.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    # 3. Suite de vos installations (Nvidia)
    apt-get install -y wget build-essential kmod && \
    wget https://us.download.nvidia.com/XFree86/Linux-x86_64/580.82.09/NVIDIA-Linux-x86_64-580.82.09.run && \
    chmod +x NVIDIA-Linux-x86_64-580.82.09.run && \
    ./NVIDIA-Linux-x86_64-580.82.09.run --no-kernel-module --silent && \
    rm NVIDIA-Linux-x86_64-580.82.09.run

# ------------------------------------------------------------
# Install display + audio stack
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xinit \
        xserver-xorg-core \
        x11-utils \
        x11-xserver-utils \
        mesa-utils \
        tailscale \
        pipewire \
        pipewire-audio-client-libraries \
        pipewire-pulse pipewire-alsa alsa-utils \
        wireplumber \
        dbus-x11 \
        supervisor \
        pulseaudio-utils \
        alsa-utils \
        fonts-dejavu-core \
        mc \
        nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# XFCE layer
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xfce4 \
        xfce4-terminal \
        mousepad \
        tango-icon-theme \
        dbus-x11 \
        xdg-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Gaming Layer (Steam, Lutris & Wine/Proton dependencies)
# ------------------------------------------------------------
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    # Installation de Steam et Lutris avec les dépendances graphiques 32-bits
    apt-get install -y --no-install-recommends \
        steam \
        lutris \
        # Pilotes graphiques 32-bits (essentiels pour les jeux Windows/Steam sous Linux)
        libgl1-mesa-dri:i386 \
        libgl1-mesa-glx:i386 \
        libvulkan1 \
        libvulkan1:i386 \
        # Dépendances communes pour Wine / Proton (Lutris en dépend grandement)
        wine \
        winetricks \
        zenity && \

# ------------------------------------------------------------
# Create runtime directories
# ------------------------------------------------------------
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

# ------------------------------------------------------------
# Copy configuration files
# ------------------------------------------------------------
COPY root/ /

# ------------------------------------------------------------
# Default environment variables
# ------------------------------------------------------------
ENV DISPLAY=:0
ENV SUNSHINE_LOG=info
ENV SUNSHINE_CONFIG_DIR=/config

# ------------------------------------------------------------
# Expose Sunshine ports
# ------------------------------------------------------------
EXPOSE 47984-47990/tcp
EXPOSE 47998-48010/udp

# ------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------
ENTRYPOINT []
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
