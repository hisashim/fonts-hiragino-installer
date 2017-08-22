#!/usr/bin/make

## variables

# metadata

PRODUCT = hiragino
VERSION = $(shell cat VERSION)
PACKAGE = $(shell [ -f debian/changelog ] && \
                  head -n 1 debian/changelog | cut -d' ' -f 1)
DEBREV  = $(shell [ -f debian/changelog ] && \
                  head -n 1 debian/changelog \
                  | cut -d' ' -f 2 | sed 's/(\(.*\)-\(.*\))/\2/')

# programs

TAR_XVCS= tar --exclude=".svn" --exclude=".git" --exclude=".hg"
DEBUILDOPTS=
PBUILDER = cowbuilder
PBRESULT = /var/cache/pbuilder/result
PBOPTS   = --hookdir=pbuilder-hooks \
           --bindmounts "$(PBRESULT) $(SRCDIR)"

# files and directories

SRCDIR  = /var/tmp/hiragino

hiraginoudserif = $(foreach v,Std StdN,$(foreach w,4 6,HiraginoUDSerif$(v)-W$(w).otf))
hiraginoudsans  = $(foreach v,Std StdN,$(foreach w,3 4 5 6,HiraginoUDSans$(v)-W$(w).otf))
hiraginoudsansf = $(foreach v,Std StdN,$(foreach w,3 4 5 6,HiraginoUDSansF$(v)-W$(w).otf))
hiraginoudsansr = $(foreach v,Std StdN,$(foreach w,3 4 5 6,HiraginoUDSansR$(v)-W$(w).otf))
hiraginoserif   = $(foreach v,Pr6N Upr,$(foreach w,3 6,HiraginoSerif$(v)-W$(w).otf))
hiraminpro      = $(foreach v,Pro ProN,$(foreach w,2 3 6,HiraMin$(v)-W$(w).otf))
hiraminstd      = $(foreach v,Std StdN,$(foreach w,2 3 4 5 6 7 8,HiraMin$(v)-W$(w).otf))
hiraginosans    = $(foreach v,Pr6N Upr GB,$(foreach w,3 6,HiraginoSans$(v)-W$(w).otf))
hirakakupro     = $(foreach v,Pro ProN,$(foreach w,3 6,HiraKaku$(v)-W$(w).otf))
hirakakustd     = $(foreach v,Std StdN,$(foreach w,0 1 2 3 4 5 6 7 8 9,HiraKaku$(v)-W$(w).otf))
hirasansold     = $(foreach v,Std StdN,$(foreach w,6 7 8 9,HiraSansOld$(v)-W$(w).otf))
hiraginosansr   = $(foreach v,Pr6N Upr,$(foreach w,4,HiraginoSansR$(v)-W$(w).otf))
hiramarupro     = $(foreach v,Pro ProN,$(foreach w,4,HiraMaru$(v)-W$(w).otf))
hiramarustd     = $(foreach v,Std StdN,$(foreach w,2 3 4 5 6 8,HiraMaru$(v)-W$(w).otf))
hiragyostd      = $(foreach v,Std StdN,$(foreach w,4 8,HiraGyo$(v)-W$(w).otf))
yutuki5gok      = $(foreach v,Std,$(foreach w,2 3 4 5 6 7 8,Yutuki5GoK$(v)-W$(w).otf))
yutuki36pk      = $(foreach v,Std,$(foreach w,2 3 4 5 6 7 8,Yutuki36PK$(v)-W$(w).otf))
hiraminhk       = $(foreach v,Std,$(foreach w,3 4 5 6,HiraMinHK$(v)-W$(w).otf))
hirakakadk      = $(foreach v,Std,$(foreach w,1 2 3 4 5 6 7 8 9,HiraKakADK$(v)-W$(w).otf))
hirakakupk      = $(foreach v,Std,$(foreach w,2 3 4 5 6,HiraKakuPK$(v)-W$(w).otf))
hiraminrub      = $(foreach v,Std,$(foreach w,3,HiraMinRub$(v)-W$(w).otf))
koburinago      = $(foreach v,Std StdN,$(foreach w,1 3 6,KoburinaGo$(v)-W$(w).otf))
hiraall = $(hiraginoudserif) $(hiraginoudsans) $(hiraginoudsansf) $(hiraginoudsansr) \
          $(hiraginoserif) $(hiraminpro) $(hiraminstd) \
          $(hiraginosans) $(hirakakupro) $(hirakakustd) $(hirasansold) \
          $(hiraginosansr) $(hiramarupro) $(hiramarustd) \
          $(hiragyostd) \
          $(yutuki5gok) $(yutuki36pk) \
          $(hiraminhk) $(hirakakadk) $(hirakakupk) $(hiraminrub) \
          $(koburinago)
