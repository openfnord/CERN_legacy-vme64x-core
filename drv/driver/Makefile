CPU?=x86_64

all: driver
driver: modules

modules:
	$(MAKE) -C $(KERNELSRC) M=`pwd` CPU=$(CPU) GIT_VERSION=$(GIT_VERSION) modules

clean:
	$(RM) -r $(CPU)
	$(MAKE) -C $(KERNELSRC) M=`pwd` clean
	
cleanall: clean
	$(RM) -r $(ALL_CPUS)

