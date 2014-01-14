SRCS = vme_cs_csr_cfg vme_sw_reset write_ctrl_window

RANLIB=ranlib

CFLAGS		= -Wall -DDEBUG -D_GNU_SOURCE -g -I. -I../$(INCDIR)
CFLAGS		+= -I../driver
CFLAGS          += -I../lib
LIBVMEBUS	= ../lib/libvmebus.a
LIBVD80		= libvd80.a
LDLIBS		= -lrt

all: $(SRCS:.c=)

.PHONY: all sources clean

$(LIBVMEBUS):
	$(MAKE) -C ../$(LIBDIR)

%.o:     %.c
	$(CC) $(CFLAGS) -o $@ -c $<

sources: $(SRCS) $(SCRIPTS)

vme_cs_csr_cfg: vme_cs_csr_cfg.c $(LIBVMEBUS)

vme_sw_reset: vme_sw_reset.c $(LIBVMEBUS)

write_ctrl_window: write_ctrl_window.c $(LIBVMEBUS)

clean:
	$(RM) *.o *.a *.bak  $(SRCS:.c=)
