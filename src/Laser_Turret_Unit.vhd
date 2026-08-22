library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Laser_Turret_Unit is
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
end Laser_Turret_Unit;

architecture Behavioral of Laser_Turret_Unit is
    constant SERVO_PERIOD_CYCLES : integer := 2000000;
    constant SERVOMIN : integer := 55000;
    constant SERVOMAX : integer := 240000;
    constant CYCLE_PER_DEGREE : integer := 1027;

    constant AIM_DISTANCE_CM : integer := 30;
    constant FIRE_DISTANCE_CM : integer := 15;
    constant MIN_VALID_DISTANCE_CM : integer := 3;
    constant LOST_HOLD_CYCLES : integer := 30000000;

    constant SCAN_MIN_CYCLE : integer := 55000;
    constant SCAN_MAX_CYCLE : integer := 240000;

    constant LASX : integer := -200000;
    constant LASY : integer := 0;
    constant LASZ : integer := 0;

    constant PAN_FINE_OFFSET_CYCLE  : integer := 0;
    constant TILT_FINE_OFFSET_CYCLE : integer := 0;

    type intarray19 is array (0 to 18) of integer;

    constant SIN_LUT : intarray19 := (
        0, 17, 34, 50, 64, 77, 87, 94, 98, 100,
        98, 94, 87, 77, 64, 50, 34, 17, 0
    );

    constant COS_LUT : intarray19 := (
        100, 98, 94, 87, 77, 64, 50, 34, 17, 0,
        -17, -34, -50, -64, -77, -87, -94, -98, -100
    );

    type intarray90 is array (0 to 89) of integer;

    constant ARCTAN_LUT : intarray90 := (
        0, 2, 3, 5, 7, 9, 11, 12, 14, 16,
        18, 19, 21, 23, 25, 27, 29, 31, 32, 34,
        36, 38, 40, 42, 45, 47, 49, 51, 53, 55,
        58, 60, 62, 65, 67, 70, 73, 75, 78, 81,
        84, 87, 90, 93, 97, 100, 104, 107, 111, 115,
        119, 123, 128, 133, 138, 143, 148, 154, 160, 166,
        173, 180, 188, 196, 205, 214, 225, 236, 248, 261,
        275, 290, 308, 327, 349, 373, 401, 433, 470, 514,
        567, 631, 712, 814, 951, 1143, 1430, 1908, 2864, 5729
    );

    type laser_state_type is (IDLE, TRACKING);
    signal current_state : laser_state_type := IDLE;

    signal pwm_counter : integer range 0 to SERVO_PERIOD_CYCLES - 1 := 0;
    signal pan_pwm_target  : integer := 55000;
    signal tilt_pwm_target : integer := 55000;
    signal lost_counter : integer range 0 to LOST_HOLD_CYCLES := 0;
    signal laser_enable : std_logic := '0';
    signal last_fire : std_logic := '0';

    function clamp_servo(value_in : integer) return integer is
    begin
        if value_in < SERVOMIN then
            return SERVOMIN;
        elsif value_in > SERVOMAX then
            return SERVOMAX;
        else
            return value_in;
        end if;
    end function;

    function clamp_index(value_in : integer) return integer is
    begin
        if value_in < 0 then
            return 0;
        elsif value_in > 18 then
            return 18;
        else
            return value_in;
        end if;
    end function;

    function valid_aim_distance(d : integer) return boolean is
    begin
        return (d >= MIN_VALID_DISTANCE_CM) and (d <= AIM_DISTANCE_CM);
    end function;

    function valid_fire_distance(d : integer) return boolean is
    begin
        return (d >= MIN_VALID_DISTANCE_CM) and (d <= FIRE_DISTANCE_CM);
    end function;

    function position_to_index(pos_in : integer) return integer is
        variable pos_clamped : integer;
        variable degree_val : integer;
        variable index_val : integer;
    begin
        if pos_in < SCAN_MIN_CYCLE then
            pos_clamped := SCAN_MIN_CYCLE;
        elsif pos_in > SCAN_MAX_CYCLE then
            pos_clamped := SCAN_MAX_CYCLE;
        else
            pos_clamped := pos_in;
        end if;

        degree_val := (pos_clamped - SCAN_MIN_CYCLE) / CYCLE_PER_DEGREE;
        index_val := (degree_val + 5) / 10;
        return clamp_index(index_val);
    end function;

    function getangle(yn : integer; xn : integer) return integer is
        variable targetratio : integer;
        variable foundangle : integer := 89;
        variable abs_y : integer;
        variable abs_x : integer;
    begin
        abs_y := abs(yn);
        abs_x := abs(xn);

        if abs_x = 0 then
            return 90;
        end if;

        targetratio := (abs_y * 100) / abs_x;
        foundangle := 89;

        for i in 0 to 89 loop
            if ARCTAN_LUT(i) >= targetratio then
                foundangle := i;
                exit;
            end if;
        end loop;

        if xn >= 0 then
            if yn >= 0 then
                return 90 + foundangle;
            else
                return 90 - foundangle;
            end if;
        else
            if yn >= 0 then
                return 180;
            else
                return 0;
            end if;
        end if;
    end function;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if pwm_counter = SERVO_PERIOD_CYCLES - 1 then
                pwm_counter <= 0;
            else
                pwm_counter <= pwm_counter + 1;
            end if;
        end if;
    end process;

    process(clk)
        variable pan_index : integer;
        variable tilt_index : integer;
        variable lock_x : integer;
        variable lock_y : integer;
        variable lock_z : integer;
        variable lx : integer;
        variable ly : integer;
        variable lz : integer;
        variable abs_lx : integer;
        variable abs_ly : integer;
        variable horizontal_dist : integer;
        variable rotate_deg : integer;
        variable tilt_deg : integer;
        variable pan_pwm_calc : integer;
        variable tilt_pwm_calc : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= IDLE;
                pan_pwm_target <= SERVOMIN;
                tilt_pwm_target <= SERVOMIN;
                lost_counter <= 0;
                laser_enable <= '0';
                last_fire <= '0';
            else
                if valid_aim_distance(distance_cm) then
                    current_state <= TRACKING;
                    lost_counter <= 0;

                    pan_index := position_to_index(pan_position_in);
                    tilt_index := position_to_index(tilt_position_in);

                    lock_x := distance_cm * COS_LUT(tilt_index) * COS_LUT(pan_index);
                    lock_y := distance_cm * COS_LUT(tilt_index) * SIN_LUT(pan_index);
                    lock_z := distance_cm * SIN_LUT(tilt_index) * 100;

                    lx := lock_x - LASX;
                    ly := lock_y - LASY;
                    lz := lock_z - LASZ;

                    abs_lx := abs(lx);
                    abs_ly := abs(ly);

                    rotate_deg := getangle(ly, lx);

                    if abs_lx > abs_ly then
                        horizontal_dist := (96 * abs_lx + 40 * abs_ly) / 100;
                    else
                        horizontal_dist := (96 * abs_ly + 40 * abs_lx) / 100;
                    end if;

                    tilt_deg := getangle(lz, horizontal_dist);

                    pan_pwm_calc := SERVOMIN + (rotate_deg * CYCLE_PER_DEGREE) +
                                    PAN_FINE_OFFSET_CYCLE;
                    tilt_pwm_calc := SERVOMIN + ((tilt_deg - 90) * CYCLE_PER_DEGREE) +
                                     TILT_FINE_OFFSET_CYCLE;

                    pan_pwm_target <= clamp_servo(pan_pwm_calc);
                    tilt_pwm_target <= clamp_servo(tilt_pwm_calc);

                    if valid_fire_distance(distance_cm) then
                        laser_enable <= '1';
                        last_fire <= '1';
                    else
                        laser_enable <= '0';
                        last_fire <= '0';
                    end if;
                else
                    case current_state is
                        when IDLE =>
                            pan_pwm_target <= SERVOMIN;
                            tilt_pwm_target <= SERVOMIN;
                            laser_enable <= '0';
                            last_fire <= '0';
                            lost_counter <= 0;

                        when TRACKING =>
                            if lost_counter < LOST_HOLD_CYCLES then
                                lost_counter <= lost_counter + 1;
                                laser_enable <= last_fire;
                            else
                                current_state <= IDLE;
                                lost_counter <= 0;
                                laser_enable <= '0';
                                last_fire <= '0';
                                pan_pwm_target <= SERVOMIN;
                                tilt_pwm_target <= SERVOMIN;
                            end if;
                    end case;
                end if;
            end if;
        end if;
    end process;

    laser_servo_pan <= '1' when pwm_counter < pan_pwm_target else '0';
    laser_servo_tilt <= '1' when pwm_counter < tilt_pwm_target else '0';
    laser_out <= laser_enable;
end Behavioral;
