#!/usr/bin/make

## variables

# metadata

PRODUCT = hiragino
VERSION = 0.0.1
PACKAGE = otf-hiragino
DEBREV  = $(shell head -n 1 debian/changelog \
                  | cut -d' ' -f 2 | sed 's/(\(.*\)-\(.*\))/\2/')

# programs

TAR_XVCS= tar --exclude=".svn" --exclude=".git" --exclude=".hg"
DEBUILDOPTS=
PBUILDER = cowbuilder
PBOPTS   = --hookdir=pbuilder-hooks \
           --bindmounts "/var/cache/pbuilder/result"

# files and directories

DESTDIR =
FONTSDIR= $(DESTDIR)/usr/share/fonts
TEXMF   = $(DESTDIR)/usr/share/texmf
TEXMF_TL= $(DESTDIR)/usr/share/texmf-texlive
SRCDIR  = /var/tmp/hiragino
UNINSTDIR:=$(SRCDIR)/uninstalled.$(shell date -u +%Y%m%d%H%M%S).$$$$

hiraminstd = $(foreach v,Std StdN,$(foreach w,2 3 4 5 6 7 8,HiraMin$(v)-W$(w).otf))
hiraminpro = $(foreach v,Pro ProN,$(foreach w,2 3 6,HiraMin$(v)-W$(w).otf))
hirakakustd= $(foreach v,Std StdN,$(foreach w,1 2 3 4 5 6 7 8 9,HiraKaku$(v)-W$(w).otf))
hirakakupro= $(foreach v,Pro ProN,$(foreach w,3 6,HiraKaku$(v)-W$(w).otf))
hiramarustd= $(foreach v,Std StdN,$(foreach w,2 4 6 8,HiraMaru$(v)-W$(w).otf))
hiramarupro= $(foreach v,Pro ProN,$(foreach w,4,HiraMaru$(v)-W$(w).otf))
hiragyostd = $(foreach v,Std StdN,$(foreach w,4 8,HiraGyo$(v)-W$(w).otf))
hiragyopro =
hiraall    = $(hiraminstd) $(hiraminpro) $(hirakakustd) $(hirakakupro) \
             $(hiramarustd) $(hiramarupro) $(hiragyostd) $(hiragyopro)
available  = $(foreach f,\
                       $(hiraall),\
                       $(shell if [ -f $(SRCDIR)/$(f) ]; then echo $(f); fi))
unavailable= $(foreach f,\
                       $(hiraall),\
                       $(shell if [ ! -f $(SRCDIR)/$(f) ]; then echo $(f); fi))

DIST    = Makefile

RELEASE = $(PRODUCT)-$(VERSION)

DEB     = $(PACKAGE)_$(VERSION)-$(DEBREV)
DEBORIG = $(PACKAGE)_$(VERSION).orig.tar.gz

## targets

all:

.PHONY: all install uninstall checkprep \
	deb pbuilder-build pbuilder-login pbuilder-test \
	mostlyclean clean distclean
.SECONDARY:

# installation

install: checkprep
	@if [ ! -d $(FONTSDIR)/opentype/hiragino ]; then \
	  echo Creating directory $(FONTSDIR)/opentype/hiragino; \
	  mkdir -p $(FONTSDIR)/opentype/hiragino; \
	fi
	cp $(addprefix $(SRCDIR)/,$(available)) $(FONTSDIR)/opentype/hiragino/
	@for d in $(TEXMF)/fonts $(TEXMF_TL)/fonts; do \
	  echo Looking for directory $$d; \
	  if [ -d $$d ]; then \
	    echo $$d found; \
	    if [ ! -d $$d/opentype ]; then \
	      echo Creating directory $$d/opentype; \
	      mkdir -p $$d/opentype; \
	    fi; \
	    if [ ! -h $$d/opentype/hiragino ]; then \
	      echo Creating symlink from $$d/opentype/hiragino \
	                            to $(FONTSDIR)/opentype/hiragino; \
	      ln -s $(FONTSDIR)/opentype/hiragino $$d/opentype/hiragino; \
	    fi; \
	  fi; \
	done

uninstall:
	@if [ -d $(FONTSDIR)/opentype/hiragino ] && \
	    [ -e $(FONTSDIR)/opentype/hiragino/* ]; then \
	  echo Installed font files found, moving to $(UNINSTDIR); \
	  mkdir -p $(UNINSTDIR); \
	  mv $(FONTSDIR)/opentype/hiragino/* $(UNINSTDIR); \
	  echo Deleting directory $(FONTSDIR)/opentype/hiragino; \
	  rm -fr $(FONTSDIR)/opentype/hiragino; \
	fi
	@if [ -d $(FONTSDIR)/opentype ] && \
	    [ ! -e $(FONTSDIR)/opentype/* ]; then \
	  echo Deleting empty directory $(FONTSDIR)/opentype; \
	  rmdir $(FONTSDIR)/opentype; \
	fi
	@for d in $(TEXMF)/fonts $(TEXMF_TL)/fonts; do \
	  if [ -h $$d/opentype/hiragino ]; then \
	    echo Deleting link $$d/opentype/hiragino; \
	    rm -f $$d/opentype/hiragino; \
	    if [ -d $$d/opentype ] && [ ! -e $$d/opentype/* ]; then \
	      echo Deleting empty directory $$d/opentype; \
	      rmdir $$d/opentype; \
	    fi; \
	  fi; \
	done

checkprep:
	@if [ ! -d $(SRCDIR)  ]; then \
	  echo Directory $(SRCDIR) not found.; \
	  echo Prepare font files in directory $(SRCDIR) and try again.; \
	  exit 1; \
	fi
	@echo Looking for fonts in $(SRCDIR):
	@echo Available: $(available)
	@echo Unavailable: $(unavailable)
	@if [ -z "$(strip $(available))"  ]; then \
	  echo No font available; \
	  exit 1; \
	fi

# source package

dist: $(RELEASE).tar.gz

$(RELEASE): $(DIST)
	mkdir -p $@
	($(TAR_XVCS) -cf - $(DIST)) | (cd $@ && tar xpf -)

%.tar.gz: %
	tar cfz $@ $<

# debian package

deb: $(DEB)_all.deb

$(DEB)_all.deb: pbuilder-build
	cp /var/cache/pbuilder/result/$@ ./

pbuilder-build: $(DEB).dsc
	sudo $(PBUILDER) --build $< -- $(PBOPTS)

pbuilder-login:
	sudo $(PBUILDER) --login $(PBOPTS)

pbuilder-test: $(DEB)_all.deb
	sudo $(PBUILDER) --execute --hookdir=pbuilder-hooks \
	  --bindmounts "/var/cache/pbuilder/result /var/tmp/hiragino" \
	  -- pbuilder-hooks/test.sh \
	$(PACKAGE) $(VERSION) $(DEBREV)

$(DEB).dsc: $(RELEASE) $(DEBORIG)
	($(TAR_XVCS) -cf - debian) | (cd $(RELEASE) && tar xpf -)
	(cd $(RELEASE) && debuild $(DEBUILDOPTS); cd -)

$(DEBORIG): $(RELEASE).tar.gz
	cp $< $@

# utilities

mostlyclean:	
	rm -fr $(RELEASE)
	rm -f $(DEB)_*.build $(DEB)_*.changes
	rm -fr debian/$(PRODUCT)

clean: mostlyclean
	rm -f $(RELEASE).tar.gz
	rm -f $(DEB).dsc $(DEBORIG) $(DEB).diff.gz $(DEB)_*.deb

distclean: clean
