-- ExternalMemory.VHD
-- 2024.11.02
-- uses intel's altsyncram to create a memory module
-- 16 bits of address space, 16 bits of data space

LIBRARY ieee;
LIBRARY altera_mf;
LIBRARY lpm;

USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
USE ieee.std_logic_unsigned.ALL;
USE altera_mf.altera_mf_components.ALL;
USE lpm.lpm_components.ALL;

ENTITY ExternalMemory IS
	PORT (
		RESETN,
		CLOCK,
		EXTMEMADDR_EN,
		EXTMEMDATA_EN,
		EXTMEMCONFIG_EN,
		EXTMEMERR_EN,
		EXTMEMID_EN,
		EXTMEMBOUNDS_EN,
		IO_WRITE : IN STD_LOGIC;
		IO_DATA : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		ERR_OUT : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		BOUND_B : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		BOUND_A : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		ID_A_OUT: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		ID_B_OUT: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		STATE_OUT: OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
	);
END ExternalMemory;

ARCHITECTURE a OF ExternalMemory IS
	SIGNAL id : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL id_a : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL id_b : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL bound_in_a : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL bound_out_a : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL bound_in_b : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL bound_out_b : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL address : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL data_in : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL data_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL inter_out : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL err : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL config : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL wren : STD_LOGIC;
	SIGNAL wren_bound_a : STD_LOGIC;
	SIGNAL wren_bound_b : STD_LOGIC;

	SIGNAL write_inc_en : STD_LOGIC;
	SIGNAL read_inc_en : STD_LOGIC;
	SIGNAL write_inc_dir : STD_LOGIC;
	SIGNAL read_inc_dir : STD_LOGIC;
  SIGNAL byte_en : STD_LOGIC_VECTOR(1 DOWNTO 0);
	SIGNAL inc_val : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL inc_val_shifted : STD_LOGIC_VECTOR(15 DOWNTO 0);

	TYPE state_type IS (
		idle,
		incrementing,
		decrementing,
		check,
		stop
	);
	SIGNAL state : state_type;
