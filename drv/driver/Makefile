CPU?=x86_64

all: driver
driver: modules

modules:
	$(MAKE) -C $(KERNELSRC) M=`pwd` CPU=$(CPU) GIT_VERSION=$(GIT_VERSION) modules

clean:
	$(MAKE) -C $(KERNELSRC) M=`pwd` clean
