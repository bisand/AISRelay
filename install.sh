#!/bin/sh
echo "Starting AIS installation..."

# Install .net core
wget https://dotnet.microsoft.com/download/dotnet-core/scripts/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --install-dir /usr/share/dotnet --channel LTS --version latest --no-path

# The path in dotnet installer is not always working as intended, so we set it ourselves.
export PATH="/usr/share/dotnet":"$PATH"

# Install AIS Relay
dotnet publish --output /usr/share/aisrelay

apt install -y git build-essential autotools-dev autoconf libtool libusb-dev

git clone https://github.com/libusb/libusb.git
cd libusb
make
make install
cd ..

# Clone and install RTL-SDR
git clone git://git.osmocom.org/rtl-sdr.git
cd rtl-sdr/
autoreconf -i
./configure
make
sudo make install-udev-rules
sudo ldconfig
cd ..

# Clone and install RTL-AIS
git clone https://github.com/dgiardini/rtl-ais 
cd rtl-ais
make
make install
