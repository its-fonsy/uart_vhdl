library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.finish;

-- Empty entity for testbench
entity uart_tb is
    end uart_tb;

architecture behav of uart_tb is

    -- Constants definition
    constant clock_frequency  : integer := 50e6;
    constant clock_period     : time := 1000 ms / clock_frequency;

    -- Component definition
    component uart is
        generic (
                INPUT_CLK_FREQ  : integer := 50e6;
                TX_FIFO_SIZE    : integer := 8;
                RX_FIFO_SIZE    : integer := 8
                );
        port (
                -- Clock and Reset
                clk             : in    std_logic;
                rstn            : in    std_logic;

                -- UART configuration signal
                baud_rate       : in    std_logic_vector(2 downto 0);
                data_parity     : in    std_logic;
                data_len        : in    std_logic_vector(3 downto 0);

                -- UART TX signals
                tx_data         : in    std_logic_vector(8 downto 0);
                tx_data_ready   : in    std_logic;
                tx_fifo_full    : out   std_logic;

                -- UART RX signals
                rx_data         : out   std_logic_vector(9 downto 0);
                rx_data_ready   : out   std_logic;
                rx_data_request : in    std_logic;
                rx_fifo_full    : out   std_logic;

                -- UART TX and UART RX signals
                rx              : in    std_logic;
                tx              : out   std_logic
             );
    end component uart;

    -- Signals definitions
    signal clk              : std_logic := '0';
    signal rstn             : std_logic;
    signal baud_rate        : std_logic_vector(2 downto 0);
    signal data_parity      : std_logic;
    signal data_len         : std_logic_vector(3 downto 0);
    signal tx_data          : std_logic_vector(8 downto 0);
    signal tx_data_ready    : std_logic;
    signal tx_fifo_full     : std_logic;
    signal rx_data          : std_logic_vector(9 downto 0);
    signal rx_data_ready    : std_logic;
    signal rx_data_request  : std_logic;
    signal rx_fifo_full     : std_logic;
    signal rx               : std_logic;
    signal tx               : std_logic;

begin

    dut: uart port map(
                        clk,
                        rstn,
                        baud_rate,
                        data_parity,
                        data_len,
                        tx_data,
                        tx_data_ready,
                        tx_fifo_full,
                        rx_data,
                        rx_data_ready,
                        rx_data_request,
                        rx_fifo_full,
                        rx,
                        tx
                      );


    -- Clock process
    clk <= not clk after clock_period / 2;

    -- Main simulation process
    stimuli: process is
    begin

        -- Initialize the signals
        baud_rate <= 3x"1";
        data_parity <= '0';
        data_len <= x"8";
        tx_data <= 9x"000";
        tx_data_ready <= '0';
        rx_data_request <= '0';
        rx <= '0';
        rstn <= '1';
        wait until falling_edge(clk);

        -- Reset the system
        rstn <= '0';
        wait until falling_edge(clk);
        rstn <= '1';

        report "Test finished";
        finish;

    end process;

end behav;
