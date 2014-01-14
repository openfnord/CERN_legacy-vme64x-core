--___________________________________________________________________________________
--                              VME TO WB INTERFACE
--
--                                CERN,BE/CO-HT 
--___________________________________________________________________________________
-- File:                           VME_Wb_master.vhd
--___________________________________________________________________________________
-- Description:
-- This component implements the WB master side in the vme64x core.
-- Work mode:
--            PIPELINED 
--            SINGLE READ/WRITE
--
-- The WB bus can be 64 bit wide or 32 bit wide and the data organization is BIG ENDIAN 
-- --> the most significant byte is carried in the lower position of the bus.
-- Eg:
--   _______________________________________________________________________
--  | Byte(0)| Byte(1)| Byte(2)| Byte(3)| Byte(4)| Byte(5)| Byte(6)| Byte(7)|
--  |________|________|________|________|________|________|________|________|
--   D[63:56] D[55:48] D[47:40] D[39:32] D[31:24] D[23:16] D[15:8]  D[7:0]
--
-- eg of timing diagram with synchronous WB Slave:
--             
--       Clk   _____       _____       _____       _____       _____       _____       _____
--       _____|     |_____|     |_____|     |_____|     |_____|     |_____|     |_____|     
--      cyc_o  ____________________________________________________________
--       _____|                                                            |________________
--      stb_o  ________________________________________________
--       _____|                                                |____________________________
--       __________________________________________
--      stall_i                                    |________________________________________
--      ack_i                                                   ___________
--       ______________________________________________________|           |________________       
--
-- The ack_i can be asserted with some Tclk of delay, not immediately.
-- This component implements the correct shift of the data in input/output from/to WB bus
--
--______________________________________________________________________________
-- Authors:                                      
--               Pablo Alvarez Sanchez (Pablo.Alvarez.Sanchez@cern.ch)                             
--               Davide Pedretti       (Davide.Pedretti@cern.ch)  
-- Date         11/2012                                                                           
-- Version      v0.03  
--______________________________________________________________________________
--                               GNU LESSER GENERAL PUBLIC LICENSE                                
--                              ------------------------------------    
-- Copyright (c) 2009 - 2011 CERN                           
-- This source file is free software; you can redistribute it and/or modify it 
-- under the terms of the GNU Lesser General Public License as published by the 
-- Free Software Foundation; either version 2.1 of the License, or (at your option) 
-- any later version. This source is distributed in the hope that it will be useful, 
-- but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for 
-- more details. You should have received a copy of the GNU Lesser General Public 
-- License along with this source; if not, download it from 
-- http://www.gnu.org/licenses/lgpl-2.1.html                     
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.xvme64x_pack.all;
use work.wishbone_pkg.all;

--===========================================================================
-- Entity declaration
--===========================================================================
entity VME_Wb_Interface is
   generic(g_wb_data_width : integer := c_width;
	        g_wb_addr_width : integer := c_addr_width;
           g_family        : string  := "Arria II VME-WB";
           g_sdb_addr : t_wishbone_address := c_sdb_address);

   Port ( memReq_i        : in   std_logic;
          clk_i           : in   std_logic;
          cardSel_i       : in   std_logic;
          reset_i         : in   std_logic;
          BERRcondition_i : in   std_logic;
          sel_i           : in   std_logic_vector(7 downto 0);
          locDataInSwap_i : in   std_logic_vector(63 downto 0);
          locDataOut_o    : out  std_logic_vector(63 downto 0);
          rel_locAddr_i   : in   std_logic_vector(63 downto 0);
          memAckWb_o      : out  std_logic;
          err_o           : out  std_logic;
          rty_o           : out  std_logic;
          RW_i            : in   std_logic;
          stall_i         : in   std_logic;
          rty_i           : in   std_logic;
          err_i           : in   std_logic;
          cyc_o           : out  std_logic;
          stb_o           : out  std_logic;
          WBdata_o        : out  std_logic_vector(g_wb_data_width - 1 downto 0);
          wbData_i        : in   std_logic_vector(g_wb_data_width - 1 downto 0);
          locAddr_o       : out  std_logic_vector(g_wb_addr_width - 1 downto 0);
          memAckWB_i      : in   std_logic;
          WbSel_o         : out  std_logic_vector(f_div8(g_wb_data_width) - 1 downto 0);
          funct_sel       : in   std_logic_vector (7 downto 0);
          RW_o            : out  std_logic;
          -- MSI
          msi_reset_i     : in   std_logic;
          msi_slave_o     : out  t_wishbone_slave_out;
          msi_slave_i     : in   t_wishbone_slave_in := cc_dummy_slave_in;
          msi_irq_o       : out  std_logic       
          );
end VME_Wb_interface;

