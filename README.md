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
#NOTE:  Additional resources are added when addin manager and file save as ora are clicked. I tried to excercise every menu function to make sure all resources were added to the list.
```
### Final Functional AppDir Tree
The resulting resources needed to run pinta/mono are shown here in tree form.  This helps in developing a plan to copy the needed files to the AppDir. 
<pre>
AppDir
├── AppRun
├── pinta.desktop
├── pinta.png
└── usr
    └── local
        ├── bin
        │   ├── mono
        │   ├── mono-sgen
        │   └── pinta
        ├── etc
        │   └── mono
        │       └── config
        └── lib
            ├── libmono-native.so
            ├── libMonoPosixHelper.so
            ├── mono
            │   ├── 4.5
            │   │   └── mscorlib.dll
            │   └── gac
            │       ├── atk-sharp
            │       │   └── 2.12.0.0__35e10195dab3c99f
            │       │       ├── atk-sharp.dll
            │       │       ├── atk-sharp.dll.config
            │       │       ├── libatksharpglue-2.so
            │       │       └── libglibsharpglue-2.so -> ../../glib-sharp/2.12.0.0__35e10195dab3c99f/libglibsharpglue-2.so
            │       ├── gdk-sharp
            │       │   └── 2.12.0.0__35e10195dab3c99f
            │       │       ├── gdk-sharp.dll
            │       │       ├── gdk-sharp.dll.config
            │       │       ├── libgdksharpglue-2.so
            │       │       └── libglibsharpglue-2.so -> ../../glib-sharp/2.12.0.0__35e10195dab3c99f/libglibsharpglue-2.so
            │       ├── glib-sharp
            │       │   └── 2.12.0.0__35e10195dab3c99f
            │       │       ├── glib-sharp.dll
            │       │       ├── glib-sharp.dll.config
            │       │       └── libglibsharpglue-2.so
            │       ├── gtk-sharp
            │       │   └── 2.12.0.0__35e10195dab3c99f
            │       │       ├── gtk-sharp.dll
            │       │       ├── gtk-sharp.dll.config
            │       │       ├── libglibsharpglue-2.so -> ../../glib-sharp/2.12.0.0__35e10195dab3c99f/libglibsharpglue-2.so
            │       │       └── libgtksharpglue-2.so
            │       ├── ICSharpCode.SharpZipLib
            │       │   └── 4.84.0.0__1b03e6acf1164f73
            │       │       └── ICSharpCode.SharpZipLib.dll
            │       ├── Mono.Addins
            │       │   └── 1.0.0.0__0738eb9f132ed756
            │       │       └── Mono.Addins.dll
            │       ├── Mono.Addins.Gui
            │       │   └── 1.0.0.0__0738eb9f132ed756
            │       │       └── Mono.Addins.Gui.dll
            │       ├── Mono.Addins.Setup
            │       │   └── 1.0.0.0__0738eb9f132ed756
            │       │       └── Mono.Addins.Setup.dll
            │       ├── Mono.Cairo
            │       │   └── 4.0.0.0__0738eb9f132ed756
            │       │       ├── Mono.Cairo.dll
            │       │       └── Mono.Cairo.dll.config
            │       ├── Mono.Posix
            │       │   └── 4.0.0.0__0738eb9f132ed756
            │       │       └── Mono.Posix.dll
            │       ├── pango-sharp
            │       │   └── 2.12.0.0__35e10195dab3c99f
            │       │       ├── libglibsharpglue-2.so -> ../../glib-sharp/2.12.0.0__35e10195dab3c99f/libglibsharpglue-2.so
            │       │       ├── libpangosharpglue-2.so
            │       │       ├── pango-sharp.dll
            │       │       └── pango-sharp.dll.config
            │       ├── System
            │       │   └── 4.0.0.0__b77a5c561934e089
            │       │       └── System.dll
            │       ├── System.Core
            │       │   └── 4.0.0.0__b77a5c561934e089
            │       │       └── System.Core.dll
            │       └── System.Xml
            │           └── 4.0.0.0__b77a5c561934e089
            │               └── System.Xml.dll
            └── pinta
                ├── Pinta.Core.dll
                ├── Pinta.Core.dll.config
                ├── Pinta.Effects.dll
                ├── Pinta.exe
                ├── Pinta.Gui.Widgets.dll
                ├── Pinta.Resources.dll
                └── Pinta.Tools.dll

38 directories, 46 files
</pre>
#### Copy mono libraries, binaries and the config file
After analyzing the running program.  Copy the resources that pinta/mono needs to the AppDir.
```
appdir=/home/"$USER"/temp/AppDir
mkdir -p "$appdir"/usr/local/etc/mono
mkdir -p "$appdir"/usr/local/bin
mkdir -p "$appdir"/usr/local/lib/mono/4.5
mkdir -p "$appdir"/usr/local/lib/mono/gac
mkdir -p "$appdir"/usr/local/lib/pinta

