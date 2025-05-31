#!/bin/bash
set -e

echo "🔧 Updating and installing dependencies..."
sudo apt update
sudo apt install -y curl alsa-utils libasound2 ffmpeg

sudo systemctl stop go2rtc 2>/dev/null || true
sudo systemctl disable go2rtc 2>/dev/null || true

echo "🎙️ Setting up go2rtc..."
sudo mkdir -p /opt/go2rtc
cd /opt/go2rtc

sudo curl -L -o go2rtc https://github.com/AlexxIT/go2rtc/releases/latest/download/go2rtc_linux_armv6
sudo chmod +x go2rtc

echo "📝 Creating ffmpeg USB mic wrapper script..."
sudo tee /opt/go2rtc/ffmpeg-usb-mic.sh > /dev/null << 'EOF'
#!/bin/bash

DEVICE=$(arecord -l | awk '/card [0-9]+:.*USB/ {gsub(":", "", $2); print "hw:" $2 ",0"; exit}')
if [ -z "$DEVICE" ]; then
    echo "WARNING: No USB mic found, falling back to hw:0,0" >&2
    DEVICE="hw:0,0"
fi

exec ffmpeg -hide_banner -f alsa -channels 1 -sample_rate 48000 -i "$DEVICE" \
  -c:a libopus -rtsp_transport tcp -f rtsp "$1"
EOF

sudo chmod +x /opt/go2rtc/ffmpeg-usb-mic.sh

echo "✅ FFmpeg wrapper installed at /opt/go2rtc/ffmpeg-usb-mic.sh"

echo "📄 Writing go2rtc config..."
cat <<EOF | sudo tee /opt/go2rtc/go2rtc.yaml > /dev/null
streams:
  mic:
    - exec:/opt/go2rtc/ffmpeg-usb-mic.sh {output}
EOF

echo "🧩 Creating systemd service..."
USER="${SUDO_USER:-$(whoami)}"
cat <<EOF | sudo tee /etc/systemd/system/go2rtc.service > /dev/null
[Unit]
Description=go2rtc RTSP server
After=network.target sound.target

[Service]
ExecStart=/opt/go2rtc/go2rtc -config /opt/go2rtc/go2rtc.yaml
Restart=always
User=$USER
WorkingDirectory=/opt/go2rtc

[Install]
WantedBy=multi-user.target
EOF

echo "📦 Disabling swap..."
sudo systemctl stop dphys-swapfile || true
sudo systemctl disable dphys-swapfile || true
sudo apt purge -y dphys-swapfile || true

echo "🧹 Mounting logs and temp dirs in RAM..."

# Only append if not already present
grep -q 'tmpfs /tmp' /etc/fstab || cat <<EOF | sudo tee -a /etc/fstab > /dev/null
tmpfs /tmp tmpfs defaults,noatime,nosuid,size=64m 0 0
tmpfs /var/tmp tmpfs defaults,noatime,nosuid,size=16m 0 0
tmpfs /var/log tmpfs defaults,noatime,nosuid,mode=0755,size=32m 0 0
EOF

echo "⚙️ Setting noatime on root filesystem..."
sudo sed -i 's|\( / .*defaults\)\(.*\)|\1,noatime\2|' /etc/fstab

echo "🔄 Reloading systemd and mounting tmpfs..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now go2rtc.service
sudo mount -a

HOSTNAME=$(hostname)
echo "✅ Setup complete!"
echo "Stream available at rtsp://${HOSTNAME}.local:8554/mic"
