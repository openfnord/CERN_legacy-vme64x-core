cmd_/root/deploy/firmware/vmebridge/driver/vmebus.ko := ld -r -m elf_i386 -T /usr/src/linux-headers-3.2.0-4-common/scripts/module-common.lds --build-id  -o /root/deploy/firmware/vmebridge/driver/vmebus.ko /root/deploy/firmware/vmebridge/driver/vmebus.o /root/deploy/firmware/vmebridge/driver/vmebus.mod.o
