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

    -- Function that return the Baud rate period based on the baud_conf vector

    pure function get_baud_period(baud_conf: std_logic_vector(2 downto 0)) return time is
    begin

        -- Check the baud rate configuration

        case baud_conf is
            when 3x"0" => return 1 fs;
            when 3x"1" => return (1 sec) / 9600;
            when 3x"2" => return (1 sec) / 19200;
            when 3x"3" => return (1 sec) / 28800;
            when 3x"4" => return (1 sec) / 38400;
            when 3x"5" => return (1 sec) / 57600;
            when 3x"6" => return (1 sec) / 76800;
            when 3x"7" => return (1 sec) / 115200;
            when others => return 1 fs;
        end case;

    end function;

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

    -- DUT signals definition

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

    -- Test scheduler signals definition

    signal test_tx_start    : boolean := false;
    signal test_rx_start    : boolean := false;
    signal test_tx_finished : boolean := false;
    signal test_rx_finished : boolean := false;

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

    -- Process that test the UART transmitter

    test_uart_transmitter: process is

        -- Variables definitions

        variable test_data : std_logic_vector(8 downto 0);
        variable test_parity_mode : std_logic;
        variable seed1, seed2 : positive := 492;

        -- Function that generate random bit

        impure function random_bit return std_logic is
            variable r      : real;
            variable bit    : std_logic;
        begin
            uniform(seed1, seed2, r);
            bit := '1' when r > 0.5 else '0';
            return bit;
        end function;

        -- Function that generate random vector for UART transmitter

        impure function random_tx_vector(len: integer) return std_logic_vector is
            variable vector : std_logic_vector(8 downto 0);
        begin

            -- Set all bit to 0

            vector := (others => '0');

            -- Generate random bit for the appropiate length

            for i in 0 to len-1 loop
                vector(i) := random_bit;
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
            baud_period := get_baud_period(baud_rate);

            -- Wait for START bit

            wait until falling_edge(tx);

            -- Delay half-period to Fetch data on falling edge of the baud rate clock

            wait for baud_period / 2;

            -- Check transmitted DATA

            for i in 0 to data_length loop
                wait for baud_period;
                assert tx = test_data(i)
                    report "Error on " & integer'image(i) & " bit"
                    severity error;
            end loop;

            -- Check PARITY bit ('0' = EVEN, '1' = ODD)

            wait for baud_period;
            case test_parity_mode is
                when '0' => assert tx = (xor test_data) report "Error on even PARITY bit" severity error;
                when '1' => assert tx = (not (xor test_data)) report "Error on odd PARITY bit" severity error;
                when others => report "ERROR: parity mode not set." severity error;
            end case;

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

        data_len <= (others => 'Z');
        baud_rate <= (others => 'Z');

        wait until test_tx_start;

        -- Test every baud rate configuration

        report "Starting UART TX test";
        for baud_conf in 1 to 7 loop

            baud_rate <= std_logic_vector(to_unsigned(baud_conf, 3));

            -- Test every data length configuration

            for dl in 5 to 9 loop

                data_len <= std_logic_vector(to_unsigned(dl, 4));

                -- For each baudrate/data_length combination test 10 random values

                for n in 0 to 9 loop

                    -- Generate random data

                    test_data := random_tx_vector(dl);
                    test_parity_mode := random_bit;

                    -- Test UART TX with generated data

                    data_parity <= test_parity_mode;
                    load_tx(clk, tx_data, tx_data_ready);
                    read_tx(tx, baud_rate, data_len);
                end loop;
            end loop;
        end loop;
        report "Finished UART TX test";

        wait for clock_period;

        -- TX test finished, disconnect from non-TX input signals and wait

        data_len <= (others => 'Z');
        baud_rate <= (others => 'Z');
        test_tx_finished <= true;

        wait;

    end process;

    test_uart_receiver: process is

        -- Variables definitions

        variable test_data          : std_logic_vector(9 downto 0);
        variable test_parity_mode   : std_logic;
        variable seed1, seed2       : positive := 415320;

        -- Function that generate random bit

        impure function random_bit return std_logic is
            variable r      : real;
            variable bit    : std_logic;
        begin
            uniform(seed1, seed2, r);
            bit := '1' when r > 0.5 else '0';
            return bit;
        end function;

        -- Function that generate random value input RX vector

        impure function random_rx_vector(len: integer) return std_logic_vector is
            variable vector : std_logic_vector(9 downto 0);
        begin
            -- Zero the vector

            vector := (others => '0');

            -- Generate random vector for the required length

            for i in 0 to len-1 loop
                vector(i) := random_bit;
            end loop;

            -- Parity bit

            vector(len) := (xor vector) when test_parity_mode = '0' else (not (xor vector));

            return vector;

        end function;

        -- Function that generate random delay based on baud rate configuration

        impure function random_delay(baud_conf: std_logic_vector(2 downto 0)) return time is
            variable r, r_scaled, min_real, max_real    : real;
            variable baud_period                        : time;
            variable debug                              : boolean := false;
        begin
            baud_period := get_baud_period(baud_conf);
            uniform(seed1, seed2, r);
            min_real := real((baud_period * 0.1) / 1 ps);
            max_real := real((baud_period * 0.9) / 1 ps);
            r_scaled := r * ( max_real - min_real ) + min_real;

            if debug then
                report  "Baud period = " & time'image(baud_period) &
                        " -> Random delay = " & time'image(r_scaled * 1 ps);
            end if;

            return real(r_scaled) * 1 ps;
        end function;

        -- Procedure that simulate the RX of UART

        procedure uart_tx(
                    signal rx           : out   std_logic;
                    signal baud_rate    : in    std_logic_vector(2 downto 0);
                    signal data_len     : in    std_logic_vector(3 downto 0)
        ) is
            variable baud_period    : time;
            variable data_length    : integer;
            variable debug          : boolean := false;
        begin
            baud_period := get_baud_period(baud_rate);
            data_length := to_integer(unsigned(data_len));

            -- START condition

            rx <= '0';

            if debug then
                report "(0x" & to_hstring(test_data) & ") START BIT -> 0";
            end if;

            wait for baud_period;

            -- DATA transmission

            for i in 0 to data_length-1 loop
                rx <= test_data(i);

                if debug then
                    report "(0x" & to_hstring(test_data) & ") BIT " & integer'image(i)
                            & " -> " & to_string(test_data(i));
                end if;

                wait for baud_period;
            end loop;

            -- PARITY bit

            rx <= test_data(data_length);

            if debug then
                report "(0x" & to_hstring(test_data) & ") PARITY BIT -> " & to_string(test_data(data_length));
            end if;

            wait for baud_period;

            -- STOP bit

            rx <= '1';

            if debug then
                report "(0x" & to_hstring(test_data) & ") STOP BIT -> 1";
            end if;

            wait for baud_period;

        end procedure uart_tx;

    begin

        -- Default signal values

        rx_data_request <= 'Z';
        rx <= 'Z';
        data_len <= (others => 'Z');
        baud_rate <= (others => 'Z');

        -- Wait for start RX signal

        wait until test_rx_start;

        -- Start the receiver test

        report "Starting UART RX test";
        rx_data_request <= '0';
        rx <= '1';
        wait for clock_period;

        --  Test every baud rate configuration

        for baud_conf in 1 to 7 loop

            baud_rate <= std_logic_vector(to_unsigned(baud_conf, 3));

            --  Test every data length configuration

            for len in 5 to 9 loop
                data_len <= std_logic_vector(to_unsigned(len, 4));

                -- For each baud/len combination test receiver with 10 random values

                for n in 0 to 9 loop

                    -- Generate random value

                    test_parity_mode := random_bit;
                    test_data := random_rx_vector(len);

                    -- Wait for random delay proportional to the baud rate

                    wait for random_delay(baud_rate);

                    -- Send data and wait for its complete reception

                    uart_tx(rx, baud_rate, data_len);
                    rx_data_request <= '1';
                    wait until rising_edge(rx_data_ready);

                    -- Assert correcteness of the received data
                    
                    assert rx_data = test_data
                        report "Wrong data" 
                                & " BAUD=" & to_hstring(baud_rate)
                                & " LEN=" & integer'image(len)
                                & " PARITY=" & to_string(test_parity_mode)
                                & " SENT=0x" & to_hstring(test_data)
                                & " RECV=0x" & to_hstring(rx_data)
                        severity error;

                    -- Acknowledge that data has been read

                    wait until falling_edge(clk);
                    rx_data_request <= '0';

                end loop;
            end loop;
        end loop;

        report "Finished UART RX test";
        test_rx_finished <= true;
        wait;
    end process;

    test_scheduler: process is
    begin

        -- Initialize the input signals

        baud_rate <= (others => '0');
        data_parity <= '0';
        data_len <= (others => '0');
        tx_data <= (others => '0');
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

        -- Disconnect from the TX input signals

        baud_rate <= (others => 'Z');
        data_parity <= 'Z';
        data_len <= (others => 'Z');
        tx_data <= (others => 'Z');
        tx_data_ready <= 'Z';

        -- Start and wait for the TX test end

        test_tx_start <= true;
        wait until test_tx_finished;

        -- Disconnect from the RX input signals

        rx_data_request <= 'Z';
        rx <= 'Z';

        -- Start and wait for the UART RX test end

        test_rx_start <= true;
        wait until test_rx_finished;

        report "All test finished";
        finish;

    end process;

end behav;
