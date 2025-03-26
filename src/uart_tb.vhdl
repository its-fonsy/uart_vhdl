library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;

use std.env.finish;

-- Empty entity for testbench
entity uart_tb is
    end uart_tb;

architecture behav of uart_tb is

    -- Constants definition
    constant clock_frequency  : integer := 50e6;
    constant clock_period     : time := 1 sec / clock_frequency;

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

    dut: uart
    generic map (
                INPUT_CLK_FREQ  => clock_frequency,
                TX_FIFO_SIZE    => 8,
                RX_FIFO_SIZE    => 8
                )
    port map(
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

    -- Process that test the transmission of the UART
    test_uart_transmission: process is

        -- Variables definitions
        variable test_data : std_logic_vector(8 downto 0);
        variable test_parity_mode : std_logic;
        variable seed1, seed2 : positive := 492;

        -- Function that generate random value input TX vector
        impure function random_vector(len: integer) return std_logic_vector is
            variable r      : real;
            variable vector : std_logic_vector(8 downto 0);
        begin

            -- Set al bit to 0
            vector := (others => '0');

            -- Generate random bit for the appropiate length
            for i in 0 to len-1 loop
                uniform(seed1, seed2, r);
                vector(i) := '1' when r > 0.5 else '0';
            end loop;

            return vector;

        end function;

        -- Procedure that assert correctness of the transmitted data
        procedure read_tx   (
                            signal tx           : in    std_logic;
                            signal baud_rate    : in    std_logic_vector(2 downto 0);
                            signal data_len     : in    std_logic_vector(3 downto 0)
                            ) is
            variable data_length    : integer;
            variable baud_period    : time;
        begin
            data_length:= to_integer(unsigned(data_len)) - 1;

            -- Check the baud rate configuration
            case baud_rate is
                when 3x"0" => baud_period := 1 fs;
                when 3x"1" => baud_period := (1 sec) / 9600;
                when 3x"2" => baud_period := (1 sec) / 19200;
                when 3x"3" => baud_period := (1 sec) / 28800;
                when 3x"4" => baud_period := (1 sec) / 38400;
                when 3x"5" => baud_period := (1 sec) / 57600;
                when 3x"6" => baud_period := (1 sec) / 76800;
                when 3x"7" => baud_period := (1 sec) / 115200;
                when others => baud_period := 1 fs;
            end case;

            -- Wait for START bit
            wait until falling_edge(tx);
            -- Delay half-period to Fetch data on falling edge of the baud rate clock
            wait for baud_period / 2;

            -- Check sent data
            for i in 0 to data_length loop
                wait for baud_period;
                assert tx = test_data(i)
                    report "Error on " & integer'image(i) & " bit"
                    severity error;
            end loop;

            -- Check parity bit
            wait for baud_period;
            if test_parity_mode = '0' then
                -- even parity
                assert tx = (xor test_data) report "Error on even PARITY bit" severity error;
            else
                -- odd parity
                assert tx = (not(xor test_data)) report "Error on odd PARITY bit" severity error;
            end if;

            -- Check STOP bit
            wait for baud_period;
            assert tx = '1' report "Error on STOP bit" severity error;

            -- Wait for busy = '0'
            wait for baud_period;

        end procedure read_tx;

        -- Procedure to load test data to the TX fifo
        procedure load_tx (
                            signal clk              : in    std_logic;
                            signal tx_data          : out   std_logic_vector(8 downto 0);
                            signal tx_data_ready    : out   std_logic
                          ) is
        begin
            wait until falling_edge(clk);
            tx_data <= test_data;
            tx_data_ready <= '1';
            wait until falling_edge(clk);
            tx_data_ready <= '0';
        end procedure load_tx;

    begin

        -- Initialize all the signals
        baud_rate <= 3x"0";
        data_parity <= '0';
        data_len <= x"8";
        tx_data <= 9x"000";
        tx_data_ready <= '0';
        rx_data_request <= '0';
        rx <= '1';
        rstn <= '1';
        wait until falling_edge(clk);

        -- Reset the system
        rstn <= '0';
        wait until falling_edge(clk);
        rstn <= '1';

        wait until falling_edge(clk);

        -- Test every baud rate configuration
        for baud_conf in 1 to 7 loop

            baud_rate <= std_logic_vector(to_unsigned(baud_conf, 3));

            -- Test every data length configuration
            for dl in 5 to 9 loop

                data_len <= std_logic_vector(to_unsigned(dl, 4));

                -- For each baudrate/data_length combo test 10 random values
                for n in 0 to 9 loop

                    -- Generate random data
                    test_data := random_vector(dl);
                    test_parity_mode := test_data(2);

                    -- Test UART TX with generated data
                    data_parity <= test_parity_mode;
                    load_tx(clk, tx_data, tx_data_ready);
                    read_tx(tx, baud_rate, data_len);
                end loop;
            end loop;
        end loop;

        wait for 10 * clock_period;
        report "Test finished";
        finish;

    end process;

end behav;
