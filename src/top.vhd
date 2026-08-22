library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    port(
        clk              : in std_logic;
        echo             : in std_logic;
        trigger          : out std_logic;
        servo1           : out std_logic;
        servo2           : out std_logic;
        btnreset         : in std_logic;
        seg              : out std_logic_vector(6 downto 0);
        anode            : out std_logic_vector(3 downto 0);
        buzzer           : out std_logic;
        led1             : out std_logic;
        led2             : out std_logic;
        led3             : out std_logic;
        laser_servo_pan  : out std_logic;
        laser_servo_tilt : out std_logic;
        laser_out        : out std_logic
    );
end top;

architecture Behavioral of top is
    component servo
        port(
            clk   : in std_logic;
            cycle : in integer;
            move  : out std_logic
        );
    end component;

    component radar
        port(
            clk      : in std_logic;
            trigger  : out std_logic;
            echo     : in std_logic;
            distance : out integer
        );
    end component;

    component sevsegdis
        port(
            clk : in std_logic;
            num : in integer;
            seg : out std_logic_vector(6 downto 0);
            an  : out std_logic_vector(3 downto 0)
        );
    end component;

    component Laser_Turret_Unit
        port(
            clk              : in std_logic;
            reset            : in std_logic;
            distance_cm      : in integer;
            pan_position_in  : in integer;
            tilt_position_in : in integer;
            laser_servo_pan  : out std_logic;
            laser_servo_tilt : out std_logic;
            laser_out        : out std_logic
        );
    end component;

    signal distance_sig : integer := 0;

    constant MIN_ANGLE   : integer := 55000;
    constant MAX_ANGLE   : integer := 240000;
    constant PAN_STEP    : integer := 500;
    constant TILT_STEP   : integer := 15000;
    constant SWEEP_DELAY : integer := 500000;

    signal servo1pos   : integer := 147500;
    signal servo2pos   : integer := 147500;
    signal sweep_timer : integer := 0;

    signal pan_dir  : std_logic := '1';
    signal tilt_dir : std_logic := '1';

    type state_type is (SCANNING, LOCKED);
    signal current_state : state_type := SCANNING;

    signal target_lost_timer : integer := 0;
    constant LOST_TIMEOUT : integer := 50000000;

    signal beep_timer   : integer := 0;
    signal beep_limit   : integer := 0;
    signal buzzer_state : std_logic := '0';

    signal display_val : integer := 0;
begin
    distsensor: radar port map(
        clk      => clk,
        echo     => echo,
        trigger  => trigger,
        distance => distance_sig
    );

    flatservo: servo port map(
        clk   => clk,
        cycle => servo1pos,
        move  => servo1
    );

    verticalservo: servo port map(
        clk   => clk,
        cycle => servo2pos,
        move  => servo2
    );

    display: sevsegdis port map(
        clk => clk,
        seg => seg,
        an  => anode,
        num => display_val
    );

    laser_unit: Laser_Turret_Unit port map(
        clk              => clk,
        reset            => btnreset,
        distance_cm      => distance_sig,
        pan_position_in  => servo1pos,
        tilt_position_in => servo2pos,
        laser_servo_pan  => laser_servo_pan,
        laser_servo_tilt => laser_servo_tilt,
        laser_out        => laser_out
    );

    process(clk)
    begin
        if rising_edge(clk) then
            if btnreset = '1' then
                current_state <= SCANNING;
                servo1pos <= 147500;
                servo2pos <= 147500;
                pan_dir <= '1';
                tilt_dir <= '1';
                led1 <= '0';
                led2 <= '0';
                led3 <= '0';
                buzzer_state <= '0';
                buzzer <= '0';
                beep_timer <= 0;
            else
                case current_state is
                    when SCANNING =>
                        led1 <= '0';
                        led2 <= '0';
                        led3 <= '0';
                        buzzer <= '0';
                        buzzer_state <= '0';
                        display_val <= 9999;

                        if sweep_timer < SWEEP_DELAY then
                            sweep_timer <= sweep_timer + 1;
                        else
                            sweep_timer <= 0;

                            if pan_dir = '1' then
                                if servo1pos + PAN_STEP < MAX_ANGLE then
                                    servo1pos <= servo1pos + PAN_STEP;
                                else
                                    pan_dir <= '0';

                                    if tilt_dir = '1' then
                                        if servo2pos + TILT_STEP <= MAX_ANGLE then
                                            servo2pos <= servo2pos + TILT_STEP;
                                        else
                                            tilt_dir <= '0';
                                            servo2pos <= servo2pos - TILT_STEP;
                                        end if;
                                    else
                                        if servo2pos - TILT_STEP >= MIN_ANGLE then
                                            servo2pos <= servo2pos - TILT_STEP;
                                        else
                                            tilt_dir <= '1';
                                            servo2pos <= servo2pos + TILT_STEP;
                                        end if;
                                    end if;
                                end if;
                            else
                                if servo1pos - PAN_STEP > MIN_ANGLE then
                                    servo1pos <= servo1pos - PAN_STEP;
                                else
                                    pan_dir <= '1';

                                    if tilt_dir = '1' then
                                        if servo2pos + TILT_STEP <= MAX_ANGLE then
                                            servo2pos <= servo2pos + TILT_STEP;
                                        else
                                            tilt_dir <= '0';
                                            servo2pos <= servo2pos - TILT_STEP;
                                        end if;
                                    else
                                        if servo2pos - TILT_STEP >= MIN_ANGLE then
                                            servo2pos <= servo2pos - TILT_STEP;
                                        else
                                            tilt_dir <= '1';
                                            servo2pos <= servo2pos + TILT_STEP;
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;

                        if distance_sig > 2 and distance_sig <= 30 then
                            current_state <= LOCKED;
                            target_lost_timer <= 0;
                        end if;

                    when LOCKED =>
                        display_val <= distance_sig;

                        if distance_sig <= 10 then
                            led1 <= '1';
                            led2 <= '1';
                            led3 <= '1';
                        elsif distance_sig <= 20 then
                            led1 <= '1';
                            led2 <= '1';
                            led3 <= '0';
                        else
                            led1 <= '1';
                            led2 <= '0';
                            led3 <= '0';
                        end if;

                        if distance_sig > 30 or distance_sig <= 2 then
                            if target_lost_timer < LOST_TIMEOUT then
                                target_lost_timer <= target_lost_timer + 1;
                            else
                                current_state <= SCANNING;
                            end if;
                        else
                            target_lost_timer <= 0;
                        end if;

                        if distance_sig <= 10 then
                            beep_limit <= 10000000;
                        elsif distance_sig <= 20 then
                            beep_limit <= 25000000;
                        else
                            beep_limit <= 50000000;
                        end if;

                        if beep_timer < beep_limit then
                            beep_timer <= beep_timer + 1;
                        else
                            beep_timer <= 0;
                            buzzer_state <= not buzzer_state;
                        end if;

                        buzzer <= buzzer_state;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
