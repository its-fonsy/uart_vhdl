library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baud_rate_generator is
    generic (
            INPUT_CLK_FREQ : integer := 50e6
            );
    port (
            i_clk       : in    std_logic;
            rstn        : in    std_logic;
            baud_config : in    std_logic_vector(2 downto 0);
            o_clk_baud  : out   std_logic
         );
end entity baud_rate_generator;

architecture RTL of baud_rate_generator is
begin

    baud_generator: process(i_clk, rstn, baud_config) is
        variable count : integer;
        variable max_count : integer;
    begin
        if rstn = '0' then
            count := 0;
            o_clk_baud <= '0';
        elsif rising_edge(i_clk) then

            -- Check the configuration
            case baud_config is
                when 3x"0" => max_count := 0;
                when 3x"1" => max_count := INPUT_CLK_FREQ / 9600;
                when 3x"2" => max_count := INPUT_CLK_FREQ / 19200;
                when 3x"3" => max_count := INPUT_CLK_FREQ / 28800;
                when 3x"4" => max_count := INPUT_CLK_FREQ / 38400;
                when 3x"5" => max_count := INPUT_CLK_FREQ / 57600;
                when 3x"6" => max_count := INPUT_CLK_FREQ / 76800;
                when 3x"7" => max_count := INPUT_CLK_FREQ / 115200;
                when others => max_count := 0;
            end case;

            if max_count = 0 then
                o_clk_baud <= '0';
                count := 0;
            elsif count > (max_count / 2) then
                o_clk_baud <= not o_clk_baud;
                count := 0;
            end if;

            count := count + 1;

        end if;
    end process baud_generator;

end architecture RTL;
