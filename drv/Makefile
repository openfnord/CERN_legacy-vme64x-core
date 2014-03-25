ifneq ($(CONFIG_VME_BUS),m)
ifneq ($(CONFIG_VME_BUS),y)
SUBDIRS = driver include lib drvrtest test pylib test_vetar
endif
endif

all:	$(SUBDIRS:=-all)
clean:	$(SUBDIRS:=-clean)
install: driver-install

%-all:
	$(MAKE) -C $* all
	
%-clean:
	$(MAKE) -C $* clean
	
%-install:
	$(MAKE) -C $* install
