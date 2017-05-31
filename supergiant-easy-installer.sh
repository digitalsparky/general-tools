#!/bin/bash
set -e

sendHelp() {
    echo "Supergiant Easy Installer by Matthew Spurrier (github.com/digitalsparky)"
    echo
    echo "Usage: $0 [-p path-to-install] -f FQDN -e EMAIL"
    echo
    echo "FQDN: the fully qualified name for your supergiant manager (eg: manage.example.com)"
    echo "EMAIL: your email address, for registration and usage with letsencrypt"
    echo "path-to-install: defaults to /opt/supergiant"
    exit 1
}

while getopts ":p:f:e:" opt; do
  case $opt in
    p)
      SGPATH="$OPTARG"
      ;;
    f)
      FQDN="$OPTARG"
      ;;
    e)
      EMAIL="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done

if [ "$SGPATH" == "" ]; then
    SGPATH="/opt/supergiant"
fi

if [ "$FQDN" == "" ]; then
    sendHelp
fi

if [ "$EMAIL" == "" ]; then
    sendHelp
fi

echo "Installation Path: $SGPATH"
echo "FQDN: $FQDN"
echo "EMAIL: $EMAIL"

echo
echo "Please ensure you have $FQDN pointing to this servers IP address"
echo
echo "You'll also need to add a TXT record for letsencrypt verification as part of this installation process"
echo

read -p "Are you sure you want to proceed? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

apt -q update
apt -yq upgrade
apt -yq install supervisor jq