cp /etc/mono/config "$appdir"/usr/local/etc/mono/config
cp /usr/bin/mono "$appdir"/usr/local/bin/.
cp /usr/bin/mono-sgen "$appdir"/usr/local/bin/.
cp /usr/local/bin/pinta "$appdir"/usr/local/bin/.
cp /usr/lib/libmono-native.so "$appdir"/usr/local/lib/.
cp /usr/lib/libMonoPosixHelper.so "$appdir"/usr/local/lib/.
cp /usr/lib/mono/4.5/mscorlib.dll "$appdir"/usr/local/lib/mono/4.5/.
cp /usr/lib/mono/4.5/mscorlib.dll.so "$appdir"/usr/local/lib/mono/4.5/.
cp -R /usr/lib/mono/gac/atk-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/gdk-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/glib-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/gtk-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/ICSharpCode.SharpZipLib "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Addins "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Addins.Gui "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Addins.Setup "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Cairo "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Posix "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/pango-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/System "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/System.Core "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/System.Xml "$appdir"/usr/local/lib/mono/gac 
```
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

#### Run appimagetool
```
ARCH=x86_64 /home/$USER/Documents/appimagetool-x86_64.AppImage /home/$USER/temp/AppDir/ /home/$USER/temp/pinta-appimage
```

### pinta_create_AppDir.sh
The script automates the entire process described above
```
#!/bin/bash
appdir=/home/"$USER"/temp/AppDir
mkdir -p "$appdir"/usr/local/etc/mono
mkdir -p "$appdir"/usr/local/bin
mkdir -p "$appdir"/usr/local/lib/mono/4.5
mkdir -p "$appdir"/usr/local/lib/mono/gac
mkdir -p "$appdir"/usr/local/lib/pinta

cp /etc/mono/config "$appdir"/usr/local/etc/mono/config
cp /usr/bin/mono "$appdir"/usr/local/bin/.
cp /usr/bin/mono-sgen "$appdir"/usr/local/bin/.
cp /usr/local/bin/pinta "$appdir"/usr/local/bin/.
cp /usr/lib/libmono-native.so "$appdir"/usr/local/lib/.
cp /usr/lib/libMonoPosixHelper.so "$appdir"/usr/local/lib/.
cp /usr/lib/mono/4.5/mscorlib.dll "$appdir"/usr/local/lib/mono/4.5/.
cp /usr/lib/mono/4.5/mscorlib.dll.so "$appdir"/usr/local/lib/mono/4.5/.
cp -R /usr/lib/mono/gac/atk-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/gdk-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/glib-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/gtk-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/ICSharpCode.SharpZipLib "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Addins "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Addins.Gui "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Addins.Setup "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Cairo "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/Mono.Posix "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/pango-sharp "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/System "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/System.Core "$appdir"/usr/local/lib/mono/gac
cp -R /usr/lib/mono/gac/System.Xml "$appdir"/usr/local/lib/mono/gac
#copy pinta files from system if not already there from compile
if [ ! -f AppDir/usr/local/lib/pinta/Pinta.exe ];then
  cp -R /usr/lib/pinta/* "$appdir"/usr/local/lib/pinta                 
fi

#copy /usr/lib/cli/ .so files to "$appdir"/usr/local/lib/gac/...
src=/usr/lib/cli
files=(atk-sharp-2.0 gdk-sharp-2.0 glib-sharp-2.0 gtk-sharp-2.0 pango-sharp-2.0)
tgtdir=2.12.0.0__35e10195dab3c99f
for x in "${files[@]}";do
tgtfdr=$(echo "$x"|sed 's|-2.0||')
fn=$(ls "$src/$x"|grep ".so")
cp "$src/$x/$fn" "$appdir"/usr/local/lib/mono/gac/"$tgtfdr/$tgtdir/$fn"
done

#remove absolute paths from .config files
for x in "${files[@]}";do
tgtfdr=$(echo "$x"|sed 's|-2.0||')
fn=$(ls "$appdir"/usr/local/lib/mono/gac/"$tgtfdr/$tgtdir/"*.config)
sed -i 's|/usr/lib/cli/'"$x"'/||' "$fn"
sed -i 's|/usr/lib/cli/glib-sharp-2.0/||' "$fn"
#add symbolic links to libglibsharpglue-2.so
cd "$appdir"/usr/local/lib/mono/gac/"$tgtfdr"/"$tgtdir"/
ln -s ../../glib-sharp/"$tgtdir"/libglibsharpglue-2.so .
done

#EDIT the pinta bin file so it runs from $appdir
echo 'exec ${APPDIR}/usr/local/bin/mono ${APPDIR}/usr/local/lib/pinta/Pinta.exe "$@"'>"$appdir"/usr/local/bin/pinta

#create AppRun
ar='''#!/bin/bash

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
'''
echo "$ar">"$appdir"/AppRun
chmod +x "$appdir"/AppRun

#create pinta.desktop in AppDir (required by appimage builder)
pd='''[Desktop Entry]
Name=Pinta
GenericName=Pinta
Comment=Draw package
Exec=pinta %f
Terminal=false
Icon=pinta
Type=Application
Categories=System;
StartupNotify=true'''
echo "$pd">"$appdir"/pinta.desktop

#copy 256x256 icon, pinta.png in AppDir (required by appimage builder)
cp /usr/share/icons/gnome/256x256/categories/applications-graphics.png "$appdir"/pinta.png
```
##  ----DONE WITH APPIMAGE----

### FOR INFO ONLY -- NOT RECOMMENDED FOR FINAL APPIMAGE CREATION
Trial and error led me to try building mono directly into the AppDir.  Although this populates AppDir with many needed resources, it OVERPOPULATES with 500M of unneeded files.  It does not include the glib/atk/gdk/gtk-sharp libraries and configuration files needed for pinta to run.  But it was helpful in leading to a working solution with mono.
```
#https://download.mono-project.com/sources/mono/index.html
cd mono-6.12.0.199
./configure 
make
make install DESTDIR=/home/$USER/temp/AppDir
```
