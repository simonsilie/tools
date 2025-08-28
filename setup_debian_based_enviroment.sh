#!/bin/bash

# Usage and Distro Parsing
if [ $# -eq 0 ]; then
    echo "Usage: $0 <distro>"
    echo "Supported distros: debian, ubuntu, mint"
    exit 1
fi

distro=$(echo "$1" | tr '[:upper:]' '[:lower:]')

case "$distro" in
    debian|ubuntu|mint) ;;
    *)
        echo "Unsupported distro: $distro"
        echo "Supported distros: debian, ubuntu, mint"
        exit 2
        ;;
esac

github_url="https://github.com"

protonvpn_package="protonvpn-stable-release_1.0.4_all.deb"
protonmail_bridge_package="protonmail-bridge_3.12.0-1_amd64.deb"
bitbox_version="4.44.1"
bitbox_package="bitbox_${bitbox_version}_amd64.deb"
balenaEtcher_version="1.19.25"
balenaEtcher_zip="balenaEtcher-linux-x64-${balenaEtcher_version}.zip"
portfolio_version="0.71.2"
portfolio_tar_gz="PortfolioPerformance-${portfolio_version}-linux.gtk.x86_64.tar.gz"
veracrypt_version="1.26.14"
veracrypt_tar_bz2="veracrypt-${veracrypt_version}-setup.tar.bz2"
standardnotes_version="3.195.12"
standardnotes_app="standard-notes-${standardnotes_version}-linux-x86_64.AppImage"

PKG_UPDATE="sudo apt update"
PKG_UPGRADE="sudo apt upgrade -y"
PKG_INSTALL="sudo apt install -y"
PKG_REMOVE="sudo apt remove -y"
PKG_PURGE="sudo apt purge -y"
PKG_AUTOREMOVE="sudo apt autoremove -y"

$PKG_UPDATE
$PKG_UPGRADE
$PKG_PURGE apport
$PKG_REMOVE popularity-contest
$PKG_AUTOREMOVE

if [ "$distro" = "ubuntu" ]; then
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
    sudo apt-get update && sudo apt-get install --allow-downgrades -y firefox
fi

$PKG_INSTALL flatpak gnome-software-plugin-flatpak

$PKG_INSTALL thunderbird thunderbird-locale-de

$PKG_INSTALL virtualbox virtualbox-qt virtualbox-dkms
# -Fix: Can't enumerate USB devices for virtualbox
sudo usermod -aG vboxusers "$USER"

$PKG_INSTALL keepassxc

$PKG_INSTALL nextcloud-desktop

$PKG_INSTALL linphone-desktop

$PKG_INSTALL meld

$PKG_INSTALL bleachbit

$PKG_INSTALL torbrowser-launcher

$PKG_INSTALL htop zram-config

# install Codium
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list
$PKG_UPDATE && $PKG_INSTALL codium

# install Calibre
$PKG_INSTALL libxcb-cursor0 libfreetype-dev
sudo -v && wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin

# install Signal
wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
cat signal-desktop-keyring.gpg | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' |\
  sudo tee /etc/apt/sources.list.d/signal-xenial.list
$PKG_UPDATE && $PKG_INSTALL signal-desktop
rm -rf signal-desktop-keyring.gpg

# install Element
$PKG_INSTALL wget apt-transport-https
sudo wget -O /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | sudo tee /etc/apt/sources.list.d/element-io.list
$PKG_UPDATE
$PKG_INSTALL element-desktop

# install Syncthing
$PKG_INSTALL -y curl
sudo mkdir -p /etc/apt/keyrings
sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
$PKG_UPDATE
$PKG_INSTALL -y syncthing
sudo cp /usr/share/applications/syncthing-start.desktop ~/.config/autostart/
sudo chown "$USER": syncthing-start.desktop

# install ProtonVPN
cd ~/Downloads || exit 1
wget https://repo.protonvpn.com/debian/dists/stable/main/binary-all/${protonvpn_package}
sudo dpkg -i ./${protonvpn_package} && $PKG_UPDATE
$PKG_INSTALL proton-vpn-gnome-desktop
$PKG_INSTALL libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1 gnome-shell-extension-appindicator
rm -rf ${protonvpn_package}

# install Protonmail Bridge
cd ~/Downloads || exit 1
wget https://proton.me/download/bridge/${protonmail_bridge_package}
$PKG_INSTALL ./${protonmail_bridge_package}
rm -rf ${protonmail_bridge_package}

# Bitbox
cd ~/Downloads || exit 1
wget ${github_url}/BitBoxSwiss/bitbox-wallet-app/releases/download/v${bitbox_version}/${bitbox_package}
$PKG_INSTALL ./${bitbox_package}
rm -rf ${bitbox_package}

# balenaEtcher
cd ~/Downloads || exit 1
wget ${github_url}/balena-io/etcher/releases/download/v${balenaEtcher_version}/${balenaEtcher_zip}
mkdir -p ~/Applications
unzip ./${balenaEtcher_zip} -d ~/Applications
rm -rf ${balenaEtcher_zip}

# portofolioPerformance
cd ~/Downloads || exit 1
wget ${github_url}/buchen/portfolio/releases/download/${portfolio_version}/${portfolio_tar_gz}
mkdir -p ~/Applications
tar -xvzf ${portfolio_tar_gz} -C ~/Applications
rm -rf ${portfolio_tar_gz}
$PKG_INSTALL default-jre

# VeraCrypt
cd ~/Downloads || exit 1
wget https://launchpad.net/veracrypt/trunk/${veracrypt_version}/+download/${veracrypt_tar_bz2}
mkdir -p ~/Applications
tar -xvf ${veracrypt_tar_bz2} -C ~/Downloads
./veracrypt-1.26.14-setup-gui-x64
find  . -name 'veracrypt*' -exec rm {} \;

# AppImages require FUSE to run.
$PKG_INSTALL libfuse2

# Standard Notes
cd ~/Applications || exit 1
wget ${github_url}/standardnotes/app/releases/download/%40standardnotes/desktop%40${standardnotes_version}/${standardnotes_app}
mv ${standardnotes_app} standard-notes-linux-x86_64.AppImage
chmod a+x standard-notes-linux-x86_64.AppImage

# Antivirus
$PKG_INSTALL clamav clamav-daemon
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam
#clamscan -r -i /
#clamscan -r -i --remove=yes /

$PKG_AUTOREMOVE

sudo cp ./desktop_files/* /usr/share/applications
sudo cp ./desktop_files/.icons ~/Applications/.icons

# sort apps by name in launcher
gsettings set org.gnome.shell app-picker-layout "[]"
