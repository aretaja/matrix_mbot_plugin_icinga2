# matrix_mbot_icinga2
Mbot Icinga2 plugin

## Getting Started
Installation on Debian

### Prerequisites
* From https://github.com/aretaja/matrix_mbot
Mbot

* From debian repo
```
apt install libmonitoring-icinga2-client-rest-perl
```
## Installing
### Install plugin
```
git clone https://github.com/aretaja/matrix_mbot_plugin_icinga2
cd matrix_mbot_plugin_icinga2
perl Makefile.PL
make
sudo make install
make clean
```

### Add Icinga2 related config to your mbot.conf
```
# Icinga2 plugin
ic2_host     = localhost                  # host where Icinga2 API is listening (optional - defaults to localhost)
ic2_port     = 5665                       # API port (optional - defaults to 5665)
ic2_path     = /                          # API URI (optional - defaults to "/")
ic2_version  = 1                          # API version (optional - defaults to 1)
ic2_user     = username                   # API user (required)
ic2_pass     = password                   # API user password (required)
ic2_insec    = 1                          # optional - plugin skips certificate verification if set
# ic2_cacert   = <cert_path>              # The file name of a PEM-format file containing the certificate of the CA
                                          # that issued the server's HTTPS certificate. As internal monitoring servers
                                          # often use certs from in-house CAs, this still allows for secure peer
                                          #identification instead of using insecure mode.
```

### Restart mbot
```
sudo systemctl restart mbot
```

## Usage
Ask help from bot
```
Mbot: help
```
