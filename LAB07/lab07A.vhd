library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DividerA is
    port(
        clk        : in  std_logic;
        clear      : in  std_logic; -- Asynchronous clear for registers, synchronous reset for FSM
        Divisor_in : in  std_logic_vector(7 downto 0);
        Dividend_in: in  std_logic_vector(7 downto 0);

        Done_Flag         : out std_logic;
        Quotient_out      : out std_logic_vector(7 downto 0);
        Actual_Remainder_out : out std_logic_vector(7 downto 0);

        q_segments_d0   : out std_logic_vector(6 downto 0);
        q_segments_d1   : out std_logic_vector(6 downto 0);
        r_segments_d0   : out std_logic_vector(6 downto 0);
        r_segments_d1   : out std_logic_vector(6 downto 0);

        state_out : out std_logic_vector(2 downto 0) -- For debugging or monitoring FSM state
    );
end entity DividerA;

architecture logicfunc of DividerA is

    component lab05a is
        generic (N : integer := 8);
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
            reset  : in  std_logic; -- FSM uses synchronous reset based on its internal structure
            w      : in  std_logic;
            output : out std_logic_vector(2 downto 0)
        );
    end component FSM;

    component binary_to_4_digit_7seg is
        port (
            binary_in         : in  std_logic_vector(15 downto 0);
            segments_out_d0   : out std_logic_vector(6 downto 0);
            segments_out_d1   : out std_logic_vector(6 downto 0);
            segments_out_d2   : out std_logic_vector(6 downto 0);
            segments_out_d3   : out std_logic_vector(6 downto 0)
        );
    end component binary_to_4_digit_7seg;

    -- Signals from FSM
    signal state_from_fsm : std_logic_vector(2 downto 0);

    -- Register outputs
    signal r_reg_q : std_logic_vector(15 downto 0);
    signal d_reg_q : std_logic_vector(15 downto 0);
    signal q_reg_q : std_logic_vector(7 downto 0);

    -- Combinational signals for register control and data inputs
    signal r_load_comb, d_load_comb, q_load_comb : std_logic;
    signal r_reg_di_comb, d_reg_di_comb       : std_logic_vector(15 downto 0);
    signal q_reg_di_comb                      : std_logic_vector(7 downto 0);
    signal q_sdi_comb, d_sdi_comb             : std_logic;
    signal fsm_input_comb                     : std_logic;
    signal done_flag_comb                     : std_logic;

    -- Registered count signal
    signal count_reg  : integer range 0 to 8 := 0;
    signal count_next : integer range 0 to 8;

    -- Signals for 7-segment display inputs
    signal res_r_disp, res_q_disp : std_logic_vector(7 downto 0);

