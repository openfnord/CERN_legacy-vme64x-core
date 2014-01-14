/*
* Copyright (C) 2012-2013 GSI (www.gsi.de)
* Author: Cesar Prados <c.prados@gsi.de>
*
* Released according to the GNU GPL, version 2 or any later version
*
* Driver for VETAR VME board.
*/
#ifndef __VETAR_H__
#define __VETAR_H__

#include <linux/firmware.h>
#include <vmebus.h>

#define VME_WB 
#define VETAR_MAX_DEVICES        32
#define VETAR_DEFAULT_IDX { [0 ... (VETAR_MAX_DEVICES-1)] = -1 }
#define VETAR_IRQ_LEVEL	2
#define VETAR_VENDOR_ID		0x80031

#define VME_VENDOR_ID_OFFSET	0x24

enum vetar_map_win {
	MAP_CR_CSR = 0,	/* CR/CSR */
	MAP_REG		/* A32 space */
};

/* Our device structure */
struct vetar_dev {
	int			lun;
	int			slot;
	uint32_t		vmebase;
	int			vector;
	int			level;

	char			*fw_name;
	struct device		*dev;
	char			driver[16];
	char			description[80];
	struct vme_mapping	*map[2];

	/* struct work_struct	work; */
	unsigned long		irqcount;
	//struct fmc_device	*fmcs[VETAR_N_SLOTS];
						/* FMC devices */
	//int			fmcs_n;		/* Number of FMC devices */
	//int			irq_count;	/* for mezzanine use too */
};

/* Functions and data in vetar-vme.c */
//extern int vetar_is_bootloader_active(struct vetar_dev *vetar);
//extern int vetar_bootloader_unlock (struct vetar_dev *vetar);
//extern int vetar_load_fpga(struct vetar_dev *vetar, const void *data, int size);
//extern int vetar_load_fpga_file(struct vetar_dev *vetar, const char *name);
extern void vetar_setup_csr_fa0(void *base, u32 vme, unsigned vector,
			       unsigned level);
extern int vetar_unmap_window(struct vetar_dev *vetar, enum vetar_map_win map_type);
extern int vetar_map_window( struct vetar_dev *vetar, enum vetar_map_win map_type);

//extern char *vetar_fw_name;
//extern int spec_use_msi;

/* Functions in vetar-fmc.c, used by vetar-vme.c */
//extern int vetar_fmc_create(struct vetar_dev *vetar);
//extern void vetar_fmc_destroy(struct vetar_dev *vetar);

/* Functions in vetar-i2c.c, used by vetar-fmc.c */
//extern int vetar_i2c_init(struct fmc_device *fmc);
//extern void vetar_i2c_exit(struct fmc_device *fmc);
//extern int vetar_eeprom_read(struct fmc_device *fmc, uint32_t offset,
//			    void *buf, size_t size);
//extern int vetar_eeprom_write(struct fmc_device *fmc, uint32_t offset,
//			     const void *buf, size_t size);

/* VETAR CSR offsets */
#define FUN0ADER	0x7FF63
#define INT_LEVEL	0x7ff5b
#define INTVECTOR	0x7ff5f
#define WB_32_64	0x7ff33
#define BIT_SET_REG	0x7FFFB
#define BIT_CLR_REG	0x7FFF7
#define WB32		1
#define WB64		0
#define RESET_CORE	0x80
#define ENABLE_CORE	0x10

/* Functions in vetar-sysfs.c */
//extern int vetar_create_sysfs_files(struct vetar_dev *card);
//extern void vetar_remove_sysfs_files(struct vetar_dev *card);

#endif /* __VETAR_H__ */