--===========================================================================
-- Architecture declaration
--==========================================================================
architecture Behavioral of VME_Wb_interface is
   signal s_shift_dx     :   std_logic;
   signal s_funct_sel    :   std_logic_vector (7 downto 0);
   signal s_cyc          :   std_logic;
   signal s_AckWithError :   std_logic;
   signal s_ack_ctrl     :   std_logic;
   signal s_wbData_i     :   std_logic_vector(63 downto 0);
   signal s_select       :   std_logic_vector(8 downto 0);
   signal s_data_ctrl    :   std_logic_vector(g_wb_data_width - 1 downto 0);
   signal s_DATi_sample  :   std_logic_vector(g_wb_data_width - 1 downto 0);
   -- Ctrl
   signal s_error_ctrl   :   std_logic_vector(31 downto 0);
   -- MSI register
   signal s_msi_cyc      :   std_logic := '0';
   signal s_msi_fifo_full:   std_logic;
   signal s_msi_fifo_full_r :   std_logic;

   -- MSI IRQ FIFO
   signal msi_int_master_o  : t_wishbone_master_out;
   signal msi_int_master_i  : t_wishbone_master_in;

--===========================================================================
-- Architecture begin
--===========================================================================
begin

   s_select    <= cardSel_i & sel_i;
   s_wbData_i  <= std_logic_vector(resize(unsigned(s_DATi_sample),s_wbData_i'length));
   cyc_o       <= s_cyc;

   MSI_IRQ_FIFO : xwb_clock_crossing port map(
      slave_clk_i    => clk_i,
      slave_rst_n_i  => msi_reset_i,
      slave_i        => msi_slave_i,
      slave_o        => msi_slave_o,
      master_clk_i   => clk_i, 
      master_rst_n_i => msi_reset_i,
      master_i       => msi_int_master_i,
      master_o       => msi_int_master_o);

   msi_int_master_i.rty <=  '0';
   s_msi_fifo_full      <= msi_int_master_o.cyc and msi_int_master_o.stb;
   msi_irq_o            <= s_msi_fifo_full and not s_msi_fifo_full_r;

   process(clk_i)

      begin

      if rising_edge(clk_i) then 

      s_msi_fifo_full_r <= s_msi_fifo_full;
      s_funct_sel <= funct_sel;
 
      msi_int_master_i.stall <= '1';
      msi_int_master_i.ack   <= '0';
      msi_int_master_i.err   <= '0';

      -- WB WINDOW
         if s_funct_sel(0) = '1'  or (s_funct_sel(0) = '0' and s_funct_sel(1) = '0') then 
            -- strobe hadler
            if reset_i = '1' or (stall_i = '0' and s_cyc = '1') then
               stb_o <= '0';
            elsif memReq_i = '1' and cardSel_i = '1' and BERRcondition_i = '0' then	 
               stb_o <= '1';
            end if;
            -- cycle handler
            if reset_i = '1' or memAckWB_i = '1' then
               s_cyc <= '0';
            elsif memReq_i = '1' and cardSel_i = '1' and BERRcondition_i = '0' then	 
               s_cyc <= '1';
            end if;
            -- ack and rw handler
            RW_o           <= RW_i;
            s_AckWithError <=(memReq_i and cardSel_i and BERRcondition_i); 
            s_ack_ctrl <= '0';

         elsif s_funct_sel(1) = '1' and  -- CONTROL WINDOW
               (memReq_i = '1' and cardSel_i = '1' and BERRcondition_i = '0') then
            
            s_ack_ctrl <= '1'; 

            case rel_locAddr_i(5 downto 0) is -- 24 bits access valid addres 0/8/16/24/32 ..
               when "000000" => -- ERROR 
                  s_data_ctrl <= s_error_ctrl;
               when "001000" => -- SDWD
                  s_data_ctrl <= g_sdb_addr;
               when "010000" => -- CTRL
                  s_data_ctrl(31) <= s_cyc;
                  s_data_ctrl(30 downto 0) <= (others => '0');
               when "011000" => -- MASTER MSI STATUS
                  s_data_ctrl(31) <= s_msi_fifo_full;
                  s_data_ctrl(30) <= msi_int_master_o.we;
                  s_data_ctrl(29 downto 4) <= (others => '0'); 
                  s_data_ctrl(3  downto 0) <= msi_int_master_o.sel;
               when "100000" => -- MASTER MSI ADD
                  s_data_ctrl     <= msi_int_master_o.adr;   
               when "101000" => -- MASTER MSI DATA
                  s_data_ctrl     <= msi_int_master_o.dat;   
               when others =>
                  s_data_ctrl <= (others => '0');
            end case;
           
            if RW_i = '0' and memReq_i = '1' and cardSel_i = '1' then
               case rel_locAddr_i(5 downto 0) is
                  when "010000" =>  -- CTRL
                         if locDataInSwap_i(30) = '1' then  -- write 
                            s_cyc  <= locDataInSwap_i(31);
                         end if;
                  when "011000" => -- MASTER MSI STATUS
                        case locDataInSwap_i(1 downto 0) is
                           when "00" => null;
                           when "01" => msi_int_master_i.stall   <= '0';
                           when "10" => msi_int_master_i.ack     <= '1';
                           when "11" => msi_int_master_i.err     <= '1';
                        end case;
                  when "101000" => -- MASTER MSI DATA
                     msi_int_master_i.dat <= locDataInSwap_i(31 downto 0);
                  when others =>

               end case;
            end if;
         end if;

      -- Shift in the error register
      if err_i = '1' or rty_i = '1' or s_ack_ctrl = '1' then
         s_error_ctrl <= s_error_ctrl(s_error_ctrl'length-2 downto 0) & 
                        (err_i or rty_i );
      end if;

   end if;

   end process;

-- shift data and address for WB data bus 32 bits 	
		
  gen32: if (g_wb_data_width = 32) generate

			process(clk_i)
         begin
	         if rising_edge(clk_i) then
               locAddr_o <= std_logic_vector(resize(unsigned(rel_locAddr_i) srl 2,g_wb_addr_width));
	         end if;
	      end process;
			
			process(sel_i)
         begin
             if sel_i = "10000000" or  sel_i = "01000000" or sel_i = "00100000" or sel_i = "00010000" 
			       or sel_i = "11000000" or sel_i = "00110000" or sel_i = "11110000" then
                s_shift_dx <= '1';
             else	 
                s_shift_dx <= '0';
             end if;
         end process;	
			
		   process(clk_i)
         begin
           if rising_edge(clk_i) then
			     case sel_i is                                          
                 when "10000000" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i) sll 24,g_wb_data_width));
                 when "01000000" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i) sll 16,g_wb_data_width)); 
                 when "00100000" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i) sll 8,g_wb_data_width));
					  when "00010000" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i),g_wb_data_width));
                 when "00001000" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i) sll 24,g_wb_data_width));                                
                 when "00000100" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i) sll 16,g_wb_data_width));                  
                 when "00000010" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i) sll 8,g_wb_data_width));                  
                 when "11000000" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i) sll 16,g_wb_data_width));
                 when "00110000" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i),g_wb_data_width));    
                 when "00001100" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i) sll 16,g_wb_data_width));                      
                 when "11110000" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i),g_wb_data_width));
                 when "00001111" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i),g_wb_data_width));   
                 when "00000001" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i),g_wb_data_width));
                 when "00000011" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i),g_wb_data_width));
					  when "11111111" => WBdata_o <= std_logic_vector(resize(unsigned(locDataInSwap_i),g_wb_data_width));
					  when others => null;
               end case;                        
			  
			     if s_shift_dx = '1' then
			        WbSel_o  <= sel_i(7 downto 4);  
			     else
			        WbSel_o  <= sel_i(3 downto 0);
              end if;			  		  
           end if;	
         end process;
		
		   process (s_select,s_wbData_i)
         begin
           case s_select is
               when "100000010" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(15 downto 0)) srl 8, locDataOut_o'length));
               when "100000100" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(23 downto 0)) srl 16,locDataOut_o'length));
               when "100001000" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(31 downto 0)) srl 24,locDataOut_o'length));
               when "100010000" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(7 downto 0)),locDataOut_o'length));
               when "100100000" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(15 downto 0)) srl 8,locDataOut_o'length));
               when "101000000" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(23 downto 0)) srl 16,locDataOut_o'length));
               when "110000000" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(31 downto 0)) srl 24,locDataOut_o'length));
               when "100001100" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(31 downto 0)) srl 16,locDataOut_o'length));
               when "100110000" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(15 downto 0)),locDataOut_o'length));
               when "111000000" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(31 downto 0)) srl 16,locDataOut_o'length));
               when "100000001" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(7 downto 0)), locDataOut_o'length));
               when "100000011" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(15 downto 0)), locDataOut_o'length));
               when "100001111" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(31 downto 0)), locDataOut_o'length));
               when "111110000" => locDataOut_o <= std_logic_vector(
                    resize(unsigned(s_wbData_i(31 downto 0)), locDataOut_o'length));
               when others => locDataOut_o <= (others => '0');
           end case;
         end process;
			
  end generate gen32;			               
			  
   err_o <= err_i;
   rty_o <= rty_i; 
   memAckWb_o <= memAckWB_i or s_AckWithError or rty_i or s_ack_ctrl;
------------------------------------------------------------------------
    -- This process registers the WB data input; this is a warranty that this
    -- data will be stable during all the time the VME_bus component needs to 
    -- transfers its to the VME bus.
    process(clk_i)
    begin
      if rising_edge(clk_i) then

        if memAckWB_i = '1' then 
           s_DATi_sample   <= wbData_i;       
        elsif s_ack_ctrl = '1' then
           s_DATi_sample   <= s_data_ctrl;
        end if;
      end if;
    end process; 

------------------------------------------------------------------------
end Behavioral;
--===========================================================================
-- Architecture end
--===========================================================================
