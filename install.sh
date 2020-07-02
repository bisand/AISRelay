#!/bin/bash

echo "Starting AIS installation..."

# Switch to tmp directory
rm -Rf /tmp/aisrelay
cp -R . /tmp/aisrelay
cd /tmp/aisrelay

# Install prerequisites.
echo "Installing prerequisites..."
apt install -y git cmake build-essential libusb-1.0-0-dev libboost-system-dev libboost-program-options-dev &>> /tmp/aisrelay.log

# Clone and install RTL-SDR
echo "Building and installing RTL-SRD. This could take several minutes..."
git clone git://git.osmocom.org/rtl-sdr.git &>> /tmp/aisrelay.log
cd rtl-sdr/
mkdir build
cd build
cmake ../ -DINSTALL_UDEV_RULES=ON &>> /tmp/aisrelay.log
make &>> /tmp/aisrelay.log
sudo make install &>> /tmp/aisrelay.log
sudo ldconfig &>> /tmp/aisrelay.log
cd ../..
echo "Done."

echo "Building and installing RTL-AIS. This could take several minutes..."
# Adding include and lib path to prevent build errors on rtl-ais
sed -i.bak 's/^\(prefix=\).*/\1\/usr/' /usr/local/lib/pkgconfig/librtlsdr.pc
sed -i.bak 's/^\(libdir=\).*/\1${prefix}\/lib/' /usr/local/lib/pkgconfig/librtlsdr.pc
sed -i.bak 's/^\(includedir=\).*/\1${prefix}\/include/' /usr/local/lib/pkgconfig/librtlsdr.pc

# Clone and install RTL-AIS
git clone https://github.com/dgiardini/rtl-ais &>> /tmp/aisrelay.log
cd rtl-ais
make &>> /tmp/aisrelay.log
make install &>> /tmp/aisrelay.log
cd ..
echo "Done."

echo "Building and installing AISRelay. This may take up to 30 minutes on slow systems..."
cd src
make &>> /tmp/aisrelay.log
make install &>> /tmp/aisrelay.log
cd ..
echo "Done."

echo "Creating and starting services..."
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
Description=AIS Relay for broadcasting AIS messages to local network and multiple external UDP and TCP endpoints like MarineTraffic.
After=network.target
StartLimitIntervalSec=0

[Service]
WorkingDirectory=/tmp
ExecStart=/usr/local/bin/aisrelay --listen 10110 --broadcast 2948 --publish-endpoints udp://5.9.207.224:8317
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
systemctl enable rtl_ais &>> /tmp/aisrelay.log
systemctl enable aisrelay &>> /tmp/aisrelay.log
systemctl start rtl_ais &>> /tmp/aisrelay.log
systemctl start aisrelay &>> /tmp/aisrelay.log
echo "Done."

# Cleaning up
echo "Cleaning up..."
rm -Rf /tmp/aisrelay &>> /tmp/aisrelay.log
echo "Done."
echo "Installation complete!"
echo "See log file for more info (/tmp/aisrelay.log)"
