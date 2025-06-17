#!/bin/sh

if [ $(id -u) -ne 1000 ]; then
    echo "Can only deploy as a normal user!"
    exit 1
fi

sudo apt update && sudo apt upgrade -y

# Prerequisites for PanoramaPlayer

cp -r PanoramaPlayer/ $HOME/
rm -rf $HOME/PanoramaPlayer/.git

sudo apt install libts0 -y # runtime dependency
sudo apt install libvulkan-dev libxkbcommon-dev cmake build-essential -y # buildtime dependency
sudo tar xvf files/usr-local-Qt6.8.3.tar.gz -C /usr/local/

export LD_LIBRARY_PATH=/usr/local/Qt6.8.3/lib
PANORAMA_ROOT=$HOME/PanoramaPlayer

# Build PanoramaPlayer

cd $PANORAMA_ROOT
cmake -B $PANORAMA_ROOT/build -DCMAKE_BUILD_TYPE=Release
cmake --build $PANORAMA_ROOT/build --parallel
cd -

# Copy the runtime files

cp files/eglfs.json $HOME/
cp files/panorama.service /etc/systemd/system/
cp files/reboot.service /etc/systemd/system/

# Copy shell scripts
sudo cp files/backlight /usr/local/bin/
sudo cp files/panoramaplay.sh /usr/local/bin/

# Enable PanoramaPlayer at boot
systemctl enable --user panorama.service

# Setup audio
sudo apt install pipewire pipewire-pulse pipewire-jack pipewire-alsa wireplumber -y
systemctl enable --user wireplumber.service

# Disable GUI
sudo systemctl disable lightdm

# Setup the serial port
sudo systemctl mask serial-getty@ttyAMA0.service
sudo usermod -aG dialout admin

# Raspi config
sudo cp files/config.txt /boot/firmware/config.txt

# Setup webserver

sudo apt install apache2 php php-mbstring -y
sudo $PANORAMA_ROOT/setup-web.sh