LATEST_BINARY=$(curl -Ls https://api.github.com/repos/supergiant/supergiant/releases/latest | jq -r '.assets[].browser_download_url' | grep supergiant-server-linux-amd64)
if [ $? -gt 0 ]; then
	echo "Oops! Failed to get latest binary URL from GitHub"
	exit 1
fi

curl -o /usr/bin/certbot-auto https://dl.eff.org/certbot-auto
chmod a+x /usr/bin/certbot-auto

rm -rf $SGPATH > /dev/null 2>&1

mkdir -p $SGPATH/log
mkdir -p $SGPATH/bin
mkdir -p $SGPATH/db
mkdir -p $SGPATH/etc

cat <<EOF > $SGPATH/etc/config.json
{
  "sqlite_file": "$SGPATH/db/main.db",
  "ui_enabled": true,
  "capacity_service_enabled": true,
  "publish_host": "$FQDN",
  "http_port": "80",
  "https_port": "443",
  "ssl_cert_file": "/etc/letsencrypt/live/$FQDN/fullchain.pem",
  "ssl_key_file": "/etc/letsencrypt/live/$FQDN/privkey.pem",
  "log_file": "$SGPATH/log/main.log",
  "log_level": "info",
  "node_sizes": {
    "aws": [
      {"name": "t2.nano", "ram_gib": 0.5, "cpu_cores": 1},
      {"name": "t2.micro", "ram_gib": 1, "cpu_cores": 1},
      {"name": "t1.micro", "ram_gib": 0.613, "cpu_cores": 1},
      {"name": "t2.small", "ram_gib": 2, "cpu_cores": 1},
      {"name": "m1.small", "ram_gib": 1.7, "cpu_cores": 1},
      {"name": "t2.medium", "ram_gib": 4, "cpu_cores": 2},
      {"name": "m3.medium", "ram_gib": 3.75, "cpu_cores": 1},
      {"name": "m1.medium", "ram_gib": 3.75, "cpu_cores": 1},
      {"name": "t2.large", "ram_gib": 8, "cpu_cores": 2},
      {"name": "c3.large", "ram_gib": 3.75, "cpu_cores": 2},
      {"name": "c4.large", "ram_gib": 3.75, "cpu_cores": 2},
      {"name": "m4.large", "ram_gib": 8, "cpu_cores": 2},
      {"name": "c1.medium", "ram_gib": 1.7, "cpu_cores": 2},
      {"name": "m3.large", "ram_gib": 7.5, "cpu_cores": 2},
      {"name": "r3.large", "ram_gib": 15.25, "cpu_cores": 2},
      {"name": "m1.large", "ram_gib": 7.5, "cpu_cores": 2},
      {"name": "c4.xlarge", "ram_gib": 7.5, "cpu_cores": 4},
      {"name": "c3.xlarge", "ram_gib": 7.5, "cpu_cores": 4},
      {"name": "m4.xlarge", "ram_gib": 16, "cpu_cores": 4},
      {"name": "m2.xlarge", "ram_gib": 17.1, "cpu_cores": 2},
      {"name": "m3.xlarge", "ram_gib": 15, "cpu_cores": 4},
      {"name": "r3.xlarge", "ram_gib": 30.5, "cpu_cores": 4},
      {"name": "m1.xlarge", "ram_gib": 15, "cpu_cores": 4},
      {"name": "c4.2xlarge", "ram_gib": 15, "cpu_cores": 8},
      {"name": "c3.2xlarge", "ram_gib": 15, "cpu_cores": 8},
      {"name": "m4.2xlarge", "ram_gib": 32, "cpu_cores": 8},
      {"name": "m2.2xlarge", "ram_gib": 34.2, "cpu_cores": 4},
      {"name": "c1.xlarge", "ram_gib": 7, "cpu_cores": 8},
      {"name": "m3.2xlarge", "ram_gib": 30, "cpu_cores": 8},
      {"name": "g2.2xlarge", "ram_gib": 15, "cpu_cores": 8},
      {"name": "r3.2xlarge", "ram_gib": 61, "cpu_cores": 8},
      {"name": "d2.xlarge", "ram_gib": 30.5, "cpu_cores": 4},
      {"name": "c4.4xlarge", "ram_gib": 30, "cpu_cores": 16},
      {"name": "c3.4xlarge", "ram_gib": 30, "cpu_cores": 16},
      {"name": "i2.xlarge", "ram_gib": 30.5, "cpu_cores": 4},
      {"name": "m4.4xlarge", "ram_gib": 64, "cpu_cores": 16},
      {"name": "m2.4xlarge", "ram_gib": 68.4, "cpu_cores": 8},
      {"name": "r3.4xlarge", "ram_gib": 122, "cpu_cores": 16},
      {"name": "d2.2xlarge", "ram_gib": 61, "cpu_cores": 8},
      {"name": "c4.8xlarge", "ram_gib": 60, "cpu_cores": 36},
      {"name": "c3.8xlarge", "ram_gib": 60, "cpu_cores": 32},
      {"name": "i2.2xlarge", "ram_gib": 61, "cpu_cores": 8},
      {"name": "cc2.8xlarge", "ram_gib": 60.5, "cpu_cores": 32},
      {"name": "cg1.4xlarge", "ram_gib": 22.5, "cpu_cores": 16},
      {"name": "m4.10xlarge", "ram_gib": 160, "cpu_cores": 40},
      {"name": "g2.8xlarge", "ram_gib": 60, "cpu_cores": 32},
      {"name": "r3.8xlarge", "ram_gib": 244, "cpu_cores": 32},
      {"name": "d2.4xlarge", "ram_gib": 122, "cpu_cores": 16},
      {"name": "hi1.4xlarge", "ram_gib": 60.5, "cpu_cores": 16},
      {"name": "i2.4xlarge", "ram_gib": 122, "cpu_cores": 16},
      {"name": "cr1.8xlarge", "ram_gib": 244, "cpu_cores": 32},
      {"name": "hs1.8xlarge", "ram_gib": 117, "cpu_cores": 16},
      {"name": "d2.8xlarge", "ram_gib": 244, "cpu_cores": 36},
      {"name": "i2.8xlarge", "ram_gib": 244, "cpu_cores": 32}
    ],
    "digitalocean": [
      {"name": "512mb", "ram_gib": 0.5, "cpu_cores": 1},
      {"name": "1gb", "ram_gib": 1, "cpu_cores": 1},
      {"name": "2gb", "ram_gib": 2, "cpu_cores": 2},
      {"name": "4gb", "ram_gib": 4, "cpu_cores": 2},
      {"name": "8gb", "ram_gib": 8, "cpu_cores": 4},
      {"name": "16gb", "ram_gib": 16, "cpu_cores": 8},
      {"name": "32gb", "ram_gib": 32, "cpu_cores": 12},
      {"name": "48gb", "ram_gib": 48, "cpu_cores": 16},
      {"name": "64gb", "ram_gib": 64, "cpu_cores": 20}
    ],
    "gce": [
      {"name": "n1-standard-1", "ram_gib": 3.75, "cpu_cores": 1},
      {"name": "n1-standard-2", "ram_gib": 7.5, "cpu_cores": 2},
      {"name": "n1-standard-4", "ram_gib": 15, "cpu_cores": 4},
      {"name": "n1-standard-8", "ram_gib": 30, "cpu_cores": 8}
    ]
  }
}
EOF

cat <<EOF > $SGPATH/etc/logrotate.conf
$SGPATH/logs/main.log
{
    rotate 4
    weekly
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
}
EOF

cat <<EOF > $SGPATH/etc/supervisor.conf
[program:supergiant]
command=$SGPATH/bin/supergiant --config-file $SGPATH/etc/config.json
autostart=true
autorestart=true
umask=002
priority=3
startretries=3
stopwaitsecs=10
redirect_stderr=true
EOF

rm -f /etc/supervisor/conf.d/supergiant.conf > /dev/null 2>&1
rm -f /etc/logrotate.d/supergiant > /dev/null 2>&1
ln -s $SGPATH/etc/supervisor.conf /etc/supervisor/conf.d/supergiant.conf
ln -s $SGPATH/etc/logrotate.conf /etc/logrotate.d/supergiant

curl -sL -o $SGPATH/bin/supergiant $LATEST_BINARY
chmod a+x $SGPATH/bin/supergiant

echo "Initiating letsencrypt to get SSL certificate for $FQDN"
/usr/bin/certbot-auto certonly --manual -m $EMAIL --rsa-key-size 4096 --preferred-challenges dns -d $FQDN

cat <<EOF > /etc/cron.d/certbot-auto
0,12 * * * * /usr/bin/certbot-auto renew
EOF

echo "Supergiant config installed, if this is a new install, create a new database by running:"
echo "$SGPATH/bin/supergiant --config-file $SGPATH/etc/config.json"
echo
echo "This will give you a new username/password"
echo
echo "Otherwise, copy your database in place, then run:"
echo "supervisorctl start supergiant"
