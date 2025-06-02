library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divider is
    generic (
        N_BITS : integer := 8;  -- Bit width of Divisor, Dividend, Quotient, Remainder
        M_BITS : integer := 16  -- Bit width of internal R and D registers (typically 2*N_BITS)
                                -- Constraint: M_BITS >= N_BITS
    );
    port(
        clk        : in  std_logic;
        clear      : in  std_logic;
        Divisor_in : in  std_logic_vector(N_BITS-1 downto 0);
        Dividend_in: in  std_logic_vector(N_BITS-1 downto 0);

        Done_Flag         : out std_logic;
        Quotient_out      : out std_logic_vector(N_BITS-1 downto 0);
        Actual_Remainder_out : out std_logic_vector(N_BITS-1 downto 0); -- Remainder also N_BITS

        -- 7-Segment display outputs (these remain fixed width for the example component)
        -- You might need a generic display driver or adjust this section for larger N_BITS
        q_segments_d0   : out std_logic_vector(6 downto 0);
        q_segments_d1   : out std_logic_vector(6 downto 0);
        r_segments_d0   : out std_logic_vector(6 downto 0);
        r_segments_d1   : out std_logic_vector(6 downto 0);

        state_out : out std_logic_vector(2 downto 0)
    );
end entity Divider;

architecture logicfunc of Divider is

    -- Ensure M_BITS is at least N_BITS for the algorithm to work as intended
    -- and typically M_BITS should be 2*N_BITS for the restoring algorithm variant
    -- where D shifts right and R holds the dividend initially.
    -- If R were to shift left, M_BITS would be N_BITS for R and D.
    -- For this D-shifting-right algorithm:
    -- R needs to hold Dividend (N bits) and have space for intermediate results.
    -- D needs to hold Divisor (N bits) and be able to shift it across M bits.
    -- Let's assume the common setup where R is M_BITS and D is M_BITS.

    constant INTERNAL_WIDTH : integer := M_BITS; -- Internal register width
    constant DATA_WIDTH     : integer := N_BITS; -- Input/Output data width

    component lab05a is
        generic (N : integer); -- Generic width for the shift register
        port(
            clk    : in  std_logic;
            clear  : in  std_logic;
            load   : in  std_logic;
            lr_sel : in  std_logic;
            di     : in  std_logic_vector(N-1 downto 0);
            sdi    : in  std_logic;
            qo     : out std_logic_vector(N-1 downto 0)
        );
    end component lab05a;

    component FSM is
        port (
            clk    : in  std_logic;
            reset  : in  std_logic;
            w      : in  std_logic;
            output : out std_logic_vector(2 downto 0)
        );
    end component FSM;

    component binary_to_4_digit_7seg is
        port (
            binary_in         : in  std_logic_vector(15 downto 0); -- Fixed input width
            segments_out_d0   : out std_logic_vector(6 downto 0);
            segments_out_d1   : out std_logic_vector(6 downto 0);
            segments_out_d2   : out std_logic_vector(6 downto 0);
            segments_out_d3   : out std_logic_vector(6 downto 0)
        );
    end component binary_to_4_digit_7seg;

    signal state_from_fsm : std_logic_vector(2 downto 0);

    signal r_reg_q : std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    signal d_reg_q : std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    signal q_reg_q : std_logic_vector(DATA_WIDTH-1 downto 0);

    signal r_load_comb, d_load_comb, q_load_comb : std_logic;
    signal r_reg_di_comb, d_reg_di_comb       : std_logic_vector(INTERNAL_WIDTH-1 downto 0);
    signal q_reg_di_comb                      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal q_sdi_comb, d_sdi_comb             : std_logic;
    signal fsm_input_comb                     : std_logic;
    signal done_flag_comb                     : std_logic;

    signal count_reg  : integer range 0 to DATA_WIDTH := 0; -- Count up to N_BITS iterations
    signal count_next : integer range 0 to DATA_WIDTH;

    signal res_r_disp_padded, res_q_disp_padded : std_logic_vector(15 downto 0);

