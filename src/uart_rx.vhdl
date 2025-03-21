library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (
            clk         : in    std_logic;
            rstn        : in    std_logic;
            -- Accepted value are 5 to 9
            data_len    : in    std_logic_vector(3 downto 0);
            rx          : in    std_logic;
            data_ready  : out   std_logic;
            data        : out   std_logic_vector(9 downto 0)
         );
end entity uart_rx;

architecture RTL of uart_rx is

    -- FSM states type definition
    type fsm_state is (IDLE, DATA_TRANSMISSION, PARITY_BIT, STOP_BIT, ERROR_STOP);

    -- Constants definition

    -- Signals
    signal cs, ns       : fsm_state;
    signal cnt_count    : unsigned(3 downto 0);
    signal cnt_enable   : std_logic;
    signal cnt_reset    : std_logic;
    signal sfr_reset    : std_logic;
    signal sfr_shift    : std_logic;
    signal sfr_data     : std_logic_vector(9 downto 0);

begin

    data <= sfr_data;

    -- Shift Register
    shift_reg: process(rstn, clk, sfr_reset, sfr_shift) is
    begin
        -- Async Reset
        if rstn = '0' then
            sfr_data <= (others => '0');
        elsif rising_edge(clk) then
            if sfr_reset = '1' then
                sfr_data <= (others => '0');
            elsif sfr_shift = '1' then
                sfr_data <= sfr_data srl 1;
                sfr_data(9) <= rx;
            end if;
        end if;
    end process shift_reg;

    -- Counter
    counter_reg: process(rstn, clk, cnt_reset, cnt_enable) is
    begin
        -- Async Reset
        if rstn = '0' then
            cnt_count <= (others => '0');
        elsif rising_edge(clk) then
            if cnt_reset = '1' then
                cnt_count <= (others => '0');
            elsif cnt_enable = '1' then
                cnt_count <= cnt_count + 1;
            end if;
        end if;
    end process counter_reg;

    -- FSM state register
    fsm_reg: process(clk) is
    begin
        if rstn = '0' then
            cs <= IDLE;
        elsif rising_edge(clk) then
            cs <= ns;
        end if;
    end process fsm_reg;

    -- FSM datapath
    fsm_datapath: process(cs, cnt_count, rx) is
    begin

        -- Default signals values
        cnt_enable <= '0';
        cnt_reset <= '0';
        sfr_reset <= '0';
        sfr_shift <= '0';
        data_ready <= '0';

        -- State switch case
        case cs is

            when IDLE =>
                if rx = '0' then
                    ns <= DATA_TRANSMISSION;
                    sfr_reset <= '1';
                else
                    ns <= IDLE;
                end if;

            when DATA_TRANSMISSION =>
                cnt_enable <= '1';
                sfr_shift <= '1';
                ns <= DATA_TRANSMISSION;
                if cnt_count = unsigned(data_len) then
                    ns <= PARITY_BIT;
                end if;

            when PARITY_BIT =>
                sfr_shift <= '1';
                cnt_reset <= '1';
                ns <= STOP_BIT;

            when STOP_BIT =>
                data_ready <= '1';
                if rx = '1' then
                    ns <= IDLE;
                else
                    ns <= ERROR_STOP;
                end if;

            when ERROR_STOP =>
                if rx = '0' then
                    ns <= ERROR_STOP;
                else
                    ns <= IDLE;
                end if;

            when others =>
                ns <= IDLE;

        end case;
    end process fsm_datapath;

end architecture RTL;
