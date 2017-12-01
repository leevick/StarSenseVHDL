--*****************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2005, 2006, 2007 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor             : Xilinx
-- \   \   \/    Version            : 3.6.1
--  \   \        Application        : MIG
--  /   /        Filename           : DDR2_rd_data_fifo_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the distributed RAM which stores
--               the read data from the memory.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_rd_data_fifo_0 is
  port (
    clk                  : in  std_logic;
    reset                : in  std_logic;
    fifo_rd_en           : in  std_logic;
    read_en_delayed_rise : in  std_logic;
    read_en_delayed_fall : in  std_logic;
    first_rising         : in  std_logic;
    read_data_rise       : in  std_logic_vector(MEMORY_WIDTH-1 downto 0);
    read_data_fall       : in  std_logic_vector(MEMORY_WIDTH-1 downto 0);
    read_data_fifo_rise  : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
    read_data_fifo_fall  : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
    read_data_valid      : out std_logic
    );
end entity;

architecture arc_rd_data_fifo of DDR2_rd_data_fifo_0 is

  component DDR2_ram_d_0
    port (
      dpo   : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
      a0    : in  std_logic;
      a1    : in  std_logic;
      a2    : in  std_logic;
      a3    : in  std_logic;
      d     : in  std_logic_vector(MEMORY_WIDTH-1 downto 0);
      dpra0 : in  std_logic;
      dpra1 : in  std_logic;
      dpra2 : in  std_logic;
      dpra3 : in  std_logic;
      wclk  : in  std_logic;
      we    : in  std_logic
      );
  end component;

  signal fifos_data_out1 : std_logic_vector(2*MEMORY_WIDTH-1 downto 0);
  signal fifo_rd_addr    : std_logic_vector(3 downto 0);
  signal rise0_wr_addr   : std_logic_vector(3 downto 0);
  signal fall0_wr_addr   : std_logic_vector(3 downto 0);

  signal rise_fifo_data  : std_logic_vector(MEMORY_WIDTH-1 downto 0);
  signal fall_fifo_data  : std_logic_vector(MEMORY_WIDTH-1 downto 0);
  signal rise_fifo_out   : std_logic_vector(MEMORY_WIDTH-1 downto 0);
  signal fall_fifo_out   : std_logic_vector(MEMORY_WIDTH-1 downto 0);

  signal fifo_rd_en_r0   : std_logic;
  signal fifo_rd_en_r1   : std_logic;
  signal fifo_rd_en_r2   : std_logic;

  signal reset_r1        : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset_r1 : signal is "no";
  attribute syn_preserve of reset_r1                : signal is true;

begin

  --***************************************************************************

  read_data_valid     <= fifo_rd_en_r2;
  read_data_fifo_fall <= fifos_data_out1(MEMORY_WIDTH-1 downto 0);
  read_data_fifo_rise <= fifos_data_out1(2*MEMORY_WIDTH-1 downto MEMORY_WIDTH);

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset_r1 <= reset;
    end if;
  end process;

  -- Read Enable generation for fifos based on the empty flags
  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1') then
        fifo_rd_en_r0 <= '0';
        fifo_rd_en_r1 <= '0';
        fifo_rd_en_r2 <= '0';
      else
        fifo_rd_en_r0 <= fifo_rd_en;
        fifo_rd_en_r1 <= fifo_rd_en_r0;
        fifo_rd_en_r2 <= fifo_rd_en_r1;
      end if;
    end if;
  end process;

  -- Write Pointer increment for FIFOs
  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1') then
        rise0_wr_addr(3 downto 0) <= x"0";
      elsif (read_en_delayed_rise = '1') then
        rise0_wr_addr(3 downto 0) <= rise0_wr_addr(3 downto 0) + "0001";
      end if;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1') then
        fall0_wr_addr(3 downto 0) <= x"0";
      elsif (read_en_delayed_fall = '1') then
        fall0_wr_addr(3 downto 0) <= fall0_wr_addr(3 downto 0) + "0001";
      end if;
    end if;
  end process;

  --/////////////////// FIFO Data Output Sequencing /////////////////////////

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (fifo_rd_en_r0 = '1') then
        rise_fifo_data <= rise_fifo_out;
        fall_fifo_data <= fall_fifo_out;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1') then
        fifo_rd_addr(3 downto 0) <= x"0";
      elsif (fifo_rd_en_r0 = '1') then
        fifo_rd_addr(3 downto 0) <= fifo_rd_addr(3 downto 0) + "0001";
      end if;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1') then
        fifos_data_out1(2*MEMORY_WIDTH-1 downto 0) <= (others => '0');
      elsif (fifo_rd_en_r1 = '1') then
        if (first_rising = '1') then
          fifos_data_out1(2*MEMORY_WIDTH-1 downto 0) <= fall_fifo_data &
                                                        rise_fifo_data;
        else
          fifos_data_out1(2*MEMORY_WIDTH-1 downto 0) <= rise_fifo_data &
                                                        fall_fifo_data;
        end if;
      end if;
    end if;
  end process;


  --****************************************************************************
  -- Distributed RAM 4 bit wide FIFO instantiations
  -- (2 FIFOs per strobe, rising edge data fifo and falling edge data fifo)
  --****************************************************************************
  -- FIFOs associated with DQS(0)

  ram_rise0 : DDR2_ram_d_0
    port map (
      dpo   => rise_fifo_out(MEMORY_WIDTH-1 downto 0),
      a0    => rise0_wr_addr(0),
      a1    => rise0_wr_addr(1),
      a2    => rise0_wr_addr(2),
      a3    => rise0_wr_addr(3),
      d     => read_data_rise(MEMORY_WIDTH-1 downto 0),
      dpra0 => fifo_rd_addr(0),
      dpra1 => fifo_rd_addr(1),
      dpra2 => fifo_rd_addr(2),
      dpra3 => fifo_rd_addr(3),
      wclk  => clk,
      we    => read_en_delayed_rise
      );

  ram_fall0 : DDR2_ram_d_0
    port map (
      dpo   => fall_fifo_out(MEMORY_WIDTH-1 downto 0),
      a0    => fall0_wr_addr(0),
      a1    => fall0_wr_addr(1),
      a2    => fall0_wr_addr(2),
      a3    => fall0_wr_addr(3),
      d     => read_data_fall(MEMORY_WIDTH-1 downto 0),
      dpra0 => fifo_rd_addr(0),
      dpra1 => fifo_rd_addr(1),
      dpra2 => fifo_rd_addr(2),
      dpra3 => fifo_rd_addr(3),
      wclk  => clk,
      we    => read_en_delayed_fall
      );


end arc_rd_data_fifo;
