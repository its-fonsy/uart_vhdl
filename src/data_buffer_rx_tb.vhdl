library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;

use std.env.finish;

-- Empty entity for testbench
entity data_buffer_rx_tb is
end data_buffer_rx_tb;

architecture behav of data_buffer_rx_tb is

    -- Constants definition
    constant clock_frequency        : integer := 100e6;
    constant clock_period           : time := 1000 ms / clock_frequency;
    constant baud_rate_frequency    : integer := 9600;
    constant baud_rate_period       : time := 1000 ms / baud_rate_frequency;
    constant dw                     : integer := 10;

    -- Components definitions
    component fifo is
        generic (
                DATA_WIDTH  : integer   := 8;
                SIZE        : integer   := 8
                );
        port (
                clk         : in    std_logic;
                rstn        : in    std_logic;
                push        : in    std_logic;
                data_in     : in    std_logic_vector(DATA_WIDTH-1 downto 0);
                pop         : in    std_logic;
                data_out    : out   std_logic_vector(DATA_WIDTH-1 downto 0);
                data_ready  : out   std_logic;
                full        : out   std_logic
             );
    end component fifo;

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

    component data_buffer is
        generic (
                DATA_WIDTH : integer := 8
                );
        port (
                rstn                : in    std_logic;
                data_in             : in    std_logic_vector(DATA_WIDTH-1 downto 0);
                data_in_clk         : in    std_logic;
                data_in_valid       : in    std_logic;
                data_in_request     : out   std_logic;
                data_out            : out   std_logic_vector(DATA_WIDTH-1 downto 0);
                data_out_clk        : in    std_logic;
                data_out_valid      : out   std_logic;
                data_out_request    : in    std_logic
             );
    end component data_buffer;

    signal clk              : std_logic := '0';
    signal rstn             : std_logic;

    -- UART TX signals
    signal baud_clk         : std_logic := '0';
    signal rx_data_len      : std_logic_vector(3 downto 0);
    signal rx               : std_logic;
    signal rx_data_ready    : std_logic;
    signal rx_data          : std_logic_vector(9 downto 0);

    -- Fifo signals
    signal fifo_push        : std_logic;
    signal fifo_pop         : std_logic;
    signal fifo_data_ready  : std_logic;
    signal fifo_full        : std_logic;
    signal fifo_data_in     : std_logic_vector(dw-1 downto 0);
    signal fifo_data_out    : std_logic_vector(dw-1 downto 0);

begin

    -- Instantiate FIFO
    fifo0: fifo
        generic map(
                DATA_WIDTH => dw,
                SIZE => 8
                   )
        port map(
                clk => clk,
                rstn => rstn,
                push => fifo_push,
                data_in => fifo_data_in,
                pop => fifo_pop,
                data_out => fifo_data_out,
                data_ready => fifo_data_ready,
                full => fifo_full
                );

    tx0: uart_rx
        port map(
                clk => baud_clk,
                rstn => rstn,
                data_len => rx_data_len,
                rx => rx,
                data_ready => rx_data_ready,
                data => rx_data 
                );

    dut: data_buffer
        generic map(
                DATA_WIDTH => dw
                    )
        port map(
                rstn => rstn,
                data_in => rx_data,
                data_in_clk => baud_clk,
                data_in_valid => rx_data_ready,
                data_in_request => open,
                data_out => fifo_data_in,
                data_out_clk => clk,
                data_out_valid => fifo_push,
                data_out_request => '1'
                );

    -- Clock
    clk <= not clk after clock_period / 2;
    baud_clk <= not baud_clk after baud_rate_period / 2;

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
            for i in 0 to (to_integer(unsigned(rx_data_len)) - 1) loop
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
        fifo_pop <= '0';
        rstn <= '1';
        rx_data_len <= 4x"8";
        wait until falling_edge(clk);

        -- Reset the system
        rstn <= '0';
        wait until falling_edge(clk);
        rstn <= '1';

        rx_data_len <= 4x"8";
        test_data := 9x"0A4";
        wait for 1 ps;
        uart_tx(rx, baud_clk);

        wait for 2*baud_rate_period;

        wait until falling_edge(baud_clk);
        test_data := 9x"18F";
        wait for 1 ps;
        uart_tx(rx, baud_clk);

        wait for 2*baud_rate_period;

        report "Test finished";
        finish;

    end process;

end behav;
