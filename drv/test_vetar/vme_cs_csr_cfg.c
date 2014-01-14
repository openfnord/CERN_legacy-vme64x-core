#include <unistd.h>
#include <libvmebus.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include <signal.h>

#define VME_MAP      0
#define WB_CTRL_MAP  1
#define WB_MAP       2

/* VME CSR offsets */
#define FUN0ADER			   	0x7FF63
#define FUN1ADER				   0x7FF73
#define WB_32_64				   0x7ff33
#define BIT_SET_REG				0x7FFFB
#define BIT_CLR_REG				0x7FFF7
#define IRQ_VECTOR				0x7FF5F
#define IRQ_LEVEL  				0x7FF5B
#define VME_VENDOR_ID_OFFSET	0x24

/* VME CSR VALUES */
#define WB32					1
#define WB64					0
#define RESET_CORE				0x80
#define ENABLE_CORE				0x10
#define VME_IRQ_LEVEL			0x6
#define VME_VENDOR_ID			0x80031

/* VME WB Interdace*/
#define ERROR_FLAG    			0
#define SDWB_ADDRESS 	 		8
#define CTRL					   16
#define MASTER_CTRL				24
#define MASTER_ADD				32
#define MASTER_DATA 			   40

#define clear() printf("\033[H\033[J")

struct vme_mapping   map[3];
void   *virt[3];

uint32_t do_mapping( uint32_t slot )
{

   map[VME_MAP].am         = VME_CR_CSR;
	map[VME_MAP].data_width	= VME_D32;
   map[VME_MAP].sizel		= 0x80000;
	map[VME_MAP].vme_addrl	= slot * 0x80000;

	virt[VME_MAP] = vme_map(&map[VME_MAP], 1);

	if (virt[VME_MAP] == NULL) {
		perror("vme_map VME_MAP");
		return -1;
	}
   return 0;
}

void vme_csr_write(uint32_t value, uint32_t offset)
{
   *(volatile uint32_t *) (virt[VME_MAP] + offset) = value;
}

uint8_t vme_csr_read(offset)
{
   uint8_t rv = (*(volatile uint8_t *)(virt[VME_MAP] + offset));

   return rv;
}

uint32_t vme_csr_read32(offset)
{
   uint32_t rv = swapbe32(*(volatile uint32_t *)(virt[VME_MAP] + offset));

   return rv;
}

int main( int argc, char *argv[] )
{

   uint32_t slot = 1;
   uint32_t rv = 0;

   clear();

   if ( argc != 2 )
   {
      printf( "Please indicate with VETAR card you want to hit\n");
      return 0;
   }

   sscanf (argv[1],"%d",&slot);

   /* Creating the mapping of CR/CSR, WB and WB CTRL */
   if(do_mapping(slot) < 0)
   {
      printf("Problem Mapping \n");
      return -1;
   }

   printf("****************************************\n");
   printf("*CONFIGURATION VME VETAR CARD IN SLOT %d*\n", slot);
   printf("****************************************\n");

   rv = vme_csr_read32(VME_VENDOR_ID_OFFSET) << 16;
   rv += vme_csr_read32(VME_VENDOR_ID_OFFSET+4) << 8;
   rv += vme_csr_read32(VME_VENDOR_ID_OFFSET+8);
   printf("Vendor ID: \t\t\t %x \n",rv);


   rv = vme_csr_read(FUN0ADER)<<24;
   rv += vme_csr_read(FUN0ADER+4)<<16;
   rv += vme_csr_read(FUN0ADER+8)<<8;
   printf("Wisbone bus base address: \t %x \n",rv);

   rv = vme_csr_read(FUN1ADER)<<24;
   rv += vme_csr_read(FUN1ADER+4)<<16;
   rv += vme_csr_read(FUN1ADER+8)<<8;
   printf("Wisbone Ctrl bus base address: \t %x \n",rv);

   rv = vme_csr_read(WB_32_64);

   if(rv == 1) printf("WB interface: \t\t\t 32 bits\n");
   else        printf("WB interface: \t\t\t 64 bits\n");


   rv = vme_csr_read(IRQ_VECTOR);
   printf("IRQ Vector: \t\t\t %x \n",rv);

   rv = vme_csr_read(IRQ_LEVEL);
   printf("IRQ Level: \t\t\t %x \n",rv);

   rv = vme_csr_read(BIT_SET_REG);
   if(rv != 0x18) printf("Error Flag: \t\t\t Not asserted \n");
   else printf("Error Flag: \t\t\t Asserted!!!\n");

   rv = vme_csr_read(BIT_SET_REG);
   if(rv&0x10) printf("WB Bus: \t\t\t Enabled \n");
   else printf("WB Bus: \t\t\t Not Enabled!! \n");

   fflush(stdout);

	vme_unmap(&map[0], 0);

   return 0;
}