begin

    FSM_CTRL : FSM
        port map (
            clk    => clk,
            reset  => clear, -- FSM reset tied to main clear
            w      => fsm_input_comb,
            output => state_from_fsm
        );

    R_Register : lab05a
        generic map (N => 16)
        port map (
            clk    => clk,
            clear  => clear,
            load   => r_load_comb,
            lr_sel => '0',          -- R_Register doesn't shift based on lr_sel here, only loads
            di     => r_reg_di_comb,
            sdi    => '0',          -- Not used for shifting R in this algorithm
            qo     => r_reg_q
        );

    D_Register : lab05a
        generic map (N => 16)
        port map (
            clk    => clk,
            clear  => clear,
            load   => d_load_comb,
            lr_sel => '0',          -- '0' for right shift
            di     => d_reg_di_comb,
            sdi    => d_sdi_comb,   -- Serial input for right shift
            qo     => d_reg_q
        );

    Q_Register : lab05a
        generic map (N => 8)
        port map (
            clk    => clk,
            clear  => clear,
            load   => q_load_comb,
            lr_sel => '1',          -- '1' for left shift
            di     => q_reg_di_comb,
            sdi    => q_sdi_comb,   -- Serial input for left shift
            qo     => q_reg_q
        );

    -- Combinational logic for FSM input and register controls
    comb_logic_proc : process(state_from_fsm, r_reg_q, d_reg_q, q_reg_q, Dividend_in, Divisor_in, count_reg)
        variable temp_rem : signed(15 downto 0); -- Use signed for subtraction comparison
    begin
        -- Default assignments (to hold values or defined states)
        r_load_comb <= '1'; r_reg_di_comb <= r_reg_q; -- Hold R
        d_load_comb <= '1'; d_reg_di_comb <= d_reg_q; -- Hold D
        q_load_comb <= '1'; q_reg_di_comb <= q_reg_q; -- Hold Q

        q_sdi_comb <= '0';      -- Default serial input for Q
        d_sdi_comb <= '0';      -- Default serial input for D (for right shift)
        fsm_input_comb <= '0';  -- Default FSM condition
        done_flag_comb <= '0';  -- Default Done_Flag
        count_next <= count_reg; -- Default: count doesn't change

        case state_from_fsm is
            when "000" =>  -- S0: Initialization
                r_load_comb <= '1';
                r_reg_di_comb(15 downto 8) <= (others => '0');
                r_reg_di_comb(7 downto 0)  <= Dividend_in;

                d_load_comb <= '1';
                d_reg_di_comb(15 downto 8) <= Divisor_in;
                d_reg_di_comb(7 downto 0)  <= (others => '0');

                q_load_comb <= '1';
                q_reg_di_comb <= (others => '0');

                fsm_input_comb <= '1'; -- Trigger transition to S1
                count_next <= 0;     -- Reset iteration counter

            when "001" =>  -- S1: Subtract (Trial division)
                temp_rem := signed(r_reg_q) - signed(d_reg_q);
                r_load_comb <= '1';
                r_reg_di_comb <= std_logic_vector(temp_rem); -- Load R with (R-D)
                fsm_input_comb <= temp_rem(15); -- MSB indicates sign (1 for negative)
                -- D and Q hold (covered by defaults)

            when "010" =>  -- S2A: Subtraction successful (R-D >= 0), r_reg_q now holds (OldR - D)
                -- R holds its new value (OldR - D) (covered by default as r_reg_di_comb defaults to r_reg_q)
                -- D holds (covered by default)
                q_load_comb <= '0'; -- Enable Q shift
                q_sdi_comb  <= '1'; -- Shift '1' into Q
                fsm_input_comb <= '0'; -- Always transition to S3

            when "011" =>  -- S2B: Subtraction failed (R-D < 0), r_reg_q now holds (OldR - D)
                r_load_comb <= '1';
                -- Restore R: current r_reg_q is (OldR - D), so add D back
                r_reg_di_comb <= std_logic_vector(signed(r_reg_q) + signed(d_reg_q));
                -- D holds (covered by default)
                q_load_comb <= '0'; -- Enable Q shift
                q_sdi_comb  <= '0'; -- Shift '0' into Q
                fsm_input_comb <= '0'; -- Always transition to S3

            when "100" =>  -- S3: Shift Divisor right
                -- R holds (covered by default)
                -- Q holds (covered by default, already shifted in S2A/S2B)
                d_load_comb <= '0'; -- Enable D shift
                d_sdi_comb  <= '0'; -- Shift '0' into MSB of D (logical right shift)

                count_next <= count_reg + 1;
                if count_reg = 8 then -- After 8 shifts (0 to 7)
                    fsm_input_comb <= '1';  -- Done, transition to S4
                else
                    fsm_input_comb <= '0';  -- Not done, transition back to S1
                end if;

            when "101" =>  -- S4: Done
                done_flag_comb <= '1';
                -- R, D, Q hold (covered by defaults)
                fsm_input_comb <= '0'; -- Stay in S4 (FSM handles this)

            when others => -- Should not happen
                r_load_comb <= '1'; r_reg_di_comb <= (others => 'X');
                d_load_comb <= '1'; d_reg_di_comb <= (others => 'X');
                q_load_comb <= '1'; q_reg_di_comb <= (others => 'X');
                fsm_input_comb <= '0';
                done_flag_comb <= '0';

        end case;
    end process comb_logic_proc;

    -- Process for the registered count
    count_update_proc : process(clk, clear)
    begin
        if clear = '1' then
            count_reg <= 0;
        elsif rising_edge(clk) then
            -- Update count based on FSM state logic from comb_logic_proc
            if state_from_fsm = "000" then -- Reset count at the start of operation
                 count_reg <= 0;
            elsif state_from_fsm = "100" then -- Increment count during S3 (Shift D)
                 count_reg <= count_next;
            end if;
            -- For other states, count_reg retains its value unless explicitly changed by count_next
        end if;
    end process count_update_proc;

    -- Output assignments
    state_out            <= state_from_fsm;
    Done_Flag            <= done_flag_comb;
    Quotient_out         <= q_reg_q;
    Actual_Remainder_out <= r_reg_q(7 downto 0); -- Remainder is in the lower bits of R

    -- Prepare signals for 7-segment display
    res_r_disp <= r_reg_q(7 downto 0);
    res_q_disp <= q_reg_q;

    R_Display : binary_to_4_digit_7seg
        port map (
            binary_in       => "00000000" & res_r_disp,
            segments_out_d0 => r_segments_d0,
            segments_out_d1 => r_segments_d1,
            segments_out_d2 => open, -- Not connected
            segments_out_d3 => open  -- Not connected
        );

    Q_Display : binary_to_4_digit_7seg
        port map (
            binary_in       => "00000000" & res_q_disp,
            segments_out_d0 => q_segments_d0,
            segments_out_d1 => q_segments_d1,
            segments_out_d2 => open, -- Not connected
            segments_out_d3 => open  -- Not connected
        );

end architecture logicfunc;