begin
    -- Assertions for generics (optional, but good practice)
    assert M_BITS >= N_BITS report "M_BITS must be >= N_BITS" severity error;
    -- Typically for this algorithm:
    -- assert M_BITS = 2 * N_BITS report "M_BITS should ideally be 2*N_BITS for this algorithm style" severity warning;


    FSM_CTRL : FSM
        port map (
            clk    => clk,
            reset  => clear,
            w      => fsm_input_comb,
            output => state_from_fsm
        );

    R_Register : lab05a
        generic map (N => INTERNAL_WIDTH)
        port map (
            clk    => clk, clear  => clear, load   => r_load_comb,
            lr_sel => '0', di => r_reg_di_comb, sdi => '0', qo => r_reg_q
        );

    D_Register : lab05a
        generic map (N => INTERNAL_WIDTH)
        port map (
            clk    => clk, clear  => clear, load   => d_load_comb,
            lr_sel => '0', di => d_reg_di_comb, sdi => d_sdi_comb, qo => d_reg_q
        );

    Q_Register : lab05a
        generic map (N => DATA_WIDTH)
        port map (
            clk    => clk, clear  => clear, load   => q_load_comb,
            lr_sel => '1', di => q_reg_di_comb, sdi => q_sdi_comb, qo => q_reg_q
        );

    comb_logic_proc : process(state_from_fsm, r_reg_q, d_reg_q, q_reg_q, Dividend_in, Divisor_in, count_reg)
        variable temp_rem : signed(INTERNAL_WIDTH-1 downto 0);
    begin
        r_load_comb <= '1'; r_reg_di_comb <= r_reg_q;
        d_load_comb <= '1'; d_reg_di_comb <= d_reg_q;
        q_load_comb <= '1'; q_reg_di_comb <= q_reg_q;

        q_sdi_comb <= '0';
        d_sdi_comb <= '0';
        fsm_input_comb <= '0';
        done_flag_comb <= '0';
        count_next <= count_reg;

        case state_from_fsm is
            when "000" =>  -- S0: Initialization
                r_load_comb <= '1';
                -- Load Dividend_in into lower N_BITS of r_reg_di_comb, upper bits are zero
                r_reg_di_comb(INTERNAL_WIDTH-1 downto DATA_WIDTH) <= (others => '0');
                r_reg_di_comb(DATA_WIDTH-1 downto 0)  <= Dividend_in;

                d_load_comb <= '1';
                -- Load Divisor_in into upper N_BITS of d_reg_di_comb (shifted left)
                d_reg_di_comb(INTERNAL_WIDTH-1 downto INTERNAL_WIDTH-DATA_WIDTH) <= Divisor_in;
                if (INTERNAL_WIDTH-DATA_WIDTH-1 >= 0) then -- Check if there are lower bits to zero out
                   d_reg_di_comb(INTERNAL_WIDTH-DATA_WIDTH-1 downto 0)  <= (others => '0');
                end if;


                q_load_comb <= '1';
                q_reg_di_comb <= (others => '0');

                fsm_input_comb <= '1';
                count_next <= 0;

            when "001" =>  -- S1: Subtract
                temp_rem := signed(r_reg_q) - signed(d_reg_q);
                r_load_comb <= '1';
                r_reg_di_comb <= std_logic_vector(temp_rem);
                fsm_input_comb <= temp_rem(INTERNAL_WIDTH-1); -- MSB indicates sign

            when "010" =>  -- S2A: Subtraction successful
                q_load_comb <= '0';
                q_sdi_comb  <= '1';
                fsm_input_comb <= '0';

            when "011" =>  -- S2B: Subtraction failed, restore
                r_load_comb <= '1';
                r_reg_di_comb <= std_logic_vector(signed(r_reg_q) + signed(d_reg_q));
                q_load_comb <= '0';
                q_sdi_comb  <= '0';
                fsm_input_comb <= '0';

            when "100" =>  -- S3: Shift Divisor right
                d_load_comb <= '0';
                d_sdi_comb  <= '0';

                count_next <= count_reg + 1;
                -- Done after N_BITS iterations. count_reg goes from 0 to N_BITS-1.
                -- So, if current count_reg is N_BITS-1, this is the last iteration.
                if count_reg = DATA_WIDTH then
                    fsm_input_comb <= '1';
                else
                    fsm_input_comb <= '0';
                end if;

            when "101" =>  -- S4: Done
                done_flag_comb <= '1';
                fsm_input_comb <= '0';

            when others => null;
        end case;
    end process comb_logic_proc;

    count_update_proc : process(clk, clear)
    begin
        if clear = '1' then
            count_reg <= 0;
        elsif rising_edge(clk) then
            if state_from_fsm = "000" then
                 count_reg <= 0;
            elsif state_from_fsm = "100" then
                 count_reg <= count_next;
            end if;
        end if;
    end process count_update_proc;

    state_out            <= state_from_fsm;
    Done_Flag            <= done_flag_comb;
    Quotient_out         <= q_reg_q;
    -- The final remainder will be in the lower DATA_WIDTH bits of r_reg_q
    -- after D has been shifted right DATA_WIDTH times.
    Actual_Remainder_out <= r_reg_q(DATA_WIDTH-1 downto 0);

    -- 7-Segment Display Logic (adapting for generic N_BITS)
    -- This part is a simplification. A real generic display would be more complex.
    -- It pads or truncates the N_BITS value to fit the 16-bit input of binary_to_4_digit_7seg.
    gen_display_padding: process(r_reg_q, q_reg_q)
    begin
        -- Remainder Display
        if DATA_WIDTH >= 16 then
            res_r_disp_padded <= r_reg_q(15 downto 0); -- Display lower 16 bits if N_BITS is large
        else
            res_r_disp_padded <= std_logic_vector(resize(unsigned(r_reg_q(DATA_WIDTH-1 downto 0)), 16)); -- Zero-extend
        end if;

        -- Quotient Display
        if DATA_WIDTH >= 16 then
            res_q_disp_padded <= q_reg_q(15 downto 0); -- Display lower 16 bits if N_BITS is large
        else
            res_q_disp_padded <= std_logic_vector(resize(unsigned(q_reg_q), 16)); -- Zero-extend
        end if;
    end process gen_display_padding;


    R_Display : binary_to_4_digit_7seg
        port map (
            binary_in       => res_r_disp_padded,
            segments_out_d0 => r_segments_d0,
            segments_out_d1 => r_segments_d1,
            segments_out_d2 => open,
            segments_out_d3 => open
        );

    Q_Display : binary_to_4_digit_7seg
        port map (
            binary_in       => res_q_disp_padded,
            segments_out_d0 => q_segments_d0,
            segments_out_d1 => q_segments_d1,
            segments_out_d2 => open,
            segments_out_d3 => open
        );

end architecture logicfunc;