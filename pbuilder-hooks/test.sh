#!/bin/sh
if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]
  then
  PACKAGE=$1
  SOFTWARE_VERSION=$2
  PACKAGE_REVISION=$3
  DEBFILE_BASENAME=${PACKAGE}_${SOFTWARE_VERSION}-${PACKAGE_REVISION}
  else
  exit 1
fi

echo "### Editing apt lines..."
cp -v /etc/apt/sources.list /etc/apt/sources.list.bak
echo 'deb http://cdn.debian.net/debian unstable main contrib non-free' >> /etc/apt/sources.list
echo "### /etc/apt/sources.list"
diff -u /etc/apt/sources.list.bak /etc/apt/sources.list
apt-get update
apt-get update
echo "### Installing package and requirements..."
dpkg -i /var/cache/pbuilder/result/${DEBFILE_BASENAME}_all.deb
apt-get install -f --yes
echo "### dpkg -l | grep '^ii'"
dpkg -l | grep '^ii'
echo "### texlive-base (so that symlinks are created)"
apt-get install --no-install-recommends --yes texlive-base
echo "### Files created:"
ls -alR /usr/share/fonts/opentype
ls -alR /usr/share/texmf
echo "### Testing uninstallation..."
dpkg --remove ${PACKAGE}
dpkg --install /var/cache/pbuilder/result/${DEBFILE_BASENAME}_all.deb
dpkg --purge ${PACKAGE}
