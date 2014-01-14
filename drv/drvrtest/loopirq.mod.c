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
	{ 0x3ec8886f, "param_ops_int" },
	{ 0x8ecccb22, "vme_free_irq" },
	{ 0xf9a482f9, "msleep" },
	{ 0x7832e4d0, "vme_generate_interrupt" },
	{ 0xd72f079c, "vme_request_irq" },
	{ 0x50eedeb8, "printk" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=vmebus";


MODULE_INFO(srcversion, "A896282F2870FE8756238A2");
