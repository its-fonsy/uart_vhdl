library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;

use std.env.finish;

-- Empty entity for testbench
entity baud_rate_generator_tb is
end baud_rate_generator_tb;

architecture behav of baud_rate_generator_tb is

    -- Constants definition
    constant clock_frequency  : integer := 50e6;
    constant clock_period     : time := 1000 ms / clock_frequency;

    type baudrates_t is array (0 to 7) of string(1 to 6);
    signal baudrates : baudrates_t := ("      ", "9600  ", "19200 ", "28800 ", "38400 ", "57600 ", "76800 ", "115200");

    -- Components definitions
    component baud_rate_generator is
        generic (
                INPUT_CLK_FREQ : integer := 50e6
                );
        port (
                i_clk       : in    std_logic;
                rstn        : in    std_logic;
                baud_config : in    std_logic_vector(2 downto 0);
                o_clk_baud  : out   std_logic
             );
    end component baud_rate_generator;

    -- Signals definitions
    signal i_clk       : std_logic := '0';
    signal rstn        : std_logic;
    signal baud_config : std_logic_vector(2 downto 0);
    signal o_clk_baud  : std_logic;

begin

    -- Instantiate DUT
    dut: baud_rate_generator
        generic map(INPUT_CLK_FREQ => 50e6)
        port map(i_clk, rstn, baud_config, o_clk_baud);

    -- Clock
    i_clk <= not i_clk after clock_period / 2;

    -- Main simulation process
    stimuli: process is
        variable baud_period : time;
    begin

        -- Initialize the signals
        rstn <= '1';
        baud_config <= 3x"0";
        wait until falling_edge(i_clk);

        -- Reset the system
        rstn <= '0';
        wait until falling_edge(i_clk);
        rstn <= '1';

        -- Test every baud rate
        for i in 1 to 7 loop

            -- Set the baud rate configuration
            baud_config <= std_logic_vector(to_unsigned(i, baud_config'length));

            -- Wait for 10 baud rate period
            for k in 0 to 9 loop
                baud_period := now;
                wait until rising_edge(o_clk_baud);
                wait until falling_edge(o_clk_baud);
            end loop;

            -- Compute the baud rate period
            baud_period := now - baud_period;
            report baudrates(i) & " period: " & time'image(baud_period);

            -- Reset the baud generator
            wait until falling_edge(i_clk);
            baud_config <= (others => '0');
            wait until falling_edge(i_clk);

        end loop;

        wait for clock_period;

        report "Test finished";
        finish;

    end process;

end behav;
