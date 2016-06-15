fonts-hiragino-installer
--------

Hiragino font (OpenType) installer package for Debain systems.

### Installation

Put font files in /var/tmp/hiragino:

    $ mkdir /var/tmp/hiragino
    $ cp HiraMinStdN-W3.otf /var/tmp/hiragino/
    ...

Then install the package.

    $ sudo dpkg -i fonts-hiragino-installer*.deb

If TEXMFMAIN (/usr/share/texmf) exists, it also creates symlinks so
that the fonts are accessible from TeX.

### Uninstallation

    $ sudo apt-get remove fonts-hiragino-installer

### Copyright and License

  * Copyright 2011 Hisashi Morita
  * License: Public domain
