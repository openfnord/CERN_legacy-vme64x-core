/*
* Copyright (C) 2012-2013 CERN (www.cern.ch)
* Author: Juan David Gonzalez Cobas <dcobas@cern.ch>
* Author: Luis Fernando Ruiz Gago <lfruiz@cern.ch>
*
* Released according to the GNU GPL, version 2 or any later version
*
* Driver for VETAR (Simple VME FMC carrier) board.
*/
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/fs.h>
#include <linux/version.h>
#include <linux/slab.h>
#include <linux/firmware.h>
#include <linux/delay.h>
#include <linux/io.h>
#include "vetar.h"
#include "xloader_regs.h"

/* Module parameters */
static int  slot[VETAR_MAX_DEVICES];
static unsigned int slot_num;
static unsigned int vmebase[VETAR_MAX_DEVICES];
static unsigned int vmebase_num;
static int  vector[VETAR_MAX_DEVICES];
static unsigned int vector_num;
static int lun[VETAR_MAX_DEVICES] = VETAR_DEFAULT_IDX;
static unsigned int lun_num;


module_param_array(slot, int, &slot_num, S_IRUGO);
MODULE_PARM_DESC(slot, "Slot where VETAR card is installed");
module_param_array(vmebase, uint, &vmebase_num, S_IRUGO);
MODULE_PARM_DESC(vmebase, "VME Base address of the VETAR card registers");
module_param_array(vector, int, &vector_num, S_IRUGO);
MODULE_PARM_DESC(vector, "IRQ vector");
module_param_array(lun, int, &lun_num, S_IRUGO);
MODULE_PARM_DESC(lun, "Index value for VETAR card");

int vetar_map_window(struct vetar_dev *vetar, enum vetar_map_win map_type)
{
	struct device *dev = vetar->dev;
	enum vme_address_modifier am = VME_CR_CSR;
	enum vme_data_width dw = VME_D32;
	unsigned long base = vetar->slot * 0x80000;
	unsigned int size = 0x80000;
	int rval;

	if (vetar->map[map_type] != NULL) {
		dev_err(dev, "Window %d already mapped\n", (int)map_type);
		return -EPERM;
	}

	/* Default values are for MAP_CR_CSR */
	/* For register map, we need to set them to: */
	if (map_type == MAP_REG) {
		am = VME_A32_USER_DATA_SCT;
		dw = VME_D32;
		base = vetar->vmebase;
		size = 0x100000;
	}

	vetar->map[map_type] = kzalloc(sizeof(struct vme_mapping), GFP_KERNEL);
	if (!vetar->map[map_type]) {
		dev_err(dev, "Cannot allocate memory for vme_mapping struct\n");
		return -ENOMEM;
	}

	/* Window mapping*/
	vetar->map[map_type]->am =		am; /* 0x2f */
	vetar->map[map_type]->data_width =	dw;
	vetar->map[map_type]->vme_addru =	0;
	vetar->map[map_type]->vme_addrl =	base;
	vetar->map[map_type]->sizeu =		0;
	vetar->map[map_type]->sizel =		size;

	if (( rval = vme_find_mapping(vetar->map[map_type], 1)) != 0) {
		dev_err(dev, "Failed to map window %d: (%d)\n",
				(int)map_type, rval);
		kfree(vetar->map[map_type]);
		vetar->map[map_type] = NULL;
		return -EINVAL;
	}

	dev_info(dev, "%s mapping successful at 0x%p\n",
			map_type == MAP_REG ? "register" : "CR/CSR",
			vetar->map[map_type]->kernel_va);

	return 0;
}

int vetar_unmap_window(struct vetar_dev *vetar, enum vetar_map_win map_type)
{
	struct device *dev = vetar->dev;

	if (vetar->map[map_type] == NULL) {
		dev_err(dev, "Window %d not mapped. Cannot unmap\n",
				(int)map_type);
		return -EINVAL;
	}
	if (vme_release_mapping(vetar->map[map_type], 1)) {
		dev_err(dev, "Unmap for window %d failed\n", (int)map_type);
		return -EINVAL;
	}
	dev_info(dev, "Window %d unmaped\n", (int)map_type);
	kfree(vetar->map[map_type]);
	vetar->map[map_type] = NULL;
	return 0;
}

