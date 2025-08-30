#!/bin/bash

# Usage and Distro Parsing
if [ $# -eq 0 ]; then
    echo "Usage: $0 <distro>"
    echo "Supported distros: debian, ubuntu, mint"
    exit 1
fi

distro=$(echo "$1" | tr '[:upper:]' '[:lower:]')

GITHUB_URL="https://github.com"
BITBOX_VERSION="4.44.1"
BITBOX_PACKAGE="bitbox_${BITBOX_VERSION}_amd64.deb"
balenaEtcher_version="1.19.25"
balenaEtcher_zip="balenaEtcher-linux-x64-${balenaEtcher_version}.zip"
portfolio_version="0.71.2"
portfolio_tar_gz="PortfolioPerformance-${portfolio_version}-linux.gtk.x86_64.tar.gz"
veracrypt_version="1.26.14"
veracrypt_tar_bz2="veracrypt-${veracrypt_version}-setup.tar.bz2"
PKG_UPDATE="sudo apt update"
PKG_UPGRADE="sudo apt upgrade -y"
PKG_INSTALL="sudo apt install -y"
PKG_REMOVE="sudo apt remove -y"
PKG_PURGE="sudo apt purge -y"
PKG_AUTOREMOVE="sudo apt autoremove -y"

case "$distro" in
    debian|ubuntu|mint) ;;
    *)
        echo "Unsupported distro: $distro"
        echo "Supported distros: debian, ubuntu, mint"
        exit 2
        ;;
esac

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
    $PKG_UPDATE && sudo $PKG_INSTALL --allow-downgrades firefox
fi

$PKG_INSTALL flatpak -y
$PKG_INSTALL gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install flathub org.gnome.Extensions -y
flatpak install flathub org.gnome.Firmware -y
flatpak install flathub org.gnome.meld
flatpak install flathub org.mozilla.Thunderbird -y
flatpak install flathub org.keepassxc.KeePassXC -y
flatpak install flathub com.nextcloud.desktopclient.nextcloud -y
flatpak install flathub org.torproject.torbrowser-launcher -y
flatpak install flathub com.bambulab.BambuStudio -y
flatpak install flathub com.vscodium.codium -y
flatpak install flathub org.signal.Signal -y
flatpak install flathub org.kicad.KiCad -y
flatpak install flathub com.protonvpn.www -y
flatpak install flathub ch.protonmail.protonmail-bridge -y
flatpak install flathub com.jetbrains.PyCharm-Community
flatpak install flathub com.calibre_ebook.calibre -y
flatpak install flathub org.standardnotes.standardnotes

$PKG_INSTALL virt-manager

$PKG_INSTALL linphone-desktop

$PKG_INSTALL bleachbit

$PKG_INSTALL htop

if [ "$distro" = "debian" ]; then
    $PKG_INSTALL zram-tools
    echo -e "ALGO=zstd\nPERCENT=60" | sudo tee -a /etc/default/zramswap
    sudo service zramswap reload
else
    $PKG_INSTALL zram-config
fi

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

# Bitbox
cd ~/Downloads || exit 1
wget ${GITHUB_URL}/BitBoxSwiss/bitbox-wallet-app/releases/download/v${BITBOX_VERSION}/${BITBOX_PACKAGE}
$PKG_INSTALL ./${BITBOX_PACKAGE}
rm -rf ${BITBOX_PACKAGE}

# balenaEtcher
cd ~/Downloads || exit 1
wget ${GITHUB_URL}/balena-io/etcher/releases/download/v${balenaEtcher_version}/${balenaEtcher_zip}
mkdir -p ~/Applications
unzip ./${balenaEtcher_zip} -d ~/Applications
rm -rf ${balenaEtcher_zip}

# portofolioPerformance
cd ~/Downloads || exit 1
wget ${GITHUB_URL}/buchen/portfolio/releases/download/${portfolio_version}/${portfolio_tar_gz}
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

# Antivirus
$PKG_INSTALL clamav clamav-daemon
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam
#clamscan -r -i /
#clamscan -r -i --remove=yes /

$PKG_AUTOREMOVE

# sort apps by name in launcher
gsettings set org.gnome.shell app-picker-layout "[]"