BEGIN
	-- use altsyncram component for memory
	-- the way this works is if EXTMEMADDR_EN is high, then the memory is being addressed
	-- that means that IO_DATA stores the address
	-- if EXTMEMDATA_EN is high, then the memory is being written to
	-- that means that IO_DATA stores the data to be written
	memory_component : altsyncram
	GENERIC MAP(
		operation_mode => "SINGLE_PORT",
		width_a => 16,
		widthad_a => 16,
		numwords_a => 2 ** 16,
		outdata_reg_a => "UNREGISTERED",
		init_file => "ExternalMemory.mif",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		intended_device_family => "MAX 10"
	)
	PORT MAP(
		clock0 => CLOCK,
		address_a => address,
		data_a => data_in,
		wren_a => wren,
		q_a => inter_out
	);

	-- use altsyncram component for bounds
	-- the way this works is if EXTMEMADDR_EN is high, then the memory is being addressed
	-- that means that IO_DATA stores the address
	-- if EXTMEMDATA_EN is high, then the memory is being written to
	-- that means that IO_DATA stores the data to be written
	bounds_memory_component : altsyncram
	GENERIC MAP(
		operation_mode => "BIDIR_DUAL_PORT",
		width_a => 16,
		widthad_a => 16,
		numwords_a => 2 ** 16,
		outdata_reg_a => "UNREGISTERED",
		width_b => 16,
		widthad_b => 16,
		numwords_b => 2 ** 16,
		outdata_reg_b => "UNREGISTERED",
		init_file => "ExternalMemoryBounds.mif",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		intended_device_family => "MAX 10"
	)
	PORT MAP(
		clock0 => CLOCK,
		clock1 => CLOCK,
		address_a => id_a,
		data_a => bound_in_a,
		wren_a => wren_bound_a,
		q_a => bound_out_a,
		address_b => id_b,
		data_b => bound_in_b,
		wren_b => wren_bound_b,
		q_b => bound_out_b
	);

	-- Use Intel LPM IP to create tristate drivers
	IO_BUS_DATA : lpm_bustri
	GENERIC MAP(
		lpm_width => 16
	)
	PORT MAP(
		data => data_out,
		enabledt => NOT IO_WRITE AND EXTMEMDATA_EN,
		tridata => IO_DATA
	);

	-- Use Intel LPM IP to create tristate drivers
	IO_BUS_CONFIG : lpm_bustri
	GENERIC MAP(
		lpm_width => 16
	)
	PORT MAP(
		data => config,
		enabledt => NOT IO_WRITE AND EXTMEMCONFIG_EN,
		tridata => IO_DATA
	);

	-- Use Intel LPM IP to create tristate drivers
	IO_BUS_ERR : lpm_bustri
	GENERIC MAP(
		lpm_width => 16
	)
	PORT MAP(
		data => err,
		enabledt => NOT IO_WRITE AND EXTMEMERR_EN,
		tridata => IO_DATA
	);

	inc_val(2 DOWNTO 0) <= config(2 DOWNTO 0);
	inc_val(15 DOWNTO 3) <= (OTHERS => '0');
  inc_val_shifted <= '0' & inc_val(15 DOWNTO 1);
	write_inc_en <= config(6);
	read_inc_en <= config(5);
	write_inc_dir <= config(4);
	read_inc_dir <= config(3);
  byte_en(1 DOWNTO 0) <= config(8 DOWNTO 7);

	 WITH byte_en SELECT data_out <=
		"00000000" & inter_out(7 DOWNTO 0) WHEN "01",
		"00000000" & inter_out(15 DOWNTO 8) WHEN "10",
		inter_out WHEN OTHERS;

	PROCESS (CLOCK, RESETN)
	BEGIN
		IF RESETN = '0' THEN
			address <= (OTHERS => '0');
			data_in <= (OTHERS => '0');
			err <= (OTHERS => '0');
			config <= (OTHERS => '0');
			state <= idle;
			wren <= '0';

			id_a <= (OTHERS => '0');
			bound_in_a <= (OTHERS => '0');
			wren_bound_a <= '0';
			id_b <= (OTHERS => '0');
			bound_in_b <= (OTHERS => '0');
			wren_bound_b <= '0';
			id <= (OTHERS => '0');
		ELSIF rising_edge(CLOCK) THEN
			IF EXTMEMADDR_EN = '1' AND IO_WRITE = '1' AND state = idle THEN
				address <= IO_DATA;
				state <= stop;
			END IF;

			IF EXTMEMID_EN = '1' AND IO_WRITE = '1' AND state = idle THEN
				-- enforce that the ID can never be 0xFFFF
				IF IO_DATA = X"FFFF" THEN
					err <= X"0002";
				ELSE
					id <= IO_DATA;
				END IF;
				state <= stop;
			END IF;

			IF EXTMEMBOUNDS_EN = '1' AND IO_WRITE = '1' THEN
				IF state = idle THEN
					id_a <= id;
					state <= check;

					IF id = X"FFFE" THEN
						id_b <= id + 1;
					ELSE
						id_b <= id + 2;
					END IF;

				ELSIF state = check THEN
					IF (bound_out_a <= IO_DATA) AND (NOT (bound_out_a = X"0000") OR id_a = X"0000") AND (bound_out_b >= IO_DATA OR bound_out_b = X"0000") THEN
						state <= stop;
						id_a <= id;
						id_b <= id + 1;
						wren_bound_b <= '1';

						IF IO_DATA = X"0000" THEN
							bound_in_b <= bound_in_a;
						ELSE
							bound_in_b <= IO_DATA;
						END IF;
					ELSE
						err <= X"0002";
					END IF;
					state <= stop;
				ELSE
					wren_bound_b <= '0';
				END IF;
			END IF;
			IF EXTMEMDATA_EN = '1' AND state = idle THEN
				IF id_b = X"0000" OR bound_out_b = X"0000" OR (address < bound_out_b AND bound_out_a <= address) THEN
					IF byte_en = "01" THEN
						data_in(7 DOWNTO 0) <= IO_DATA(7 DOWNTO 0);
					ELSIF byte_en = "10" THEN
						data_in(15 DOWNTO 8) <= IO_DATA(7 DOWNTO 0); 
					ELSE
						data_in <= IO_DATA;                   
					END IF;
          
					IF IO_WRITE = '1' THEN
						wren <= '1';
					ELSE
						wren <= '0';
					END IF;

					err <= X"0000";

					IF write_inc_en = '1' AND IO_WRITE = '1' THEN
						IF write_inc_dir = '1' THEN
							state <= decrementing;
						ELSE
							state <= incrementing;
						END IF;

					ELSIF read_inc_en = '1' AND IO_WRITE = '0' THEN
						IF read_inc_dir = '1' THEN
							state <= decrementing;
						ELSE
							state <= incrementing;
						END IF;
					ELSE
							state <= stop;
					END IF;
				ELSE
					err <= X"0003";
					wren <= '0';
					state <= stop;
				END IF;
			ELSE
				wren <= '0';
			END IF;

			IF EXTMEMCONFIG_EN = '1' AND IO_WRITE = '1' AND state = idle THEN
				config <= IO_DATA;
				state <= stop;
			END IF;

			IF EXTMEMERR_EN = '1' AND IO_WRITE = '1' AND state = idle THEN
				err <= X"0000";
				state <= stop;
			END IF;


			IF state = incrementing AND EXTMEMDATA_EN = '0' THEN
				state <= stop;
				CASE byte_en IS
					WHEN "01" =>
						IF inc_val(0) = '1' THEN
							config(8 DOWNTO 7) <= "10";
						END IF;
						address <= address + inc_val_shifted;
						IF inc_val_shifted > (X"FFFF" - address) THEN
							err <= X"0001";
						END IF;
					WHEN "10" =>
						IF inc_val(0) = '1' THEN
							config(8 DOWNTO 7) <= "01";
							address <= address + inc_val_shifted + 1;
							IF inc_val_shifted + 1 > (X"FFFF" - address) THEN
								err <= X"0001";
							END IF;
						ELSE
							address <= address + inc_val_shifted;
							IF inc_val_shifted > (X"FFFF" - address) THEN
								err <= X"0001";
							END IF;
						END IF;
					WHEN OTHERS =>
						address <= address + inc_val;
						IF inc_val > (X"FFFF" - address) THEN
							err <= X"0001";
						END IF;
				END CASE;
			END IF;
				
			IF state = decrementing AND EXTMEMDATA_EN = '0' THEN
				state <= stop;
				CASE byte_en IS
					WHEN "01" =>
						IF inc_val(0) = '1' THEN
							config(8 DOWNTO 7) <= "10";
							address <= address - inc_val_shifted - 1;
							IF inc_val_shifted + 1 > address THEN
								err <= X"FFFF";
							END IF;
						ELSE
							address <= address - inc_val_shifted;
							IF inc_val_shifted > address THEN
								err <= X"FFFF";
							END IF;
						END IF;
					WHEN "10" =>
						IF inc_val(0) = '1' THEN
							config(8 DOWNTO 7) <= "01";
						END IF;
						address <= address - inc_val_shifted;
						IF inc_val_shifted > address THEN
							err <= X"FFFF";
						END IF;
					WHEN OTHERS =>
						address <= address - inc_val;
						IF inc_val > address THEN
							err <= X"FFFF";
						END IF;
				END CASE;
			END IF;

		  IF EXTMEMADDR_EN = '0' AND
			  EXTMEMID_EN = '0' AND
			  EXTMEMBOUNDS_EN = '0' AND
			  EXTMEMDATA_EN = '0' AND
			  EXTMEMCONFIG_EN = '0' AND
			  EXTMEMERR_EN = '0' AND
			  state = stop THEN
			  state <= idle;
		  END IF;
	  END IF;
  END PROCESS;
ERR_OUT <= err;
BOUND_A <= bound_out_a;
BOUND_B <= bound_out_b;
ID_A_OUT <= id_a;
ID_B_OUT <= id_b;
WITH state SELECT STATE_OUT <=
	"000" WHEN idle,
	"001" WHEN check,
	"010" WHEN incrementing,
	"011" WHEN decrementing,
	"100" WHEN stop;
END a;