library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.ceil;
use ieee.math_real.log2;

entity fifo is
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
end entity fifo;

architecture RTL of fifo is

    type memory_t is array(0 to SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Signals
    signal mem  :   memory_t;

begin
    -- Queue reg
    queue_reg: process(clk, rstn, push, pop, data_in) is
        variable push_ptr   : unsigned(integer(ceil(log2(real(SIZE))))-1 downto 0);
        variable pop_ptr    : unsigned(integer(ceil(log2(real(SIZE))))-1 downto 0);
        variable count      : integer range 0 to SIZE;
        variable empty      : boolean;
    begin
        if rstn = '0' then
            push_ptr := (others => '0');
            pop_ptr := (others => '0');
            count := 0;
            empty := true;
            data_out <= (others => '0');

            -- Reset the memory
            for i in 0 to SIZE-1 loop
                mem(i) <= (others => '1');
            end loop;
        elsif rising_edge(clk) then
            data_ready <= '0';
            empty := (count = 0);
            if (push = '1') and (full = '0') then
                mem(to_integer(push_ptr)) <= data_in;
                count := count + 1;
                push_ptr := push_ptr + 1;
            elsif (pop = '1') and not empty then
                data_out <= mem(to_integer(pop_ptr));
                data_ready <= '1';
                count := count - 1;
                pop_ptr := pop_ptr + 1;
            end if;
        end if;

        if count = SIZE then
            full <= '1';
        else
            full <= '0';
        end if;
    end process queue_reg;

end architecture RTL;