found   = $(foreach f,\
                    $(hiraall),\
                    $(shell if [ -f $(SRCDIR)/$(f) ]; then echo $(f); fi))
notfound= $(foreach f,\
                    $(hiraall),\
                    $(shell if [ ! -f $(SRCDIR)/$(f) ]; then echo $(f); fi))

DIST    = Makefile VERSION ChangeLog

RELEASE = $(PRODUCT)-$(VERSION)

DEB     = $(PACKAGE)_$(VERSION)-$(DEBREV)
DEBORIG = $(PACKAGE)_$(VERSION).orig

## targets

all: $(DIST) checkprep

.PHONY: all checkprep \
	deb pbuilder-build pbuilder-login pbuilder-test debuild debuild-clean \
	mostlyclean clean maintainer-clean
.SECONDARY:

# installation
# see debian/postinst and debian/postrm for installation and uninstallation

checkprep:
	@if [ ! -d $(SRCDIR)  ]; then \
	  echo Directory $(SRCDIR) not found.; \
	  echo Prepare font files in directory $(SRCDIR) and try again.; \
	  exit 1; \
	fi
	@echo Looking for fonts in $(SRCDIR):
	@echo Found: $(found)
	@echo Not found: $(notfound)
	@if [ -z "$(strip $(found))" ]; then \
	  echo No font found; \
	  exit 1; \
	fi

# source package

dist: $(RELEASE).tar.gz

$(RELEASE): $(DIST)
	mkdir -p $@
	($(TAR_XVCS) -cf - $(DIST)) | (cd $@ && tar xpf -)

ChangeLog:
	devutils/vcslog.sh > $@

%.tar.gz: %
	tar cfz $@ $<

# debian package

deb: pbuilder-build
	cp $(PBRESULT)/$(DEB).diff.gz ./
	cp $(PBRESULT)/$(DEB).dsc ./
	cp $(PBRESULT)/$(DEB)_all.deb ./
	cp $(PBRESULT)/$(DEBORIG).tar.gz ./

pbuilder-build: $(DEB).dsc
	sudo $(PBUILDER) --build $< -- $(PBOPTS)

pbuilder-login:
	sudo $(PBUILDER) --login $(PBOPTS)

pbuilder-test: $(DEB)_all.deb
	sudo $(PBUILDER) --execute $(PBOPTS) -- \
	  pbuilder-hooks/test.sh $(PACKAGE) $(VERSION) $(DEBREV)

$(DEB).dsc: debuild

debuild: $(RELEASE) $(DEBORIG).tar.gz
	($(TAR_XVCS) -cf - debian) | (cd $(RELEASE) && tar xpf -)
	(cd $(RELEASE) && debuild $(DEBUILDOPTS); cd -)

$(DEBORIG).tar.gz: $(RELEASE).tar.gz
	cp -a $< $@

debuild-clean:
	rm -fr $(DEBORIG)
	rm -f $(DEB)_*.build $(DEB)_*.changes
	rm -fr debian/$(PRODUCT)
	rm -f $(DEB).dsc $(DEBORIG).tar.gz $(DEB).diff.gz $(DEB)_*.deb

# utilities

mostlyclean:	
	rm -fr $(RELEASE)

clean: mostlyclean
	rm -f $(RELEASE).tar.gz

maintainer-clean: clean debuild-clean
	rm -f ChangeLog
