library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;

-- Empty entity for testbench
entity uart_tx_tb is
    end uart_tx_tb;

architecture behav of uart_tx_tb is

    -- Constants definition
    constant clock_frequency  : integer := 100e6;
    constant clock_period     : time := 1000 ms / clock_frequency;

    -- Component definition
    component uart_tx is
        port (
                clk         : in    std_logic;
                rstn        : in    std_logic;
                start       : in    std_logic;
                -- 0 = even, 1 = odd
                parity_mode : in    std_logic;
                -- Accepted value are 5 to 9
                data_len    : in    std_logic_vector(3 downto 0);
                data        : in    std_logic_vector(8 downto 0);
                tx          : out   std_logic;
                busy        : out   std_logic
             );
    end component;

    -- Signals definitions
    signal clk          : std_logic := '0';
    signal rstn         : std_logic;
    signal start        : std_logic;
    signal parity_mode  : std_logic;
    signal data_len     : std_logic_vector(3 downto 0);
    signal data         : std_logic_vector(8 downto 0);
    signal tx           : std_logic;
    signal busy         : std_logic;

begin

    dut: uart_tx port map(clk, rstn, start, parity_mode, data_len, data, tx, busy);

    -- Clock
    clk <= not clk after clock_period / 2;

    -- Main simulation process
    stimuli: process is
    begin

        -- Initialize the signals
        rstn <= '1';
        start <= '0';
        wait until falling_edge(clk);

        -- Reset the system
        rstn <= '0';
        wait until falling_edge(clk);
        rstn <= '1';

        -- Test even parity
        data <= "000011100";
        data_len <= X"5";
        parity_mode <= '0';
        wait for 1 ps;
        start <= '1';
        wait until falling_edge(clk);
        start <= '0';

        wait for 11 * clock_period;

        -- Test odd parity
        data <= "010110110";
        data_len <= X"9";
        parity_mode <= '1';
        wait for 1 ps;
        start <= '1';
        wait until falling_edge(clk);
        start <= '0';

        wait for 11 * clock_period;

        report "Test finished";
        finish;

    end process;

end behav;
