--clean data for active general purpose signals
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY denoise IS
	PORT
	(
		data_in		: IN STD_LOGIC;
		clock		: IN STD_LOGIC;
		data_out	: OUT STD_LOGIC 
	);
END denoise;


ARCHITECTURE rtl OF denoise IS

	signal data_prev : std_logic:='1';
	signal data_prev_prev : std_logic:='1';

BEGIN

  denoise_proc: process(clock) is

  begin
    if rising_edge(clock) then
		data_prev <= data_in;
		data_prev_prev <= data_prev;
		if data_prev_prev = '0' and data_prev = '0' and data_in = '0' then
			data_out <= '0';
		elsif data_prev_prev = '1' and data_prev = '1' and data_in = '1' then
			data_out <= '1';
		end if;
	end if;

  end process denoise_proc;


END rtl;

