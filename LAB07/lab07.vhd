library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Divider is
    generic (
        N_BITS : integer := 8  -- Bit width of Divisor, Dividend, Quotient, Remainder
        -- M_BITS will be calculated internally
    );
    port(
        clk        : in  std_logic;
        clear      : in  std_logic;
        Divisor_in : in  std_logic_vector(N_BITS-1 downto 0);
        Dividend_in: in  std_logic_vector(N_BITS-1 downto 0);

        Done_Flag         : out std_logic;
        Quotient_out      : out std_logic_vector(N_BITS-1 downto 0);
        Actual_Remainder_out : out std_logic_vector(N_BITS-1 downto 0);

        q_segments_d0   : out std_logic_vector(6 downto 0);
        q_segments_d1   : out std_logic_vector(6 downto 0);
        r_segments_d0   : out std_logic_vector(6 downto 0);
        r_segments_d1   : out std_logic_vector(6 downto 0);

        state_out : out std_logic_vector(2 downto 0)
    );
end entity Divider;

architecture logicfunc of Divider is

    -- Calculate M_BITS based on N_BITS
    constant M_CALCULATED_BITS : integer := 2 * N_BITS;
    -- Or, if you want to ensure it's at least a certain minimum (e.g., if N_BITS is very small)
    -- constant M_CALCULATED_BITS : integer := maximum(2 * N_BITS, SOME_MINIMUM_WIDTH_IF_NEEDED);

    constant INTERNAL_WIDTH : integer := M_CALCULATED_BITS; -- Internal register width for R and D
    constant DATA_WIDTH     : integer := N_BITS;         -- Input/Output data width (Quotient)

    -- Component declarations (remain the same)
    component lab05a is
        generic (N : integer);
        port(
            clk    : in  std_logic; clear  : in  std_logic; load   : in  std_logic;
            lr_sel : in  std_logic; di     : in  std_logic_vector(N-1 downto 0);
            sdi    : in  std_logic; qo     : out std_logic_vector(N-1 downto 0)
        );
    end component lab05a;

    component FSM is
        port (
            clk    : in  std_logic; reset  : in  std_logic; w      : in  std_logic;
            output : out std_logic_vector(2 downto 0)
        );
    end component FSM;

    component binary_to_4_digit_7seg is
        port (
            binary_in         : in  std_logic_vector(15 downto 0);
            segments_out_d0   : out std_logic_vector(6 downto 0); segments_out_d1   : out std_logic_vector(6 downto 0);
            segments_out_d2   : out std_logic_vector(6 downto 0); segments_out_d3   : out std_logic_vector(6 downto 0)
        );
    end component binary_to_4_digit_7seg;

    -- Signal declarations (widths now use INTERNAL_WIDTH and DATA_WIDTH)
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

    -- Count logic: iteration count is DATA_WIDTH (N_BITS)
    -- count_reg goes from 0 to DATA_WIDTH-1 during iterations.
    -- It can become DATA_WIDTH after the last increment.
    signal count_reg  : integer range 0 to DATA_WIDTH := 0;
    signal count_next : integer range 0 to DATA_WIDTH;

    signal res_r_disp_padded, res_q_disp_padded : std_logic_vector(15 downto 0);