static void vetar_csr_write(u8 value, void *base, u32 offset)
{
	offset -= offset % 4;
	iowrite32be(value, base + offset);
}

void vetar_setup_csr_fa0(void *base, u32 vme, unsigned vector, unsigned level)
{
	u8 fa[4];		/* FUN0 ADER contents */

	/* reset the core */
	vetar_csr_write(RESET_CORE, base, BIT_SET_REG);
	msleep(10);

	/* disable the core */
	vetar_csr_write(ENABLE_CORE, base, BIT_CLR_REG);

	/* default to 32bit WB interface */
	vetar_csr_write(WB32, base, WB_32_64);

	/* set interrupt vector and level */
	vetar_csr_write(vector, base, INTVECTOR);
	vetar_csr_write(level, base, INT_LEVEL);

	/* do address relocation for FUN0 */
	fa[0] = (vme >> 24) & 0xFF;
	fa[1] = (vme >> 16) & 0xFF;
	fa[2] = (vme >> 8 ) & 0xFF;
	fa[3] = (VME_A32_USER_DATA_SCT & 0x3F) << 2;
			/* DFSR and XAM are zero */

	vetar_csr_write(fa[0], base, FUN0ADER);
	vetar_csr_write(fa[1], base, FUN0ADER + 4);
	vetar_csr_write(fa[2], base, FUN0ADER + 8);
	vetar_csr_write(fa[3], base, FUN0ADER + 12);

	/* enable module, hence make FUN0 available */
	vetar_csr_write(ENABLE_CORE, base, BIT_SET_REG);
}

static int vetar_remove(struct device *pdev, unsigned int ndev)
{
	struct vetar_dev *vetar = dev_get_drvdata(pdev);

	//vetar_fmc_destroy(vetar);

	vetar_unmap_window(vetar, MAP_CR_CSR);
	vetar_unmap_window(vetar, MAP_REG);
	//vetar_remove_sysfs_files(vetar);
	kfree(vetar);

	dev_info(pdev, "removed\n");

	return 0;
}

int vetar_is_present(struct vetar_dev *vetar)
{
	struct device *dev = vetar->dev;
	uint32_t idc;
	void *addr;

	/* Check for bootloader */
	//if (vetar_is_bootloader_active(vetar)) {
	//	return 1;
	//}

	/* Ok, maybe there is a vetar, but bootloader is not active.
	In such case, a CR/CSR with a valid manufacturer ID should exist*/

	addr = vetar->map[MAP_CR_CSR]->kernel_va + VME_VENDOR_ID_OFFSET;

	idc = be32_to_cpu(ioread32(addr)) << 16;
	idc += be32_to_cpu(ioread32(addr + 4))  << 8;
	idc += be32_to_cpu(ioread32(addr + 8));

	if (idc == VETAR_VENDOR_ID) {
		dev_info(dev, "vendor ID is 0x%08x\n", idc);
		return 1;
	}

	dev_err(dev, "wrong vendor ID. 0x%08x found, 0x%08x expected\n",
			idc, VETAR_VENDOR_ID);
	dev_err(dev, "VETAR not present at slot %d\n", vetar->slot);

	return 0;

}

