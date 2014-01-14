SUBDIRS = driver include lib drvrtest test pylib test_vetar

all: $(SUBDIRS)
clean: driver-clean drvrtest-clean  include-clean  lib-clean  test-clean pylib-clean
install: driver-install lib-install

$(SUBDIRS):
	$(MAKE) -C $@

driver-install: 
	$(MAKE) -C driver install

lib-install: 
	$(MAKE) -C lib install

pylib-clean:
	$(MAKE) -C pylib clean

driver-clean:
	$(MAKE) -C driver clean

drvrtest-clean:
	$(MAKE) -C drvrtest clean

include-clean:
	$(MAKE) -C include clean

lib-clean:
	$(MAKE) -C lib clean

test-clean:
	$(MAKE) -C test clean


.PHONY: $(SUBDIRS)
