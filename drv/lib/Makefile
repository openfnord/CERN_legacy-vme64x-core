EXTSO   = .so
EXTLIB  = .a
OBJFILES = libvmebus.o
DRIVER_NAME = vmebus
FINAL_DEST = ./
RANLIB = ranlib
INCDIRS= -I../driver
CFLAGS = ${INCDIRS}
CFLAGS += -fPIC

all:lib$(DRIVER_NAME)$(EXTSO) lib$(DRIVER_NAME)$(EXTLIB)

# Rules to build .a library
lib$(DRIVER_NAME)$(EXTLIB): lib$(DRIVER_NAME)$(EXTLIB)($(OBJFILES))
	$(RANLIB) $@

lib$(DRIVER_NAME)$(EXTSO): $(OBJFILES)
	$(CC) -shared -Wl,-export-dynamic -Wl,-soname,$(@:%.so=%.so) -o $@ $(OBJFILES)

clean:
	rm -f $(OBJFILES) *.a *.so

