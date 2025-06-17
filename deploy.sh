#!/bin/sh

if [ $(id -u) -ne 1000 ]; then
    echo "Can only deploy as a normal user!"
    exit 1
fi

# Prerequisites for PanoramaPlayer

cp -r PanoramaPlayer/ $HOME/
rm -rf $HOME/PanoramaPlayer/.git

sudo apt install libts0 # runtime dependency
sudo apt install libvulkan-dev libxkbcommon-dev cmake build-essential # buildtime dependency
sudo tar xvf files/usr-local-Qt6.8.3.tar.gz -C /usr/local/

export LD_LIBRARY_PATH=/usr/local/Qt6.8.3/lib
PANORAMA_ROOT=$HOME/PanoramaPlayer

# Build PanoramaPlayer

cmake -B $PANORAMA_ROOT/build -DCMAKE_BUILD_TYPE=Release
cmake --build $PANORAMA_ROOT/build --parallel

# Copy the runtime files

cp files/eglfs.json $HOME/
cp files/panorama.service $HOME/.config/systemd/user/

# Copy shell scripts
sudo cp files/backlight /usr/local/bin/
sudo files/panorama.sh /usr/local/bin/

# Enable PanoramaPlayer at boot
systemctl enable --now --user panorama.service

# Setup audio
sudo apt install pipewire pipewire-pulse pipewire-jack pipewire-alsa wireplumber -y
systemctl enable --now --user wireplumber.service

# Disable GUI
sudo systemctl disable --now lightdm
sudo systemctl mask lightdm

# Setup the serial port
sudo systemctl mask serial-getty@ttyAMA0.service
sudo usermod -aG dialout admin

# Raspi config
sudo cp files/config.txt /boot/firmware/config.txt