static int vetar_probe(struct device *pdev, unsigned int ndev)
{
	struct vetar_dev *vetar;
	const char *name;
	int error = 0;

	if (lun[ndev] >= VETAR_MAX_DEVICES) {
		dev_err(pdev, "Card lun %d out of range [0..%d]\n",
			lun[ndev], VETAR_MAX_DEVICES - 1);
		return -EINVAL;
	}

	vetar = kzalloc(sizeof(*vetar), GFP_KERNEL);
	if (vetar == NULL) {
		dev_err(pdev, "Cannot allocate memory for vetar card struct\n");
		return -ENOMEM;
	}

	/* Initialize struct fields*/
	vetar->lun = lun[ndev];
	vetar->slot = slot[ndev];
	vetar->vmebase = vmebase[ndev];
	vetar->vector = vector[ndev];
	vetar->level = VETAR_IRQ_LEVEL; /* Default value */
	//vetar->fmcs_n = VETAR_N_SLOTS; /* FIXME: Two mezzanines */
	vetar->dev = pdev;

	/* Get firmware name */
//	if (ndev < fw_name_num) {
//		vetar->fw_name = fw_name[ndev];
//	} else {
//		vetar->fw_name = vetar_fw_name; /* Default value */
//		dev_warn(pdev, "'fw_name' parameter not provided,"\
//				" using %s as default\n", vetar->fw_name);
//	}
//
	/* Map CR/CSR space */
	error = vetar_map_window(vetar, MAP_CR_CSR);
	if (error)
		goto failed;

	if (!vetar_is_present(vetar)) {
		error = -EINVAL;
		goto failed_unmap_crcsr;
	}

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,29)
	name = pdev->bus_id;
#else
	name = dev_name(pdev);
#endif
	strlcpy(vetar->driver, KBUILD_MODNAME, sizeof(vetar->driver));
	snprintf(vetar->description, sizeof(vetar->description),
		"VETAR at VME-A32 slot %d 0x%08x - 0x%08x irqv %d irql %d",
		vetar->slot, vetar->slot << 19, vetar->vmebase,
		vector[ndev], vetar->level);

	dev_info(pdev, "%s\n", vetar->description);

	dev_set_drvdata(vetar->dev, vetar);
//	error = vetar_create_sysfs_files(vetar);
//	if (error) {
//		dev_err(pdev, "Error creating sysfs files\n");
//		goto failed_unmap_crcsr;
//	}
//
//	/* Load the golden FPGA binary to read the eeprom */
//	error = vetar_load_fpga_file(vetar, vetar->fw_name);
//	if (error)
//		goto failed_sysfs;
//
	/* configure and activate function 0 */
	vetar_setup_csr_fa0(vetar->map[MAP_CR_CSR]->kernel_va, vmebase[ndev],
				vector[ndev], vetar->level);

	/* Map A32 space */
	error = vetar_map_window(vetar, MAP_REG);
	if (error)
		goto failed_sysfs;

//	error = vetar_fmc_create(vetar);
//	if (error) {
//		dev_err(pdev, "error creating fmc devices\n");
//		goto failed_unmap;
//	}

	return 0;

//failed_unmap:
//	vetar_unmap_window(vetar, MAP_REG);
failed_sysfs:
	//vetar_remove_sysfs_files(vetar);
failed_unmap_crcsr:
	vetar_unmap_window(vetar, MAP_CR_CSR);

failed:
	kfree(vetar);

	return error;
}

static struct vme_driver vetar_driver = {
	.probe		= vetar_probe,
	.remove		= vetar_remove,
	.driver		= {
	.name		= KBUILD_MODNAME,
	},
};

static int __init vetar_init(void)
{
	int error = 0;

	/* Check that all insmod argument vectors are the same length */
	if (lun_num != slot_num || lun_num != vmebase_num ||
		lun_num != vector_num) {
		pr_err("%s: The number of parameters doesn't match\n",
		       __func__);
		return -EINVAL;
	}

	error = vme_register_driver(&vetar_driver, lun_num);
	if (error) {
		pr_err("%s: Cannot register vme driver - lun [%d]\n", __func__,
			lun_num);
	}

	return error;
}

static void __exit vetar_exit(void)
{
	vme_unregister_driver(&vetar_driver);
}


module_init(vetar_init);
module_exit(vetar_exit);

MODULE_AUTHOR("Cesar Prados Boda");
MODULE_LICENSE("GPL");
//MODULE_VERSION(GIT_VERSION);
MODULE_VERSION("v0.1");
MODULE_DESCRIPTION("vetar driver");
