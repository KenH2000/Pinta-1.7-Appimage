#!/bin/bash
sudo apt install ca-certificates gnupg -y
sudo gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt update
#install dependencies
sudo apt install mono-runtime libglib2.0-cil libmono-posix4.0-cil gtk-sharp2 libmono-addins0.2-cil libmono-addins-gui0.2-cil -y
