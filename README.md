# Pinta-1.7-Appimage
Guidance creating an appimage of pinta with mono.
#### Reference

<pre>
Pinta 1.7
https://github.com/PintaProject/Pinta/releases/tag/1.7
https://github.com/AppImage/appimagetool/tree/main
https://docs.appimage.org/packaging-guide/manual.html

Mono 6.x 
https://www.mono-project.com/download/stable/#download-lin
#Other Mono references:
https://github.com/AppImage/AppImageKit/wiki/Bundling-Mono-apps
https://www.mono-project.com/docs/compiling-mono/linux/
https://www.mono-project.com/docs/advanced/assemblies-and-the-gac/

Apt source 6.x mono (/etc/apt/sources.list.d/mono-official-stable.list)
deb [arch=amd64 signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main
</pre>
#### mono-devel update to 6.x and install dependencies
```
sudo apt install ca-certificates gnupg -y
sudo gpg --homedir /tmp --no-default-keyring --keyring /usr/share/keyrings/mono-official-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
echo "deb [signed-by=/usr/share/keyrings/mono-official-archive-keyring.gpg] https://download.mono-project.com/repo/ubuntu stable-focal main" | sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt update
```
### Pinta Create appimage process
<pre>
#install dependencies and compile into AppDir folder
#(some were missing in pinta readme and caused compile to fail)
sudo apt install mono-runtime libglib2.0-cil libmono-posix4.0-cil gtk-sharp2 libmono-addins0.2-cil libmono-addins-gui0.2-cil -y
cd /home/$USER/temp
mkdir AppDir
#extract from pinta-1.7.tar.gz 
tar -xf pinta-1.7.tar.gz
cd pinta-1.7
./configure 
make
# make the install destination the Appdir 
sudo make install DESTDIR=/home/$USER/temp/AppDir
</pre>

Create AppRun in AppDir 
```
#!/bin/bash

# If running from an extracted image, then export ARGV0 and APPDIR
if [ -z "${APPIMAGE}" ]; then
    export ARGV0="$0"

    self=$(readlink -f -- "$0") # Protect spaces (issue 55)
    here="${self%/*}"
    tmp="${here%/*}"
    export APPDIR="$here" #"${tmp%/*}"
fi

export APPIMAGE_COMMAND=$(command -v -- "$ARGV0")
export MONO_CONFIG=${APPDIR}/usr/local/etc/mono/config
export MONO_CFG_DIR=${APPDIR}/usr/local/etc/mono
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"${APPDIR}/usr/local/lib"

"$APPDIR/usr/local/bin/pinta" "$@"
```
Make AppRun executable
```
chmod +x "$APPDIR"/AppRun
```
Create pinta.desktop in AppDir
<pre>
[Desktop Entry]
Name=Pinta
GenericName=Pinta
Comment=Draw package
Exec=pinta %f
Terminal=false
Icon=pinta
Type=Application
Categories=System;
StartupNotify=true
</pre>
Copy a 256x256 icon as pinta.png in AppDir
```
appdir=/home/$USER/temp/AppDir
cp /usr/share/icons/gnome/256x256/categories/applications-graphics.png "$appdir"/pinta.png
```
#### Analyze pinta while running to show libraries used
```
#To figure out what you need in the appimage, run install and run pinta and find the PID of mono
ps aux|grep mono
#to show the libraries used:
lsof -P -T -p <mono PID>|awk '{print $9}'
#NOTE:  Additional resources are added when addin manager and file save as ora are clicked.<br>
Try to use every menu function to make sure all resources are added to the list.
```
#### Copy mono libraries, binaries and the config file
After analyzing the running program.  Copy the resources that pinta/mono needs to the AppDir.<br>
https://github.com/KenH2000/Pinta-1.7-Appimage/blob/main/pinta_tree.txt

#### Edit library configuration files from /usr/lib/cli/
The configuration and .so files for the libraries listed below are in /usr/lib/cli.  The .so files need to be copied to the applicable AppDir gac folder, and config files edited so the pinta appimage can find them.
```
files=(atk-sharp-2.0 gdk-sharp-2.0 glib-sharp-2.0 gtk-sharp-2.0 pango-sharp-2.0)
tgtdir=2.12.0.0__35e10195dab3c99f
#copy .so files to "$appdir"/usr/local/mono/gac/$files/$tgtdir/<.so file>
#Edit .config file in "$appdir"/usr/local/mono/gac/$files/$tgtdir/<.config file> to remove absolute paths in target="..."
  
#For example, 
cat "$appdir"/usr/local/lib/mono/gac/gtk-sharp/2.12.0.0__35e10195dab3c99f/gtk-sharp.dll.config

<configuration>
  <dllmap dll="libglib-2.0-0.dll" target="libglib-2.0.so.0"/>
  <dllmap dll="libgobject-2.0-0.dll" target="libgobject-2.0.so.0"/>
  <dllmap dll="libatk-1.0-0.dll" target="libatk-1.0.so.0"/>
  <dllmap dll="libgtk-win32-2.0-0.dll" target="libgtk-x11-2.0.so.0"/>
  <dllmap dll="libgdk-win32-2.0-0.dll" target="libgdk-x11-2.0.so.0"/>
  <dllmap dll="gtksharpglue-2" target="/usr/lib/cli/gtk-sharp-2.0/libgtksharpglue-2.so"/>
  <dllmap dll="glibsharpglue-2" target="/usr/lib/cli/glib-sharp-2.0/libglibsharpglue-2.so"/>
</configuration>

#change 
  <dllmap dll="gtksharpglue-2" target="/usr/lib/cli/gtk-sharp-2.0/libgtksharpglue-2.so"/>
  <dllmap dll="glibsharpglue-2" target="/usr/lib/cli/glib-sharp-2.0/libglibsharpglue-2.so"/>
#to
  <dllmap dll="gtksharpglue-2" target="libgtksharpglue-2.so"/>
  <dllmap dll="glibsharpglue-2" target="libglibsharpglue-2.so"/>
```
#### Add symbolic links to libglibsharpglue-2.so in AppDir/usr/local/mono/gac/$files/$tgtdir/
```
cd "$appdir"/usr/local/lib/mono/gac/"$tgtfdr"/"$tgtdir"/
ln -s ../../glib-sharp/"$tgtdir"/libglibsharpglue-2.so .
#Change the pinta bin file so it runs from the ${APPDIR} (its not a real binary, but an executable text file)
APPDIR=/home/$USER/temp/AppDir
echo 'exec ${APPDIR}/usr/local/bin/mono ${APPDIR}/usr/local/lib/pinta/Pinta.exe "$@"'>AppDir/usr/local/bin/pinta
```
### pinta_create_AppDir.sh
The script automates the entire process described above.<br>
https://github.com/KenH2000/Pinta-1.7-Appimage/blob/main/pinta_create_AppDir.sh
## Testing the AppDir
1. Copy the AppDir to linux running from live CD or use bare-bones VM without any of the mono/pinta installs.
2. Run and add missing libraries or correct configuration files.
3. Repeat until pinta runs.
4. Test all the menu functions.
5. Make final appimage.
#### Run appimagetool
```
ARCH=x86_64 /home/$USER/Documents/appimagetool-x86_64.AppImage /home/$USER/temp/AppDir/ /home/$USER/temp/pinta-appimage
```
##  ----DONE WITH APPIMAGE----

### FOR INFO ONLY -- NOT RECOMMENDED FOR FINAL APPIMAGE CREATION
This may be helpful in the development process.  But it populates AppDir with over 500M of unneeded files and did not include the glib/atk/gdk/gtk-sharp libraries or fix the configuration files.  
```
#https://download.mono-project.com/sources/mono/index.html
cd mono-6.12.0.199
./configure 
make
make install DESTDIR=/home/$USER/temp/AppDir
```
