# KVER=2.6.24.7-rt21
# KVER=2.6.24.7-rt27
# KVER=2.6.29.4-rt15
# KVER=2.6.31.6-rt19
# KVER32 ?= 3.2.33-rt50
# KVER64 ?= 3.2.33-rt50.66.el6rt.x86_64

KERNELVER ?= `uname -r`
KERNELDIR ?= /lib/modules/$(KERNELVER)/build

CFLAGS=-g -Wall

all: driver
driver: modules

modules:
	$(MAKE) -C $(KERNELDIR) M=`pwd` modules
clean:
	rm -f *.o *.a *.so $(TESTS)
	rm -f *.mod.c
	rm -rf L866 L865 L864 ppc
	rm -f *.ko
	rm Module.symvers
