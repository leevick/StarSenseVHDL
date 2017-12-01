library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;

entity top is
    port(
        --clock
        i1_clk_pin:     in std_logic;
        --data
        cntrl0_ddr2_dq: inout std_logic_vector(31 downto 0);
        --address
        cntrl0_ddr2_a:  out std_logic_vector(13 downto 0);
        --bank
        cntrl0_ddr2_ba: out std_logic_vector(2 downto 0);
        cntrl0_ddr2_ras_n   :out std_logic;   
        cntrl0_ddr2_cas_n   :out std_logic;
        cntrl0_ddr2_we_n    :out std_logic;
        cntrl0_ddr2_cs_n    :out std_logic_vector(0 downto 0);
        cntrl0_ddr2_cs_n_cpy :out std_logic_vector(0 downto 0);
        cntrl0_ddr2_odt     :out std_logic_vector(0 downto 0);
        cntrl0_ddr2_odt_cpy :out std_logic_vector(0 downto 0);
        cntrl0_ddr2_cke     :out std_logic_vector(0 downto 0);
        cntrl0_ddr2_dm      :out std_logic_vector(3 downto 0);
        cntrl0_ddr2_dqs     :inout std_logic_vector(3 downto 0);
        cntrl0_ddr2_dqs_n   :inout std_logic_vector(3 downto 0);
        cntrl0_ddr2_ck      :out std_logic_vector(1 downto 0);
        cntrl0_ddr2_ck_n    :out std_logic_vector(1 downto 0)
    );
end top;

architecture Behavioral of top is

component DDR2
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
      cntrl0_ddr2_odt_cpy           : out   std_logic_vector(0 downto 0);
      cntrl0_ddr2_cke               : out   std_logic_vector(0 downto 0);
      cntrl0_ddr2_dm                : out   std_logic_vector(3 downto 0);
      sys_reset_in_n                : in    std_logic;
      cntrl0_init_done              : out   std_logic;
      cntrl0_clk_tb                 : out   std_logic;
      cntrl0_reset_tb               : out   std_logic;
      cntrl0_wdf_almost_full        : out   std_logic;
      cntrl0_af_almost_full         : out   std_logic;
      cntrl0_read_data_valid        : out   std_logic;
      cntrl0_app_wdf_wren           : in    std_logic;
      cntrl0_app_af_wren            : in    std_logic;
      cntrl0_burst_length_div2      : out   std_logic_vector(2 downto 0);
      cntrl0_app_af_addr            : in    std_logic_vector(35 downto 0);
      cntrl0_read_data_fifo_out     : out   std_logic_vector(63 downto 0);
      cntrl0_app_wdf_data           : in    std_logic_vector(63 downto 0);
      clk_0                         : in    std_logic;
      clk_90                        : in    std_logic;
      clk_200                       : in    std_logic;
      dcm_lock                      : in    std_logic;
      cntrl0_ddr2_dqs               : inout std_logic_vector(3 downto 0);
      cntrl0_ddr2_dqs_n             : inout std_logic_vector(3 downto 0);
      cntrl0_ddr2_ck                : out   std_logic_vector(1 downto 0);
      cntrl0_ddr2_ck_n              : out   std_logic_vector(1 downto 0)

);
end component;

	COMPONENT dcm2
	PORT(
		CLKIN_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLKFX_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic;
		CLK90_OUT : OUT std_logic;
		LOCKED_OUT : OUT std_logic
		);
	END COMPONENT;

    signal dcm_lock                      :std_logic;
    signal clk_90                        :std_logic;
    signal clk_200                       :std_logic;
    signal clk_50                        :std_logic;
    signal sys_reset                      :std_logic:='1';
    signal cntrl0_init_done              :std_logic;
    signal cntrl0_clk_tb                 :std_logic;
    signal cntrl0_reset_tb               :std_logic;
    signal cntrl0_wdf_almost_full        :std_logic;
    signal cntrl0_af_almost_full         :std_logic;
    signal cntrl0_read_data_valid        :std_logic;
    signal cntrl0_app_wdf_wren           :std_logic;
    signal cntrl0_app_af_wren            :std_logic;
    signal cntrl0_burst_length_div2      :std_logic_vector(2 downto 0);
    signal cntrl0_app_af_addr            :std_logic_vector(35 downto 0);
    signal cntrl0_read_data_fifo_out     :std_logic_vector(63 downto 0);
    signal cntrl0_app_wdf_data           :std_logic_vector(63 downto 0);

begin

u_DDR2 :DDR2
       port map (
      cntrl0_ddr2_dq                => cntrl0_ddr2_dq,
      cntrl0_ddr2_a                 => cntrl0_ddr2_a,
      cntrl0_ddr2_ba                => cntrl0_ddr2_ba,
      cntrl0_ddr2_ras_n             => cntrl0_ddr2_ras_n,
      cntrl0_ddr2_cas_n             => cntrl0_ddr2_cas_n,
      cntrl0_ddr2_we_n              => cntrl0_ddr2_we_n,
      cntrl0_ddr2_cs_n              => cntrl0_ddr2_cs_n,
      cntrl0_ddr2_cs_n_cpy              => cntrl0_ddr2_cs_n_cpy,
      cntrl0_ddr2_odt               => cntrl0_ddr2_odt,
      cntrl0_ddr2_odt_cpy               => cntrl0_ddr2_odt_cpy,
      cntrl0_ddr2_cke               => cntrl0_ddr2_cke,
      cntrl0_ddr2_dm                => cntrl0_ddr2_dm,
      sys_reset_in_n                => sys_reset,
      cntrl0_init_done              => cntrl0_init_done,
      cntrl0_clk_tb                 => cntrl0_clk_tb,
      cntrl0_reset_tb               => cntrl0_reset_tb,
      cntrl0_wdf_almost_full        => cntrl0_wdf_almost_full,
      cntrl0_af_almost_full         => cntrl0_af_almost_full,
      cntrl0_read_data_valid        => cntrl0_read_data_valid,
      cntrl0_app_wdf_wren           => cntrl0_app_wdf_wren,
      clk_0                         => clk_50,
      clk_90                        => clk_90,
      clk_200                       => clk_200,
      dcm_lock                      => dcm_lock,
      cntrl0_app_af_wren            => cntrl0_app_af_wren,
      cntrl0_burst_length_div2      => cntrl0_burst_length_div2,
      cntrl0_app_af_addr            => cntrl0_app_af_addr,
      cntrl0_read_data_fifo_out     => cntrl0_read_data_fifo_out,
      cntrl0_app_wdf_data           => cntrl0_app_wdf_data,
      cntrl0_ddr2_dqs               => cntrl0_ddr2_dqs,
      cntrl0_ddr2_dqs_n             => cntrl0_ddr2_dqs_n,
      cntrl0_ddr2_ck                => cntrl0_ddr2_ck,
      cntrl0_ddr2_ck_n              => cntrl0_ddr2_ck_n
);

	Inst_dcm2: dcm2
    PORT MAP(
		CLKIN_IN => i1_clk_pin,
		RST_IN => sys_reset,
		CLKFX_OUT => clk_200,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => clk_50,
        CLK90_OUT => clk_90,
		LOCKED_OUT => dcm_lock
	);

    main:process(clk_50) begin
        if sys_reset='1' then

        elsif rising_edge(clk_50) then

        end if;
    end process;

end Behavioral;

