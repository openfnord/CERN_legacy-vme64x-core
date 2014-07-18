--___________________________________________________________________________________
--                              VME TO WB INTERFACE
--
-- File:                           VME_Wb_slave.vhd
--___________________________________________________________________________________
-- Description:
-- This component implements the WB slave offering the VME base address and
-- possible more information..
--
-- The WB bus is 32 bit wide and the data organization is BIG ENDIAN 
--______________________________________________________________________________
-- Authors:                                      
--              Cesar Prados <c.prados@gsi.de>
-- Date         07/2014                                                                    
-- Version      v0.01
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
use work.wishbone_pkg.all;

--===========================================================================
-- Entity declaration
--===========================================================================
entity VME_Wb_slave is

  port(
    clk_i       : in std_logic;
    rstn_i      : in std_logic;
    wb_slave_i  : in  t_wishbone_slave_in;
    wb_slave_o  : out t_wishbone_slave_out;
    ga_i        : std_logic_vector(5 downto 0));
end VME_Wb_slave;

architecture rtl of VME_Wb_slave is

begin

  wb_process: process(clk_i)
  
  begin
    if rising_edge(clk_i) then
      if rstn_i = '0' then
        wb_slave_o.ack <= '0';
        wb_slave_o.dat <= (others => '0');
      else 
        wb_slave_o.ack <= wb_slave_i.cyc and wb_slave_i.stb;

        if wb_slave_i.cyc = '1' and wb_slave_i.stb = '1' then
          case wb_slave_i.adr(5 downto 2) is
            when "0000" =>
              wb_slave_o.dat(5 downto 0) <= ga_i;
            when others =>
              wb_slave_o.dat <= (others => '1');
          end case;
        end if;
      end if;
    end if;
  end process;

end rtl;
