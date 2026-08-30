PROG = rpkgs
BIN  = /usr/local/bin

PKG = scanpkgs
VERSION = 0.1
TAR = $(PKG)_$(VERSION).tar.gz

$(PROG): rpkgs.sh
	cp rpkgs.sh ./$(PROG)
	chmod +x ./$(PROG)

$(TAR):
	R CMD build .

installpkg: clean $(TAR)
	R CMD INSTALL $(TAR)

install: installpkg $(PROG)
	R CMD INSTALL $(TAR)
	sudo mv ./$(PROG) $(BIN)

remove:
	R CMD REMOVE $(PKG)
	sudo rm -f $(BIN)/$(PROG)

check: $(TAR)
	R CMD check $(TAR)

clean:
	rm -f $(TAR)
	rm -rf $(PKG).Rcheck

.PHONY: install remove check clean


