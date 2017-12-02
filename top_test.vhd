----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:39:43 12/02/2017 
-- Design Name: 
-- Module Name:    top_test - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_test is
    port(
        cntrl0_ddr2_dq                : inout std_logic_vector(31 downto 0);
        cntrl0_ddr2_a                 : out   std_logic_vector(13 downto 0);
        cntrl0_ddr2_ba                : out   std_logic_vector(2 downto 0);
        cntrl0_ddr2_ras_n             : out   std_logic;
        cntrl0_ddr2_cas_n             : out   std_logic;
        cntrl0_ddr2_we_n              : out   std_logic;
        cntrl0_ddr2_cs_n              : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_cs_n_cpy              : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_odt               : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_odt_cpy               : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_cke               : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_dm                : out   std_logic_vector(3 downto 0);
        i1_clk_pin                    : in    std_logic;
        cntrl0_ddr2_dqs               : inout std_logic_vector(3 downto 0);
        cntrl0_ddr2_dqs_n             : inout std_logic_vector(3 downto 0);
        cntrl0_ddr2_ck                : out   std_logic_vector(1 downto 0);
        cntrl0_ddr2_ck_n              : out   std_logic_vector(1 downto 0)
    );
end top_test;

architecture Behavioral of top_test is

    component DDR2
    port (
        cntrl0_ddr2_dq                : inout std_logic_vector(31 downto 0);
        cntrl0_ddr2_a                 : out   std_logic_vector(13 downto 0);
        cntrl0_ddr2_ba                : out   std_logic_vector(2 downto 0);
        cntrl0_ddr2_ras_n             : out   std_logic;
        cntrl0_ddr2_cas_n             : out   std_logic;
        cntrl0_ddr2_we_n              : out   std_logic;
        cntrl0_ddr2_cs_n              : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_cs_n_cpy              : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_odt               : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_odt_cpy               : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_cke               : out   std_logic_vector(0 downto 0);
        cntrl0_ddr2_dm                : out   std_logic_vector(3 downto 0);
        sys_clk                       : in    std_logic;
        idly_clk_200                  : in    std_logic;
        sys_reset_in_n                : in    std_logic;
        cntrl0_init_done              : out   std_logic;
        cntrl0_error                  : out   std_logic;
        cntrl0_ddr2_dqs               : inout std_logic_vector(3 downto 0);
        cntrl0_ddr2_dqs_n             : inout std_logic_vector(3 downto 0);
        cntrl0_ddr2_ck                : out   std_logic_vector(1 downto 0);
        cntrl0_ddr2_ck_n              : out   std_logic_vector(1 downto 0)
        );
    end component;

    component dcm
    port(
        CLKIN_IN : IN std_logic;
        RST_IN : IN std_logic;          
        CLKFX_OUT : OUT std_logic;
        CLKFX180_OUT : OUT std_logic;
        CLKIN_IBUFG_OUT : OUT std_logic;
        CLK0_OUT : OUT std_logic;
        CLK90_OUT : OUT std_logic;
        LOCKED_OUT : OUT std_logic
    );
    end component;

    signal dcm_locked           :std_logic;
    signal sys_clk              :std_logic;
    signal idly_clk_200         :std_logic;
    signal sys_reset            :std_logic:='1';
    signal cntrl0_init_done     :std_logic;
    signal cntrl0_error         :std_logic;

    signal reset_cnt            :integer:=0;

    attribute KEEP:string;
    attribute KEEP of cntrl0_init_done: signal is "TRUE";
    attribute KEEP of cntrl0_ddr2_dq: signal is "TRUE";
    attribute KEEP of cntrl0_ddr2_a: signal is "TRUE";

begin

    ddr2_0:DDR2
    port map(
        cntrl0_ddr2_dq          =>  cntrl0_ddr2_dq      ,      
        cntrl0_ddr2_a           =>  cntrl0_ddr2_a       ,      
        cntrl0_ddr2_ba          =>  cntrl0_ddr2_ba      ,      
        cntrl0_ddr2_ras_n       =>  cntrl0_ddr2_ras_n   ,      
        cntrl0_ddr2_cas_n       =>  cntrl0_ddr2_cas_n   ,      
        cntrl0_ddr2_we_n        =>  cntrl0_ddr2_we_n    ,      
        cntrl0_ddr2_cs_n        =>  cntrl0_ddr2_cs_n    ,      
        cntrl0_ddr2_cs_n_cpy    =>  cntrl0_ddr2_cs_n_cpy,          
        cntrl0_ddr2_odt         =>  cntrl0_ddr2_odt     ,      
        cntrl0_ddr2_odt_cpy     =>  cntrl0_ddr2_odt_cpy ,          
        cntrl0_ddr2_cke         =>  cntrl0_ddr2_cke     ,      
        cntrl0_ddr2_dm          =>  cntrl0_ddr2_dm      ,      
        sys_clk                 =>  sys_clk             ,      
        idly_clk_200            =>  idly_clk_200        ,      
        sys_reset_in_n          =>  not sys_reset      ,      
        cntrl0_init_done        =>  cntrl0_init_done    ,      
        cntrl0_error            =>  cntrl0_error        ,      
        cntrl0_ddr2_dqs         =>  cntrl0_ddr2_dqs     ,      
        cntrl0_ddr2_dqs_n       =>  cntrl0_ddr2_dqs_n   ,      
        cntrl0_ddr2_ck          =>  cntrl0_ddr2_ck      ,      
        cntrl0_ddr2_ck_n        =>  cntrl0_ddr2_ck_n      
    );

    Inst_dcm2: dcm port map(
		CLKIN_IN => i1_clk_pin,
		RST_IN => '0',
		CLKFX_OUT => sys_clk,
		CLKFX180_OUT => idly_clk_200,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => open,
		CLK90_OUT => open,
		LOCKED_OUT => open
	);

    main:process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if reset_cnt<50000 then
                sys_reset <='1';
                reset_cnt <= reset_cnt + 1;
            else
                sys_reset <='0';
            end if;
        end if; 
    end process;

end Behavioral;

