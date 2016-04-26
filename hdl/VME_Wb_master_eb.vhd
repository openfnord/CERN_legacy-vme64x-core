--___________________________________________________________________________________
--                              VME TO WB INTERFACE
--
-- File:                           VME_Wb_master_eb.vhd
--___________________________________________________________________________________
-- Description:
-- This component implements the WB master side in the vme64x core and MSI WB
-- Slave. Work mode:
--            PIPELINED 
--            SINGLE READ/WRITE
--
-- The WB bus is 32 bit wide and the data organization is BIG ENDIAN 
--______________________________________________________________________________
-- Authors:                                      
--              Cesar Prados <c.prados@gsi.de>
-- Date         11/2013                                                                           
-- Version      v0.02
--______________________________________________________________________________
--                               GNU LESSER GENERAL PUBLIC LICENSE                                
--                              ------------------------------------    
-- Copyright (c) 2009 - 2011 GSI
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
   constant WB_WINDOW    :   std_logic_vector := "00000001";
   constant CTRL_WINDOW  :   std_logic_vector := "00000010";
   signal s_shift_dx     :   std_logic;
   signal s_funct_sel    :   std_logic_vector (7 downto 0);
   signal s_cyc          :   std_logic;
   signal s_stb          :   std_logic;
   signal s_cyc_d        :   std_logic;
   signal s_AckWithError :   std_logic;
   signal s_ack_ctrl     :   std_logic;
   signal s_wbData_i     :   std_logic_vector(63 downto 0);
   signal s_select       :   std_logic_vector(8 downto 0);
   signal s_data_ctrl    :   std_logic_vector(g_wb_data_width - 1 downto 0);
   signal s_DATi_sample  :   std_logic_vector(g_wb_data_width - 1 downto 0);

   -- Ctrl
   signal s_error_ctrl   :   std_logic_vector(31 downto 0);
   signal r_addr         :   std_logic_vector(31 downto 16);

   -- MSI register
   signal s_msi_cyc         :   std_logic := '0';
   signal s_msi_fifo_full   :   std_logic;
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

   -- convert data/add widths  
   WBdata_o    <= locDataInSwap_i(g_wb_data_width-1 downto 0); 
   locDataOut_o <= std_logic_vector(resize(unsigned(s_wbData_i), locDataOut_o'length));

   locAddr_o(r_addr'range) <= r_addr;
   locAddr_o(r_addr'right-1 downto 0)  <= rel_locAddr_i(r_addr'right-1 downto 0);
   cyc_o <= s_cyc;
   stb_o <= s_stb;

   process(clk_i)

      begin

      if rising_edge(clk_i) then 

         s_msi_fifo_full_r <= s_msi_fifo_full;
    
         msi_int_master_i.stall <= '1';
         msi_int_master_i.ack   <= '0';
         msi_int_master_i.err   <= '0';
         
        if funct_sel(0) = '1'  or (funct_sel(0) = '0' and funct_sel(1) = '0') then
           
            if (memReq_i = '1' and cardSel_i = '1' and BERRcondition_i = '0' and s_cyc = '1') then
               s_stb <= '1';
            elsif (s_stb = '1' and stall_i = '0' and s_cyc = '1') then
               s_stb <= '0';
             end if;

            s_cyc <= s_cyc_d;

            -- ack and rw handler
            RW_o           <= RW_i;
            s_AckWithError <=(memReq_i and cardSel_i and BERRcondition_i); 
            s_ack_ctrl <= '0';

         elsif funct_sel(1) = '1' and  -- CONTROL WINDOW
               (memReq_i = '1' and cardSel_i = '1' and BERRcondition_i = '0') then
            
            s_ack_ctrl <= '1'; 

            case rel_locAddr_i(5 downto 2) is -- 24 bits access valid addres 0/8/16/24/32 ..
               when "0000" => -- ERROR 
                  s_data_ctrl <= s_error_ctrl;
               when "0010" => -- SDWD
                  s_data_ctrl <= g_sdb_addr;
               when "0100" => -- CTRL
                  s_data_ctrl(31) <= s_cyc_d;
                  s_data_ctrl(30 downto 0) <= (others => '0');
               when "0110" => -- MASTER MSI STATUS
                  s_data_ctrl(31) <= s_msi_fifo_full;
                  s_data_ctrl(30) <= msi_int_master_o.we;
                  s_data_ctrl(29 downto 4) <= (others => '0'); 
                  s_data_ctrl(3  downto 0) <= msi_int_master_o.sel;
               when "1000" => -- MASTER MSI ADD
                  s_data_ctrl     <= msi_int_master_o.adr and c_vme_msi.sdb_component.addr_last(31 downto 0);
               when "1010" => -- MASTER MSI DATA
                  s_data_ctrl     <= msi_int_master_o.dat;
               when "1110" => -- WINDOW OFFSET LOW
                  s_data_ctrl(r_addr'range)  <= r_addr;
                  s_data_ctrl(r_addr'right-1 downto 0) <= (others => '0');
               when others =>
                  s_data_ctrl <= (others => '0');
            end case;
           
            if RW_i = '0' and memReq_i = '1' and cardSel_i = '1' then
               case rel_locAddr_i(5 downto 2) is
                  when "0100" =>  -- CTRL
                         if locDataInSwap_i(30) = '1' then  -- write 
                            s_cyc_d  <= locDataInSwap_i(31);
                         end if;
                  when "0110" => -- MASTER MSI STATUS
                        case locDataInSwap_i(1 downto 0) is
                           when "00" => null;
                           when "01" => msi_int_master_i.stall   <= '0';
                           when "10" => msi_int_master_i.ack     <= '1';
                           when "11" => msi_int_master_i.err     <= '1';
                        end case;
                  when "1010" => -- MASTER MSI DATA
                     msi_int_master_i.dat <= locDataInSwap_i(31 downto 0);
                  when "1100" => -- EMULATION OF DATA WIDTH
                     WbSel_o <= locDataInSwap_i(3 downto 0);
                  when "1110" => -- WINDOW OFFSET LOW
                      r_addr(31 downto 16) <= locDataInSwap_i(31 downto 16);
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