begin
    -- Assertion (optional, N_BITS > 0 would be good)
    assert N_BITS > 0 report "N_BITS must be greater than 0" severity error;
    assert INTERNAL_WIDTH >= DATA_WIDTH report "INTERNAL_WIDTH must be >= DATA_WIDTH" severity error;


    FSM_CTRL : FSM
        port map (
            clk    => clk, reset  => clear, w      => fsm_input_comb,
            output => state_from_fsm
        );

    R_Register : lab05a
        generic map (N => INTERNAL_WIDTH)
        port map (
            clk    => clk, clear  => clear, load   => r_load_comb,
            lr_sel => '0', di     => r_reg_di_comb, sdi    => '0', qo     => r_reg_q
        );

    D_Register : lab05a
        generic map (N => INTERNAL_WIDTH)
        port map (
            clk    => clk, clear  => clear, load   => d_load_comb,
            lr_sel => '0', di     => d_reg_di_comb, sdi    => d_sdi_comb, qo     => d_reg_q
        );

    Q_Register : lab05a
        generic map (N => DATA_WIDTH)
        port map (
            clk    => clk, clear  => clear, load   => q_load_comb,
            lr_sel => '1', di     => q_reg_di_comb, sdi    => q_sdi_comb, qo     => q_reg_q
        );

    comb_logic_proc : process(state_from_fsm, r_reg_q, d_reg_q, q_reg_q, Dividend_in, Divisor_in, count_reg)
        variable temp_rem : signed(INTERNAL_WIDTH-1 downto 0);
    begin
        -- Default assignments
        r_load_comb <= '1'; r_reg_di_comb <= r_reg_q;
        d_load_comb <= '1'; d_reg_di_comb <= d_reg_q;
        q_load_comb <= '1'; q_reg_di_comb <= q_reg_q;
        q_sdi_comb <= '0'; d_sdi_comb <= '0';
        fsm_input_comb <= '0'; done_flag_comb <= '0';
        count_next <= count_reg;

        case state_from_fsm is
            when "000" =>  -- S0: Initialization
                r_load_comb <= '1';
                -- Load Dividend_in into lower DATA_WIDTH bits of r_reg_di_comb
                r_reg_di_comb(INTERNAL_WIDTH-1 downto DATA_WIDTH) <= (others => '0');
                r_reg_di_comb(DATA_WIDTH-1 downto 0)  <= Dividend_in;

                d_load_comb <= '1';
                -- Load Divisor_in into upper DATA_WIDTH bits of d_reg_di_comb (left-aligned)
                -- The effective initial position of Divisor for the first subtraction.
                -- Example: N=8, M=16. Divisor in D(15 downto 8).
                d_reg_di_comb(INTERNAL_WIDTH-1 downto INTERNAL_WIDTH-DATA_WIDTH) <= Divisor_in;
                if (INTERNAL_WIDTH-DATA_WIDTH > 0) then -- Check if there are lower bits to zero out
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
                q_load_comb <= '0'; q_sdi_comb  <= '1';
                fsm_input_comb <= '0';

            when "011" =>  -- S2B: Subtraction failed, restore
                r_load_comb <= '1';
                r_reg_di_comb <= std_logic_vector(signed(r_reg_q) + signed(d_reg_q));
                q_load_comb <= '0'; q_sdi_comb  <= '0';
                fsm_input_comb <= '0';

            when "100" =>  -- S3: Shift Divisor right
                d_load_comb <= '0'; d_sdi_comb  <= '0'; -- Shift D right
                count_next <= count_reg + 1;

                -- Done after DATA_WIDTH iterations. count_reg goes from 0 to DATA_WIDTH-1.
                -- If current count_reg is DATA_WIDTH-1, this is the S3 of the last iteration.
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
                 count_reg <= 0; -- count_next from S0 will be 0
            elsif state_from_fsm = "100" then
                 count_reg <= count_next; -- Load incremented value from S3
            end if;
            -- In other states, count_reg holds its value as count_next defaults to count_reg
        end if;
    end process count_update_proc;

    state_out            <= state_from_fsm;
    Done_Flag            <= done_flag_comb;
    Quotient_out         <= q_reg_q;
    Actual_Remainder_out <= r_reg_q(DATA_WIDTH-1 downto 0);

    -- 7-Segment Display Logic (adapting for generic N_BITS)
    gen_display_padding: process(r_reg_q, q_reg_q)
        variable r_val_for_disp : unsigned(DATA_WIDTH-1 downto 0);
        variable q_val_for_disp : unsigned(DATA_WIDTH-1 downto 0);
    begin
        r_val_for_disp := unsigned(r_reg_q(DATA_WIDTH-1 downto 0));
        q_val_for_disp := unsigned(q_reg_q);

        -- Remainder Display
        if DATA_WIDTH >= 16 then
            res_r_disp_padded <= std_logic_vector(r_val_for_disp(15 downto 0));
        else
            res_r_disp_padded <= std_logic_vector(resize(r_val_for_disp, 16));
        end if;

        -- Quotient Display
        if DATA_WIDTH >= 16 then
            res_q_disp_padded <= std_logic_vector(q_val_for_disp(15 downto 0));
        else
            res_q_disp_padded <= std_logic_vector(resize(q_val_for_disp, 16));
        end if;
    end process gen_display_padding;

    R_Display : binary_to_4_digit_7seg
        port map (
            binary_in       => res_r_disp_padded,
            segments_out_d0 => r_segments_d0, segments_out_d1 => r_segments_d1,
            segments_out_d2 => open, segments_out_d3 => open
        );

    Q_Display : binary_to_4_digit_7seg
        port map (
            binary_in       => res_q_disp_padded,
            segments_out_d0 => q_segments_d0, segments_out_d1 => q_segments_d1,
            segments_out_d2 => open, segments_out_d3 => open
        );

end architecture logicfunc;