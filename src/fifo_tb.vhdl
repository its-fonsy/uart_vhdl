library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.uniform;
use ieee.math_real.floor;

use std.env.finish;

-- Empty entity for testbench
entity fifo_tb is
end fifo_tb;

architecture behav of fifo_tb is

    -- Constants definition
    constant clock_frequency  : integer := 100e6;
    constant clock_period     : time := 1000 ms / clock_frequency;

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

    -- Signals definitions
    signal clk          : std_logic := '0';
    signal rstn         : std_logic;
    signal push         : std_logic;
    signal data_in      : std_logic_vector(9 downto 0);
    signal pop          : std_logic;
    signal data_out     : std_logic_vector(9 downto 0);
    signal data_ready   : std_logic;
    signal full         : std_logic;

begin

    -- Instantiate DUT
    dut: fifo
        generic map(DATA_WIDTH => 10, SIZE => 16)
        port map(clk, rstn, push, data_in, pop, data_out, data_ready, full);

    -- Clock
    clk <= not clk after clock_period / 2;

    -- Main simulation process
    stimuli: process is
        variable seed1 : positive;
        variable seed2 : positive;
        variable x : real;
        variable y : integer;
        variable n_data : integer;

        procedure push_random_data(
                                    signal clk : in std_logic;
                                    signal data_in : out std_logic_vector(9 downto 0)
                                ) is
        begin
            push <= '1';
            for n in 1 to n_data loop
                -- Generate random value
                uniform(seed1, seed2, x);
                y := integer(floor(x * 1024.0));

                -- Input random value
                data_in <= std_logic_vector(to_unsigned(y, 10));
                wait until falling_edge(clk);
            end loop;
            push <= '0';
        end procedure push_random_data;
    begin

        -- Initialize the signals
        rstn <= '1';
        push <= '0';
        pop <= '0';
        data_in <= 10B"00_0000_0000";
        wait until falling_edge(clk);

        -- Reset the system
        rstn <= '0';
        wait until falling_edge(clk);
        rstn <= '1';

        -- Pushing 10 random numbers
        n_data := 8;
        push_random_data(clk, data_in);
        wait until falling_edge(clk);

        -- Pop 5 items
        pop <= '1';
        wait for 5*clock_period;
        pop <= '0';

        wait for clock_period;

        n_data := 3;
        push_random_data(clk, data_in);
        wait until falling_edge(clk);

        report "Test finished";
        finish;

    end process;

end behav;
