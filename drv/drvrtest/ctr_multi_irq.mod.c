#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

MODULE_INFO(vermagic, VERMAGIC_STRING);

struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
 .name = KBUILD_MODNAME,
 .init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
 .exit = cleanup_module,
#endif
 .arch = MODULE_ARCH_INIT,
};

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0xd4733cff, "module_layout" },
	{ 0x8ecccb22, "vme_free_irq" },
	{ 0x404e46ad, "vme_release_mapping" },
	{ 0xd72f079c, "vme_request_irq" },
	{ 0xae07c6e9, "vme_find_mapping" },
	{ 0xf9a482f9, "msleep" },
	{ 0xd5d87388, "vme_bus_error_check" },
	{ 0x6acb973d, "iowrite32be" },
	{ 0x50eedeb8, "printk" },
	{ 0xfdb9b629, "ioread32be" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=vmebus";


MODULE_INFO(srcversion, "6E7C0B8A90DCB16F2E95DA9");
