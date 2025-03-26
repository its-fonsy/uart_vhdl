library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
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
end entity uart;

architecture RTL of uart is

    -- Constant definitions
    constant RX_DATA_WIDTH : integer := 10;
    constant TX_DATA_WIDTH : integer := 9;

    component uart_tx is
        port (
                clk         : in    std_logic;
                rstn        : in    std_logic;
                start       : in    std_logic;
                parity_mode : in    std_logic;                      -- 0 = even, 1 = odd
                data_len    : in    std_logic_vector(3 downto 0);   -- Accepted value are 5 to 9
                data        : in    std_logic_vector(8 downto 0);
                tx          : out   std_logic;
                busy        : out   std_logic
             );
    end component uart_tx;

    component uart_rx is
        port (
                clk         : in    std_logic;
                rstn        : in    std_logic;
                data_len    : in    std_logic_vector(3 downto 0);   -- Accepted value are 5 to 9
                rx          : in    std_logic;
                data_ready  : out   std_logic;
                data        : out   std_logic_vector(9 downto 0)
             );
    end component uart_rx;

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

    -- Baud Rate clock
    signal baud_clk             : std_logic;

    -- UART TX signals
    signal uart_tx_start        : std_logic;
    signal uart_tx_data         : std_logic_vector(8 downto 0);
    signal uart_tx_busy         : std_logic;

    -- Fifo TX signals
    signal fifo_tx_pop          : std_logic;
    signal fifo_tx_data_ready   : std_logic;
    signal fifo_tx_data_out     : std_logic_vector(8 downto 0);

    -- UART RX signals
    signal uart_rx_data         : std_logic_vector(9 downto 0);
    signal uart_rx_data_ready   : std_logic;

    -- Fifo RX signals
    signal fifo_rx_push         : std_logic;
    signal fifo_rx_data_in      : std_logic_vector(9 downto 0);

begin

    -- Instantiate BAUD RATE GENERATOR
    baud_gen: baud_rate_generator
        generic map (
                INPUT_CLK_FREQ => INPUT_CLK_FREQ
                )
        port map (
                i_clk => clk,
                rstn => rstn,
                baud_config => baud_rate,
                o_clk_baud => baud_clk
             );

    -- Instantiate FIFO TX
    fifo_tx: fifo
        generic map(
                DATA_WIDTH  => TX_DATA_WIDTH,
                SIZE        => TX_FIFO_SIZE
                   )
        port map(
                clk => clk,
                rstn => rstn,
                push => tx_data_ready,
                data_in => tx_data,
                pop => fifo_tx_pop,
                data_out => fifo_tx_data_out,
                data_ready => fifo_tx_data_ready,
                full => tx_fifo_full
                );

    -- Instantiate UART TX
    tx0: uart_tx
        port map(
                clk => baud_clk,
                rstn => rstn,
                start => uart_tx_start,
                parity_mode => data_parity,
                data_len => data_len,
                data => uart_tx_data,
                tx => tx,
                busy => uart_tx_busy
                );

    -- Instantiate DATA BUFFER TX
    data_buffer_tx: data_buffer
        generic map(
                DATA_WIDTH => TX_DATA_WIDTH
                    )
        port map(
                rstn => rstn,
                data_in => fifo_tx_data_out,
                data_in_clk => clk,
                data_in_valid => fifo_tx_data_ready,
                data_in_request => fifo_tx_pop,
                data_out => uart_tx_data,
                data_out_clk => baud_clk,
                data_out_valid => uart_tx_start,
                data_out_request => not uart_tx_busy
                );

    -- Instantiate RX FIFO
    fifo_rx: fifo
        generic map(
                DATA_WIDTH  => RX_DATA_WIDTH,
                SIZE        => RX_FIFO_SIZE
                   )
        port map(
                clk => clk,
                rstn => rstn,
                push => fifo_rx_push,
                data_in => fifo_rx_data_in,
                pop => rx_data_request,
                data_out => rx_data,
                data_ready => rx_data_ready,
                full => rx_fifo_full
                );

    -- Instantiate UART RX
    rx0: uart_rx
        port map(
                clk => baud_clk,
                rstn => rstn,
                data_len => data_len,
                rx => rx,
                data_ready => uart_rx_data_ready,
                data => uart_rx_data 
                );

    -- Instantiate UART RX
    data_buffer_rx: data_buffer
        generic map(
                DATA_WIDTH => RX_DATA_WIDTH
                    )
        port map(
                rstn => rstn,
                data_in => uart_rx_data,
                data_in_clk => baud_clk,
                data_in_valid => uart_rx_data_ready,
                data_in_request => open,
                data_out => fifo_rx_data_in,
                data_out_clk => clk,
                data_out_valid => fifo_rx_push,
                data_out_request => '1'
                );

end architecture RTL;
