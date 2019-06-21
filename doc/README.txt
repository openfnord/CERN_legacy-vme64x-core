so far I'm going to use the doc from the 
parent project VME64X core. I don't want to
have replicate documentation so please 
visit:
http://www.ohwr.org/projects/vme64x-core/wiki


This branch adds a so called direct access mode.
By writing to a special register (direct access control register, DACTL) in the A24 address space (with address modifier AM=0x39), the bridge can be switched into the wishbone direct access mode. In the direct access mode, the normal bridge operation will not work anymore. Consequently no wishbone access via etherbone is possible in direct access mode. 

The address of the DACTL is 0x400*slot+0x4. The value of slot is the VME slot number for which the bridge was configured. The default value (in normal bridge mode) in the DACTL register is 0xffffffff. the bridge can be switched back from direct access mode into normal bridge mode by writing the value 0xffffffff into the DACTL register. Writing any other value into the DACTL register will immediately switch the bridge into direct access mode. The value written into DACTL (lets call this value WB_base_address) will be used as wishbone base address. In direct access mode any VME read/write access with address modifier AM=0x09 in the VME A32-address range [0x10000000*slot,0x01ffffff*slot] will be mapped into one single wishbone read/write access: WB_address = VME_address - 0x10000000*slot + WB_base_address.

The use case for this mode is low-latency access to wishbone devices in VME systems, such as data acquisition systems for experiments.
