LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY denoise_low8 IS
	PORT
	(
		data8_in	: IN STD_LOGIC_VECTOR(7 downto 0);
		clock		: IN STD_LOGIC  := '1';
		data8_out	: OUT STD_LOGIC_VECTOR(7 downto 0) 
	);
END denoise_low8;


ARCHITECTURE rtl OF denoise_low8 IS

	component denoise_low
		port (
			data_in		: IN STD_LOGIC;
			clock		: IN STD_LOGIC  := '1';
			data_out	: OUT STD_LOGIC 
		);
	end component;	

BEGIN

	denoise:
		for I in 0 to 7 generate
		begin
		  denoise8 : denoise_low
			 port map (
				data_in => data8_in(I),
				clock => clock,
				data_out => data8_out(I)			 
				);
		end generate;


END rtl;

