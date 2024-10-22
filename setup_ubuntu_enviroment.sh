#!/bin/bash

sudo apt-get update
sudo apt-get upgrade
sudo apt-get purge -y apport
sudo apt-get remove -y popularity-contest
sudo apt-get autoremove -y

sudo snap remove firefox
sudo install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
if [ ! -f /etc/apt/sources.list.d/mozilla.list ]; then
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
fi
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla 
sudo apt-get update && sudo apt-get install -y firefox

sudo apt-get install -y flatpak gnome-software-plugin-flatpak

sudo apt-get install -y thunderbird thunderbird-locale-de

sudo apt-get install -y virtualbox virtualbox-qt virtualbox-dkms
# -Fix: Can't enumerate USB devices for virtualbox
sudo usermod -aG vboxusers "$USER"

sudo apt-get install -y keepassxc

sudo apt-get install -y nextcloud-desktop

sudo apt-get install -y linphone-desktop

sudo apt-get install -y meld

sudo apt-get install -y bleachbit

sudo apt-get install -y torbrowser-launcher

sudo apt-get install -y htop zram-config

wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt update && sudo apt install codium

sudo apt-get install -y libxcb-cursor0 libfreetype-dev
sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
  sudo tee /etc/apt/sources.list.d/signal-xenial.list
sudo apt update && sudo apt install signal-desktop

# install Element
sudo apt install -y wget apt-transport-https
sudo wget -O /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | sudo tee /etc/apt/sources.list.d/element-io.list
sudo apt update
sudo apt install element-desktop

# install Syncthing
sudo apt-get install curl
sudo mkdir -p /etc/apt/keyrings
sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
sudo apt-get update
sudo apt-get install syncthing
sudo cp /usr/share/applications/syncthing-start.desktop ~/.config/autostart/
sudo chown "$USER": syncthing-start.desktop

cd ~/Downloads || exit 1
wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.4_all.deb
sudo dpkg -i ./protonvpn-stable-release_1.0.4_all.deb && sudo apt update
sudo apt install proton-vpn-gnome-desktop
sudo apt install libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1 gnome-shell-extension-appindicator

cd ~/Downloads || exit 1
wget https://proton.me/download/bridge/protonmail-bridge_3.12.0-1_amd64.deb
sudo apt install ./protonmail-bridge_3.12.0-1_amd64.deb

# Bitbox
cd ~/Downloads || exit 1
wget https://github.com/BitBoxSwiss/bitbox-wallet-app/releases/download/v4.44.1/bitbox_4.44.1_amd64.deb
sudo apt install ./bitbox_4.44.1_amd64.deb

# balenaEtcher
cd ~/Downloads || exit 1
wget https://github.com/balena-io/etcher/releases/download/v1.19.25/balenaEtcher-linux-x64-1.19.25.zip
mkdir -p ~/Applications
unzip ./balenaEtcher-linux-x64-1.19.25.zip -d ~/Applications

# portofolioPerformance
cd ~/Downloads || exit 1
wget https://github.com/buchen/portfolio/releases/download/0.71.2/PortfolioPerformance-0.71.2-linux.gtk.x86_64.tar.gz
mkdir -p ~/Applications
tar -xvzf PortfolioPerformance-0.71.2-linux.gtk.x86_64.tar.gz -C ~/Applications

# VeraCrypt
cd ~/Downloads || exit 1
wget https://launchpad.net/veracrypt/trunk/1.26.14/+download/veracrypt-1.26.14-setup.tar.bz2
mkdir -p ~/Applications
tar -xvf veracrypt-1.26.14-setup.tar.bz2 -C ~/Downloads
./veracrypt-1.26.14-setup-gui-x64

# AppImages require FUSE to run.
sudo apt install libfuse2

# Standard Notes
cd ~/Applications || exit 1
wget https://github.com/standardnotes/app/releases/download/%40standardnotes/desktop%403.195.12/standard-notes-3.195.12-linux-x86_64.AppImage
chmod a+x standard-notes-3.195.12-linux-x86_64.AppImage

# Antivirus
sudo apt install -y clamav clamav-daemon
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam
#clamscan -r -i /
#clamscan -r -i --remove=yes /

sudo apt-get autoremove

# sort apps by name in launcher
gsettings set org.gnome.shell app-picker-layout "[]"
