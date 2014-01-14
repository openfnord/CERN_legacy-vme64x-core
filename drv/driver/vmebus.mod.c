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
	{ 0x6bc3fbc0, "__unregister_chrdev" },
	{ 0x3ce4ca6f, "disable_irq" },
	{ 0x12da5bb2, "__kmalloc" },
	{ 0xc897c382, "sg_init_table" },
	{ 0x645a7ae4, "driver_register" },
	{ 0x72df2f2a, "up_read" },
	{ 0x5cdc6018, "__bus_register" },
	{ 0x8ba16ff7, "pci_release_region" },
	{ 0x360b3724, "mem_map" },
	{ 0x3ec8886f, "param_ops_int" },
	{ 0x4acd93d3, "release_resource" },
	{ 0x2fbba096, "page_address" },
	{ 0xb2ba53eb, "dev_set_drvdata" },
	{ 0xc8b57c27, "autoremove_wake_function" },
	{ 0xd3d60af, "dma_set_mask" },
	{ 0x62c1ade7, "malloc_sizes" },
	{ 0xd85df7d4, "boot_cpu_data" },
	{ 0xea5578d5, "pci_disable_device" },
	{ 0x2addc0be, "down_interruptible" },
	{ 0x4f4dcfda, "remove_proc_entry" },
	{ 0x5792fc3, "device_destroy" },
	{ 0x6729d3df, "__get_user_4" },
	{ 0x112acbc6, "__register_chrdev" },
	{ 0x3fec048f, "sg_next" },
	{ 0xeae3dfd6, "__const_udelay" },
	{ 0xcc99e735, "mutex_unlock" },
	{ 0x250033a2, "pci_bus_alloc_resource" },
	{ 0xb5aa7165, "dma_pool_destroy" },
	{ 0x91715312, "sprintf" },
	{ 0x3da171f9, "pci_mem_start" },
	{ 0xd0f0d945, "down_read" },
	{ 0x48eb0c0d, "__init_waitqueue_head" },
	{ 0xc97261a2, "pci_set_master" },
	{ 0xfdb9b629, "ioread32be" },
	{ 0x93c66c7c, "proc_mkdir" },
	{ 0xf10de535, "ioread8" },
	{ 0x5d74e403, "device_register" },
	{ 0xab80f0ef, "pci_iounmap" },
	{ 0xf97456ea, "_raw_spin_unlock_irqrestore" },
	{ 0x95435001, "current_task" },
	{ 0xdd3afd66, "mutex_lock_interruptible" },
	{ 0xce65a0a8, "__mutex_init" },
	{ 0x50eedeb8, "printk" },
	{ 0x531b604e, "__virt_addr_valid" },
	{ 0x6c98efc4, "driver_unregister" },
	{ 0xa1c76e0a, "_cond_resched" },
	{ 0x2da418b5, "copy_to_user" },
	{ 0x16305289, "warn_slowpath_null" },
	{ 0xa5dd69ea, "mutex_lock" },
	{ 0xdd1a2871, "down" },
	{ 0x71abefe1, "device_create" },
	{ 0x2a37d074, "dma_pool_free" },
	{ 0xd6b8e852, "request_threaded_irq" },
	{ 0x97fb6f5e, "bus_unregister" },
	{ 0x7e5d5a9e, "_dev_info" },
	{ 0x6acb973d, "iowrite32be" },
	{ 0xb2fd5ceb, "__put_user_4" },
	{ 0x42c8de35, "ioremap_nocache" },
	{ 0x846eb382, "pci_bus_read_config_dword" },
	{ 0xdbef1716, "put_device" },
	{ 0xba1c1701, "get_user_pages" },
	{ 0x3bd1b1f6, "msecs_to_jiffies" },
	{ 0xd62c833f, "schedule_timeout" },
	{ 0x4292364c, "schedule" },
	{ 0x22088018, "create_proc_entry" },
	{ 0x771cf835, "dma_pool_alloc" },
	{ 0xfc8cc9a9, "pci_unregister_driver" },
	{ 0x6fe340df, "kmem_cache_alloc_trace" },
	{ 0x21fb443e, "_raw_spin_lock_irqsave" },
	{ 0xe45f60d8, "__wake_up" },
	{ 0x37a0cba, "kfree" },
	{ 0x1f0f14a8, "remap_pfn_range" },
	{ 0x622fa02a, "prepare_to_wait" },
	{ 0xedc03953, "iounmap" },
	{ 0xc4554217, "up" },
	{ 0x7e79192d, "__pci_register_driver" },
	{ 0x77b0b954, "put_page" },
	{ 0xd13b2b18, "class_destroy" },
	{ 0x75bb675a, "finish_wait" },
	{ 0xad2688a8, "device_unregister" },
	{ 0x48ccb2c4, "pci_iomap" },
	{ 0x9fe27247, "dev_set_name" },
	{ 0xf71fee1a, "pci_find_parent_resource" },
	{ 0xdb49d31, "pci_enable_device" },
	{ 0x33d169c9, "_copy_from_user" },
	{ 0x85572b48, "dma_pool_create" },
	{ 0x1df70be4, "__class_create" },
	{ 0xf021a561, "pci_request_region" },
	{ 0x3ae4ab7, "dma_ops" },
	{ 0xe484e35f, "ioread32" },
	{ 0xf20dabd8, "free_irq" },
	{ 0xe914e41e, "strcpy" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";

MODULE_ALIAS("pci:v000010E3d00000148sv*sd*bc*sc*i*");

MODULE_INFO(srcversion, "5BF559D6307FFBF32862CA3");
