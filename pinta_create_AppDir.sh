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

#create pinta.desktop in AppDir
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

#copy 256x256 icon, pinta.png in AppDir
cp /usr/share/icons/gnome/256x256/categories/applications-graphics.png "$appdir"/pinta.png
