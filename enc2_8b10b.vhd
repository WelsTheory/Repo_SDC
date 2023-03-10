library ieee; 
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity enc_8b10b is port
(
   clk_i      : in    std_logic;  
   rst_n_i    : in    std_logic;   
   ctrl_i     : in    std_logic;   -- HI
   datain    : in    std_logic_vector(7 downto 0); 
   err_o      : out   std_logic;   
   dispar_o   : out   std_logic;   
   dataout  : out   std_logic_vector(9 downto 0)  
);
end enc_8b10b;


architecture rtl of enc_8b10b is


function f_reverse_vector (a: in std_logic_vector)
return std_logic_vector is
variable v_result: std_logic_vector(a'REVERSE_RANGE);
begin
    for i in a'RANGE loop
        v_result(i) := a(i);
    end loop;
    return v_result;
end; 


type t_state_type is (RD_MINUS, RD_PLUS);
type t_enc_5b_6b  is array(integer range <>)  of std_logic_vector(5 downto 0);
type t_enc_3b_4b  is array(integer range <>)  of std_logic_vector(3 downto 0);


constant c_enc_5b_6b_table : t_enc_5b_6b (0 to 31)  := 
                           ("100111",   -- D00
                            "011101",   -- D01 
                            "101101",   -- D02
                            "110001",   -- D03
                            "110101",   -- D04
                            "101001",   -- D05
                            "011001",   -- D06   
                            "111000",   -- D07
                            "111001",   -- D08
                            "100101",   -- D09
                            "010101",   -- D10
                            "110100",   -- D11
                            "001101",   -- D12
                            "101100",   -- D13
                            "011100",   -- D14
                            "010111",   -- D15
                            "011011",   -- D16
                            "100011",   -- D17
                            "010011",   -- D18
                            "110010",   -- D19
                            "001011",   -- D20
                            "101010",   -- D21
                            "011010",   -- D22
                            "111010",   -- D23
                            "110011",   -- D24
                            "100110",   -- D25
                            "010110",   -- D26
                            "110110",   -- D27
                            "001110",   -- D28
                            "101110",   -- D29
                            "011110",   -- D30
                            "101011");  -- D31
                       
constant c_disPar_6b : std_logic_vector(0 to 31) :=("11101000100000011000000110010111");
   
constant c_enc_3b_4b_table : t_enc_3b_4b (0 to 7) := 
                           ("1011",   -- Dx0
                            "1001",   -- Dx1
                            "0101",   -- Dx2
                            "1100",   -- Dx3
                            "1101",   -- Dx4
                            "1010",   -- Dx5
                            "0110",   -- Dx6
                            "1110");  -- DxP7
                                                 
 constant c_disPar_4b : std_logic_vector(0 to 7) :=("10001001");                                                        
   

signal s_ind5b			: integer := 0;                 
signal s_ind3b        	: integer := 0;                
signal s_val6bit		: std_logic_vector(5 downto 0); 
signal s_val6bit_n 		: std_logic_vector(5 downto 0); 
signal s_val4bit		: std_logic_vector(3 downto 0); 
signal s_val4bit_n 		: std_logic_vector(3 downto 0); 


signal s_dP6bit	        : std_logic := '0'; 
signal s_dP4bit         : std_logic := '0';

signal s_in_8b_reg                : std_logic_vector(7 downto 0); 
signal s_out_10b, s_out_10b_reg   : std_logic_vector(9 downto 0) := (others => '0'); 
signal s_err, s_err_reg           : std_logic;
signal s_dispar_reg, s_ctrl_reg   : std_logic; 

signal s_dpTrack : std_logic := '0';   
signal s_RunDisp : t_state_type;     

begin

s_ind3b      <= to_integer(unsigned(s_in_8b_reg(7 downto 5))); 
s_val4bit    <= c_enc_3b_4b_table(s_ind3b); 
s_dP4bit     <= c_disPar_4b(s_ind3b);
s_val4bit_n  <= not (s_val4bit);

s_ind5b      <= to_integer(unsigned(s_in_8b_reg(4 downto 0)));
s_val6bit    <= c_enc_5b_6b_table(s_ind5b);
s_dP6bit     <= c_disPar_6b(s_ind5b);
s_val6bit_n  <= not (s_val6bit);

dispar_o     <= s_dispar_reg;
err_o        <= s_err_reg;
dataout    <= s_out_10b_reg;


p_encoding: PROCESS (s_RunDisp, s_in_8b_reg, s_dP4bit, s_dP6bit, s_val4bit, 
                     s_val4bit_n, s_val6bit, s_val6bit_n, s_ctrl_reg) 

variable v_ctrl_code : std_logic_vector(9 downto 0) := (others => '0');

begin
        
     v_ctrl_code := (others => '0');
     s_err <= '0';
     s_dpTrack <= '0';
     if s_ctrl_reg = '1' then 
       case s_in_8b_reg is
           when "00011100" => v_ctrl_code := f_reverse_vector("0011110100");
           when "00111100" => v_ctrl_code := f_reverse_vector("0011111001");
           when "01011100" => v_ctrl_code := f_reverse_vector("0011110101");
           when "01111100" => v_ctrl_code := f_reverse_vector("0011110011");
           when "10011100" => v_ctrl_code := f_reverse_vector("0011110010");
           when "10111100" => v_ctrl_code := f_reverse_vector("0011111010");
           when "11011100" => v_ctrl_code := f_reverse_vector("0011110110");
           when "11111100" => v_ctrl_code := f_reverse_vector("0011111000");
           when "11110111" => v_ctrl_code := f_reverse_vector("1110101000");
           when "11111011" => v_ctrl_code := f_reverse_vector("1101101000");
           when "11111101" => v_ctrl_code := f_reverse_vector("1011101000");
           when "11111110" => v_ctrl_code := f_reverse_vector("0111101000");                   
           when others     => s_err <= '1';
               
       end case;
       if (s_RunDisp = RD_MINUS) then 
          s_out_10b <= v_ctrl_code;
       else
          s_out_10b <= not(v_ctrl_code);
          s_dpTrack <= '1';
       end if;       
    else        
         s_out_10b <= f_reverse_vector(s_val6bit & s_val4bit);
         case s_RunDisp is
             when RD_MINUS =>
                 if s_dP4bit = s_dP6bit then
                   if s_dP6bit = '1' then
                     s_out_10b(9 downto 6) <= f_reverse_vector(s_val4bit_n);
                   end if;
                 else
                   if s_dP4bit = '1' then
                       if ( (s_val6bit(2 downto 0) = "011") and 
                            (s_val4bit(3 downto 1) = "111") ) then
                         s_out_10b(9 downto 6) <= "1110"; 
                       end if;
                   else
                      if (s_val4bit = "1100") then
                         s_out_10b(9 downto 6) <= f_reverse_vector(s_val4bit_n);
                      end if;
                   end if;
                 end if;

            when RD_PLUS =>       
                 if s_dP6bit = '1' then
                   s_out_10b(5 downto 0) <= f_reverse_vector(s_val6bit_n);
                 else
                   if (s_val6bit = "111000") then
                       s_out_10b(5 downto 0) <= f_reverse_vector(s_val6bit_n);
                   end if;
                    if s_dP4bit = '1' then
                      if ( (s_val6bit(2 downto 0) = "100") and 
                           (s_val4bit(3 downto 1) = "111") ) then
                        s_out_10b(9 downto 6) <= "0001";
                      else
                        s_out_10b(9 downto 6) <= f_reverse_vector(s_val4bit_n); 
                      end if;
                    else
                       if (s_val4bit = "1100") then
                         s_out_10b(9 downto 6) <= f_reverse_vector(s_val4bit_n);
                       end if;
                    end if;
                 end if;
                 s_dpTrack <= '1';
                 
            when others => s_out_10b <= (others => '0'); -- never be executed            
         end case;        
    end if;
end PROCESS p_encoding;

disp_FSM_state: process(clk_i, rst_n_i)
begin
    	if rising_edge(clk_i) then
	       if (rst_n_i = '1') then
		      s_RunDisp <= RD_MINUS;
           else
		      case s_RunDisp is
				when RD_MINUS => 
               
				   if ( s_ctrl_reg xor s_dP6bit xor s_dP4bit ) /= '0' then
					  s_RunDisp <= RD_PLUS;
					end if;

				when RD_PLUS  =>

				   if ( s_ctrl_reg xor s_dP6bit xor s_dP4bit ) /= '0' then
					  s_RunDisp <= RD_MINUS;
					end if;

				when others => 

				   s_RunDisp <= RD_MINUS;
			 end case;

      	  if ( s_in_8b_reg(1 downto 0) /= "00" and s_ctrl_reg = '1') then
	         s_RunDisp <= s_RunDisp;
      	  end if;

       end if;   
    end if;                                           
end process;

inout_buffers: process(clk_i, rst_n_i)
begin
     if rising_edge(clk_i) then
       if(rst_n_i = '1') then
            s_ctrl_reg <= '0';
            s_in_8b_reg <= B"000_00000";
            s_dispar_reg <= '0';
            s_err_reg <= '0';
            s_out_10b_reg <= B"0000_000000";
       else
            s_ctrl_reg <= ctrl_i;
            s_in_8b_reg <= datain;
            s_dispar_reg <= s_dpTrack;
            s_err_reg <= s_err;
            s_out_10b_reg <= s_out_10b;
       end if;
     end if;
     
end process;     

end rtl;