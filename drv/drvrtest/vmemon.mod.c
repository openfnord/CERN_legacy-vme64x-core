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
	{ 0xf59f197, "param_array_ops" },
	{ 0xbccb7cc9, "return_controller" },
	{ 0x106863e, "vme_unregister_berr_handler" },
	{ 0xd1694422, "find_controller" },
	{ 0x97a23c39, "vme_register_berr_handler" },
	{ 0x50eedeb8, "printk" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=vmebus";

