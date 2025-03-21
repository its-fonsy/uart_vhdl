library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;

-- Empty entity for testbench
entity uart_rx_tb is
    end uart_rx_tb;

architecture behav of uart_rx_tb is

    -- Constants definition
    constant clock_frequency  : integer := 100e6;
    constant clock_period     : time := 1000 ms / clock_frequency;

    -- Component definition
    component uart_rx is
        port (
                clk         : in    std_logic;
                rstn        : in    std_logic;
                -- Accepted value are 5 to 9
                data_len    : in    std_logic_vector(3 downto 0);
                rx          : in    std_logic;
                data_ready  : out   std_logic;
                data        : out   std_logic_vector(9 downto 0)
             );
    end component uart_rx;

    -- Signals definitions
    signal clk          : std_logic := '0';
    signal rstn         : std_logic;
    signal data_len     : std_logic_vector(3 downto 0);
    signal rx           : std_logic;
    signal data_ready   : std_logic;
    signal data         : std_logic_vector(9 downto 0);

begin

    dut: uart_rx port map(clk, rstn, data_len, rx, data_ready, data);

    -- Clock
    clk <= not clk after clock_period / 2;

    -- Main simulation process
    stimuli: process is

        variable test_data   : std_logic_vector(8 downto 0);

        procedure uart_tx(
                    signal rx   : out   std_logic;
                    signal clk  : in    std_logic
        ) is
            variable parity : std_logic;
        begin
            parity := xor test_data;

            -- Start condition
            rx <= '0';
            wait until falling_edge(clk);

            -- Byte transmission
            for i in 0 to (to_integer(unsigned(data_len)) - 1) loop
                rx <= test_data(i);
                wait until falling_edge(clk);
            end loop;

            -- Parity bit
            rx <= parity;
            wait until falling_edge(clk);

            -- Stop bit
            rx <= '1';
            wait until falling_edge(clk);

        end procedure uart_tx;

    begin

        -- Initialize the signals
        rstn <= '1';
        rx <= '1';
        wait until falling_edge(clk);

        -- Reset the system
        rstn <= '0';
        wait until falling_edge(clk);
        rstn <= '1';

        wait until falling_edge(clk);

        -- Send 8-bit data length
        data_len <= x"8";
        test_data := b"0_1101_0100";
        wait for 1 ps;
        uart_tx(rx, clk);

        wait for 2*clock_period;

        -- Send 9-bit data length
        data_len <= x"9";
        test_data := b"1_1110_0100";
        wait for 1 ps;
        uart_tx(rx, clk);

        wait for 2*clock_period;

        -- Send 5-bit data length
        data_len <= x"5";
        test_data := b"0_0001_1001";
        wait for 1 ps;
        uart_tx(rx, clk);

        wait for 2*clock_period;

        report "Test finished";
        finish;

    end process;

end behav;
