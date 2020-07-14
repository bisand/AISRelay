#!/bin/bash

if [ "$EUID" == "0" ]; then
    echo -en "\nRoot user detected. Typically install as a normal user. No need for sudo.\r\n\r\n"

    read -p "Are you really sure you want to install as root ? (y/N) ? " yn
    case $yn in
    [Yy]*) ;;

    *)
        exit
        ;;
    esac
fi

remove_whitespace() {
    local var="$1"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}

echo "Starting AIS installation..."

listen_port=11010
broadcast_port=2947
publish_endpoints=""
tuner_gain=49.60
ppm_error=197
do_install="true"

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -l | --listen-port)
        listen_port="$2"
        ;;
    -b | --broadcast-port)
        broadcast_port="$2"
        ;;
    -e | --publish-endpoints)
        publish_endpoints="$publish_endpoints $2"
        ;;
    -g | --tuner-gain)
        tuner_gain="$2"
        ;;
    -p | --ppm-error)
        ppm_error="$2"
        ;;
    -c | --config-only)
        do_install="false"
        ;;
    esac
    shift
done

listen_port=$(remove_whitespace "$listen_port")
broadcast_port=$(remove_whitespace "$broadcast_port")
publish_endpoints=$(remove_whitespace "$publish_endpoints")
tuner_gain=$(remove_whitespace "$tuner_gain")
ppm_error=$(remove_whitespace "$ppm_error")

echo "Listen Port: ${listen_port}"
echo "Broadcast Port: ${broadcast_port}"
echo "Publish Endpoints: ${publish_endpoints}"
echo "Tuner gain: ${tuner_gain}"
echo "PPM error: ${ppm_error}"

# Switch to tmp directory
rm -Rf /tmp/aisrelay
cp -R . /tmp/aisrelay
cd /tmp/aisrelay

if [[ "${do_install}" == "true" ]]; then
    # Install prerequisites.
    echo "Installing prerequisites..."
    sudo apt install -y git cmake build-essential libusb-1.0-0-dev jq &>>/tmp/aisrelay.log

    # Clone and install RTL-SDR
    echo "Building and installing RTL-SRD. This could take several minutes..."
    git clone git://git.osmocom.org/rtl-sdr.git &>>/tmp/aisrelay.log
    cd rtl-sdr/
    mkdir build
    cd build
    cmake ../ -DINSTALL_UDEV_RULES=ON &>>/tmp/aisrelay.log
    make &>>/tmp/aisrelay.log
    sudo make install &>>/tmp/aisrelay.log
    sudo ldconfig &>>/tmp/aisrelay.log
    cd ../..
    echo "Done."

    echo "Building and installing RTL-AIS. This could take several minutes..."
    # Adding include and lib path to prevent build errors on rtl-ais
    sudo sed -i.bak 's/^\(prefix=\).*/\1\/usr/' /usr/local/lib/pkgconfig/librtlsdr.pc
    sudo sed -i.bak 's/^\(libdir=\).*/\1${prefix}\/lib/' /usr/local/lib/pkgconfig/librtlsdr.pc
    sudo sed -i.bak 's/^\(includedir=\).*/\1${prefix}\/include/' /usr/local/lib/pkgconfig/librtlsdr.pc

    # Clone and install RTL-AIS
    git clone https://github.com/dgiardini/rtl-ais &>>/tmp/aisrelay.log
    cd rtl-ais
    make &>>/tmp/aisrelay.log
    sudo make install &>>/tmp/aisrelay.log
    cd ..
    echo "Done."
fi

echo "Installing Node-Red and dependencies..."
curl -sL https://raw.githubusercontent.com/node-red/linux-installers/master/deb/update-nodejs-and-nodered >update-nodejs-and-nodered.sh
chmod +x update-nodejs-and-nodered.sh
./update-nodejs-and-nodered.sh

envsubst < ais_relay.json > ais_relay_replaced.json

flow_id=$(curl -sL http://localhost:1880/flows | jq -r '.[] | select(select(.type=="tab").label=="AIS Relay").id')
if [ -z "$flow_id" ]; then
    echo "\$flow_id is empty. Adding AIS Relay flow."
    curl --header "Content-Type: application/json" \
    --request POST \
    --data @ais_relay_replaced.json \
    http://localhost:1880/flow
else
    echo "\$flow_id is NOT empty: ${flow_id}. Assuming flow exists. Nothing changed."
fi

echo "Creating and starting services..."
# Create rtl_ais service
sudo sh -c "cat >/etc/systemd/system/rtl_ais.service <<EOF
[Unit]
Description=rtl_ais, A simple AIS tuner and generic dual-frequency FM demodulator
After=network.target
StartLimitIntervalSec=0

[Service]
WorkingDirectory=/tmp
ExecStart=/usr/local/bin/rtl_ais -p${ppm_error} -g${tuner_gain}
Restart=always
# Restart service after 5 seconds if the dotnet service crashes:
RestartSec=5
KillSignal=SIGINT
SyslogIdentifier=rtl_ais
User=www-data

[Install]
WantedBy=multi-user.target
EOF"

# Create AIS Relay service. Deprecated for now, but could resurface...
sudo sh -c "cat >/etc/systemd/system/aisrelay.service <<EOF
[Unit]
Description=AIS Relay for broadcasting AIS messages to local network and multiple external UDP and TCP endpoints like MarineTraffic.
After=network.target
StartLimitIntervalSec=0

[Service]
WorkingDirectory=/tmp
ExecStart=/usr/local/bin/aisrelay --listen ${listen_port} --broadcast ${broadcast_port} --publish-endpoints ${publish_endpoints}
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
EOF"

# Stop an remove old aisrelay
sudo systemctl stop aisrelay &>>/tmp/aisrelay.log
sudo systemctl disable aisrelay &>>/tmp/aisrelay.log

# Enable and start services.
sudo systemctl enable rtl_ais &>>/tmp/aisrelay.log
sudo systemctl restart rtl_ais &>>/tmp/aisrelay.log
echo "Done."

# Cleaning up
echo "Cleaning up..."
rm -Rf /tmp/aisrelay &>>/tmp/aisrelay.log
echo "Done."
echo "Installation complete!"
echo "See log file for more info (/tmp/aisrelay.log)"
