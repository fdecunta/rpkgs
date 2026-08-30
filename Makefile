PKG = scanpkgs
VERSION = 0.1

TAR = $(PKG)_$(VERSION).tar.gz

$(TAR):
	R CMD build .

install: clean $(TAR)
	R CMD INSTALL $(TAR)

remove:
	R CMD REMOVE $(PKG)

check: $(TAR)
	R CMD check $(TAR)

clean:
	rm -f $(TAR)
	rm -rf $(PKG).Rcheck

.PHONY: install remove check clean


