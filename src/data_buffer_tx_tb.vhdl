library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;

use std.env.finish;

-- Empty entity for testbench
entity data_buffer_tx_tb is
end data_buffer_tx_tb;

architecture behav of data_buffer_tx_tb is

    -- Constants definition
    constant clock_frequency        : integer := 100e6;
    constant clock_period           : time := 1000 ms / clock_frequency;
    constant baud_rate_frequency    : integer := 9600;
    constant baud_rate_period       : time := 1000 ms / baud_rate_frequency;
    constant dw                     : integer := 9;

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
    end component uart_tx;

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
    signal tx_start         : std_logic;
    signal tx_parity        : std_logic;
    signal tx_data_len      : std_logic_vector(3 downto 0);
    signal tx_data          : std_logic_vector(8 downto 0);
    signal tx               : std_logic;
    signal tx_busy          : std_logic;

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

    tx0: uart_tx
        port map(
                clk => baud_clk,
                rstn => rstn,
                start => tx_start,
                parity_mode => tx_parity,
                data_len => tx_data_len,
                data => tx_data,
                tx => tx,
                busy => tx_busy
                );

    dut: data_buffer
        generic map(
                DATA_WIDTH => dw
                    )
        port map(
                rstn => rstn,
                data_in => fifo_data_out,
                data_in_clk => clk,
                data_in_valid => fifo_data_ready,
                data_in_request => fifo_pop,
                data_out => tx_data,
                data_out_clk => baud_clk,
                data_out_valid => tx_start,
                data_out_request => not tx_busy
                );

    -- Clock
    clk <= not clk after clock_period / 2;
    baud_clk <= not baud_clk after baud_rate_period / 2;

    -- Main simulation process
    stimuli: process is
    begin

        -- Initialize the signals
        rstn <= '1';
        tx_data_len <= 4x"8";
        tx_parity <= '0';
        wait until falling_edge(clk);

        -- Reset the system
        rstn <= '0';
        wait until falling_edge(clk);
        rstn <= '1';

        fifo_data_in <= 9x"012";
        fifo_push <= '1';
        wait until falling_edge(clk);
        fifo_data_in <= 9x"123";
        wait until falling_edge(clk);
        fifo_data_in <= 9x"08C";
        wait until falling_edge(clk);
        fifo_push <= '0';

        wait until falling_edge(tx_busy);
        for i in 1 to 10 loop
            wait until rising_edge(baud_clk);
        end loop;

        fifo_data_in <= 9x"021";
        fifo_push <= '1';
        wait until falling_edge(clk);
        fifo_push <= '0';

        wait until falling_edge(clk);

        fifo_data_in <= 9x"0A8";
        fifo_push <= '1';
        wait until falling_edge(clk);
        fifo_push <= '0';

        wait until falling_edge(tx_busy);
        for i in 1 to 10 loop
            wait until rising_edge(baud_clk);
        end loop;

        report "Test finished";
        finish;

    end process;

end behav;
