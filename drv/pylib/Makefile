CFLAGS += -I../driver -O0 -m32

CC = gcc

all: libvmebus.a libvmebus.so

libvmebus.a: libvmebus.o
	ar r $@ $^

libvmebus.so: libvmebus.o
	$(CC) -m32 -shared $^ -o $@

install: 
	install -D libvmebus.a libvmebus.so /usr/lib/

clean:
	rm -f *.o *.a *.so
