#!/bin/sh

echo "Starting AIS installation..."

# Switch to tmp directory
rm -Rf /tmp/aisrelay
cp -R . /tmp/aisrelay
cd /tmp/aisrelay

# Install .net core
wget https://dotnet.microsoft.com/download/dotnet-core/scripts/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --install-dir /usr/share/dotnet --channel LTS --version latest --no-path

# Install AIS Relay
/usr/share/dotnet/dotnet publish --output /usr/share/aisrelay

# Install prerequisites.
apt install -y git cmake build-essential libusb-1.0-0-dev

# Clone and install RTL-SDR
git clone git://git.osmocom.org/rtl-sdr.git
cd rtl-sdr/
mkdir build
cd build
cmake ../ -DINSTALL_UDEV_RULES=ON
make
sudo make install
sudo ldconfig
cd ../..

# Adding include and lib path to prevent build errors on rtl-ais
sed -i.bak 's/^\(prefix=\).*/\1\/usr/' /usr/local/lib/pkgconfig/librtlsdr.pc
sed -i.bak 's/^\(libdir=\).*/\1${prefix}\/lib/' /usr/local/lib/pkgconfig/librtlsdr.pc
sed -i.bak 's/^\(includedir=\).*/\1${prefix}\/include/' /usr/local/lib/pkgconfig/librtlsdr.pc

# Clone and install RTL-AIS
git clone https://github.com/dgiardini/rtl-ais 
cd rtl-ais
make
make install
cd ..

# Create rtl_ais service
cat > /etc/systemd/system/rtl_ais.service << EOF
[Unit]
Description=rtl_ais, A simple AIS tuner and generic dual-frequency FM demodulator
After=network.target
StartLimitIntervalSec=0

[Service]
WorkingDirectory=/tmp
ExecStart=/usr/local/bin/rtl_ais -p197 -g49.60
Restart=always
# Restart service after 5 seconds if the dotnet service crashes:
RestartSec=5
KillSignal=SIGINT
SyslogIdentifier=rtl_ais
User=www-data

[Install]
WantedBy=multi-user.target
EOF

# Create AIS Relay service
cat > /etc/systemd/system/aisrelay.service << EOF
[Unit]
Description=AIS Relay for broadcasting AIS messages to local network and MarineTraffic.com
After=network.target
StartLimitIntervalSec=0

[Service]
WorkingDirectory=/usr/share/aisrelay
ExecStart=/usr/share/aisrelay/aisrelay --listen 10110 --broadcast 2947 --mt-host 5.9.207.224 --mt-port 11089
Restart=always
# Restart service after 10 seconds if the dotnet service crashes:
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=aisrelay
User=www-data
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services.
systemctl enable rtl_ais
systemctl enable aisrelay
systemctl start rtl_ais
systemctl start aisrelay

# Cleaning up
rm -Rf /tmp/aisrelay
