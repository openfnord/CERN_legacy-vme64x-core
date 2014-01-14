SRCS =	create_window.c destroy_window.c setflag.c \
	test_mapping.c testctr.c testctr_ces.c\
	hsm-dma.c berrtest.c doublemap.c \
	testvd80.c vd80spd.c vd80spd-dma.c mm6390-dma.c \
	testvd802.c test_mapping.c testctr.c testctr2.c testctr_ces.c \

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

testctr_ces: testctr_ces.c $(LIBVMEBUS)

testctr2: testctr2.c $(LIBVMEBUS)

testvd80: testvd80.c $(LIBVD80) $(LIBVMEBUS)

testvd802: testvd802.c $(LIBVMEBUS)

vd80spd: vd80spd.c $(LIBVD80) $(LIBVMEBUS)

vd80spd-dma: vd80spd-dma.c $(LIBVD80) $(LIBVMEBUS)

libvd80.o: libvd80.c libvd80.h

libvd80.a: libvd80.o
	$(AR) rv $(LIBVD80) $^
	$(RANLIB) $(LIBVD80)

mm6390-dma: mm6390-dma.c $(LIBVMEBUS)

hsm-dma: hsm-dma.c $(LIBVMEBUS)

berrtest: berrtest.c $(LIBVMEBUS)

doublemap: doublemap.c $(LIBVMEBUS)

clean:
	$(RM) *.o *.a *.bak  $(SRCS:.c=)
