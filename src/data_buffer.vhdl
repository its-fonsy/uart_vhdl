library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_buffer is
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
end entity data_buffer;

architecture RTL of data_buffer is

    -- FSM states type definition
    type fsm_state_data_in_t is (DI_WAIT_FOR_DO_REQ, DI_REQUEST_DATA, DI_LOAD_DATA_REG, DI_WAIT_FOR_DO_LOAD);
    type fsm_state_data_out_t is (DO_WAIT_VALID_DATA_REG, DO_LOAD_DATA_OUT, DO_DATA_LOADED);

    -- Signals
    signal di_cs, di_ns     : fsm_state_data_in_t;
    signal do_cs, do_ns     : fsm_state_data_out_t;
    signal data_reg_load    : std_logic;
    signal data_reg_valid   : std_logic;
    signal data_out_loaded  : std_logic;

begin

    data_register: process(data_in_clk, rstn) is
        variable data : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        if rstn = '0' then
            data := (others => '0');
        elsif rising_edge(data_in_clk) then
            data := data_in;
        end if;
        data_out <= data;
    end process data_register;

    -- FSM data_in register
    di_fsm_reg: process(data_in_clk, rstn) is
    begin
        if rstn = '0' then
            di_cs <= DI_WAIT_FOR_DO_REQ;
        elsif rising_edge(data_in_clk) then
            di_cs <= di_ns;
        end if;
    end process di_fsm_reg;

    -- FSM data_in datapath
    di_fsm_datapath: process(di_cs, data_out_request, data_in_valid, data_out_loaded) is
    begin

        -- Default signals values
        data_in_request <= '0';
        data_reg_load <= '0';
        data_reg_valid <= '0';

        -- State switch case
        case di_cs is

            when DI_WAIT_FOR_DO_REQ =>
                di_ns <= DI_WAIT_FOR_DO_REQ;
                if data_out_request = '1' then
                    di_ns <= DI_REQUEST_DATA;
                end if;

            when DI_REQUEST_DATA =>
                data_in_request <= '1';
                di_ns <= DI_REQUEST_DATA;
                if data_in_valid = '1' then
                    di_ns <= DI_LOAD_DATA_REG;
                end if;

            when DI_LOAD_DATA_REG =>
                data_reg_load <= '1';
                di_ns <= DI_WAIT_FOR_DO_LOAD;

            when DI_WAIT_FOR_DO_LOAD =>
                data_reg_valid <= '1';
                di_ns <= DI_WAIT_FOR_DO_LOAD;
                if data_out_loaded = '1' then
                    di_ns <= DI_WAIT_FOR_DO_REQ;
                end if;

            when others =>
                di_ns <= DI_WAIT_FOR_DO_REQ;

        end case;
    end process di_fsm_datapath;

    -- FSM data_out register
    do_fsm_reg: process(data_out_clk, rstn) is
    begin
        if rstn = '0' then
            do_cs <= DO_WAIT_VALID_DATA_REG;
        elsif rising_edge(data_out_clk) then
            do_cs <= do_ns;
        end if;
    end process do_fsm_reg;

    -- FSM data_in datapath
    do_fsm_datapath: process(do_cs, data_reg_valid) is
    begin

        -- Default signals values
        data_out_loaded <= '0';
        data_out_valid <= '0';

        -- State switch case
        case do_cs is

            when DO_WAIT_VALID_DATA_REG =>
                do_ns <= DO_WAIT_VALID_DATA_REG;
                if data_reg_valid = '1' then
                    do_ns <= DO_LOAD_DATA_OUT;
                end if;

            when DO_LOAD_DATA_OUT =>
                data_out_valid <= '1';
                do_ns <= DO_DATA_LOADED;

            when DO_DATA_LOADED =>
                data_out_loaded <= '1';
                do_ns <= DO_DATA_LOADED;
                if data_reg_valid = '0' then
                    do_ns <= DO_WAIT_VALID_DATA_REG;
                end if;

            when others =>
                do_ns <= DO_WAIT_VALID_DATA_REG;
        end case;
    end process do_fsm_datapath;

end architecture RTL;
