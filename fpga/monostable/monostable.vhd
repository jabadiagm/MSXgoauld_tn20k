--one shot timer, 0.5s with clock = 27 MHz
LIBRARY ieee;
USE ieee.std_logic_1164.all;
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY monostable IS
	PORT
	(
		pulse_in	: IN STD_LOGIC;
		clock		: IN STD_LOGIC;
		pulse_out	: OUT STD_LOGIC;
        pulse_out_n	: OUT STD_LOGIC
	);
END monostable;


ARCHITECTURE rtl OF monostable IS

	signal counting : std_logic:='0';
	signal counter : std_logic_vector (23 downto 0):= (others => '0');

BEGIN

  process(clock) is

  begin
    if rising_edge(clock) then
		if counting = '0' then
			if pulse_in = '1' then
				counting <= '1';
			end if;
            pulse_out <= '0';
            pulse_out_n <= '1';
            counter <= (others => '0');
		else
			counter <= counter + 1;
			if counter > 13500000 then
				counting <= '0';
			end if;
            pulse_out <= '1';
            pulse_out_n <= '0';
		end if;
	end if;

  end process;


END rtl;

