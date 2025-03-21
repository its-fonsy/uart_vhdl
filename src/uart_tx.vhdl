library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
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
end entity uart_tx;

architecture RTL of uart_tx is

    -- FSM states type definition
    type fsm_state is (IDLE, START_BIT, DATA_TRANSMISSION, PARITY_BIT, STOP_BIT);

    -- Constants definition

    -- Signals
    signal cs, ns : fsm_state;
    signal cnt_count : unsigned(3 downto 0);
    signal cnt_enable : std_logic;
    signal parity : std_logic;
    signal cnt_reset : std_logic;
    signal sfr_load : std_logic;
    signal sfr_shift : std_logic;
    signal sfr_data : std_logic_vector(8 downto 0);
    signal packet_len : unsigned(3 downto 0);

begin

    -- FSM state register
    fsm_reg: process(clk) is
    begin
        if rstn = '0' then
            cs <= IDLE;
        elsif rising_edge(clk) then
            cs <= ns;
        end if;
    end process fsm_reg;

    packet_len_reg: process(rstn, clk, data_len) is
    begin
        if rstn = '0' then
            packet_len <= (others => '0');
        elsif rising_edge(clk) and (start = '1') then
            packet_len <= unsigned(data_len);
        end if;
    end process packet_len_reg;

    -- Parity bit register
    parity_reg: process(rstn, clk, parity_mode, start, data) is
    begin
        if rstn = '0' then
            parity <= '0';
        elsif rising_edge(clk) and (start = '1') then
            case parity_mode is
                when '0' => parity <= xor data;
                when '1' => parity <= not (xor data);
                when others => parity <= '0';
            end case;
        end if;
    end process parity_reg;

    -- Shift Register
    shift_reg: process(rstn, clk, sfr_load, sfr_shift) is
    begin
        -- Async Reset
        if rstn = '0' then
            sfr_data <= (others => '0');
        elsif rising_edge(clk) then
            if sfr_load = '1' then
                sfr_data <= data;
            elsif sfr_shift = '1' then
                sfr_data <= sfr_data srl 1;
            end if;
        end if;

    end process shift_reg;

    -- Counter
    counter_reg: process(rstn, clk, cnt_reset) is
    begin
        -- Async Reset
        if (rstn = '0') or (cnt_reset = '1') then
            cnt_count <= (others => '0');
        elsif rising_edge(clk) and (cnt_enable = '1') then
            cnt_count <= cnt_count + 1;
        end if;
    end process counter_reg;

    -- FSM datapath
    fsm_datapath: process(cs, start, cnt_count) is
    begin

        -- Default signals values
        cnt_enable <= '0';
        cnt_reset <= '0';
        sfr_load <= '0';
        sfr_shift <= '0';
        tx <= '1';
        busy <= '0';

        -- State switch case
        case cs is

            when IDLE =>
                if start = '1' then
                    ns <= START_BIT;
                else
                    ns <= IDLE;
                end if;

            when START_BIT =>
                busy <= '1';
                sfr_load <= '1';
                tx <= '0';
                cnt_enable <= '1';
                ns <= DATA_TRANSMISSION;

            when DATA_TRANSMISSION =>
                busy <= '1';
                cnt_enable <= '1';
                sfr_shift <= '1';
                tx <= sfr_data(0);
                ns <= DATA_TRANSMISSION;
                if cnt_count = packet_len then
                    ns <= PARITY_BIT;
                end if;

            when PARITY_BIT =>
                busy <= '1';
                cnt_reset <= '1';
                tx <= parity;
                ns <= STOP_BIT;

            when STOP_BIT =>
                busy <= '1';
                tx <= '1';
                ns <= IDLE;

            when others =>
                ns <= IDLE;

        end case;
    end process fsm_datapath;

end architecture RTL;
