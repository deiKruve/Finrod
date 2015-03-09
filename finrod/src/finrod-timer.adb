
--with System.Unsigned_Types;
with STM32F4.o7xx.Eth;
with STM32F4.O7xx.Registers;
--with Img_Uns;

package body Finrod.Timer is
   package Stm renames STM32F4;
   package Eth renames STM32F4.o7xx.Eth;
   package R   renames STM32F4.O7xx.Registers;
   --package Unsigned renames Img_Uns;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
    
   Start_Time   : Time_type := (0, 0);
   Min_Duration : Time_type := (0, 0);
   Max_duration : Time_type := (0, 0);
   
   
   ------------------------------------
   -- some operations on 'Time_Type' --
   -- part of interface;             --
   ------------------------------------
   
   function "-" (Left, Right : Time_Type) return Time_Type
   is
      use type Stm.Bits_32;
      D : Time_Type := (0, 0);
   begin
      D.Subsecs := Left.Subsecs - Right.Subsecs;
      if D.Subsecs > 2**31 then
	 D.Subsecs := D.Subsecs + 2**31;
	 D.Seconds := Left.Seconds - Right.Seconds - 1;
      else
	 D.Seconds := Left.Seconds - Right.Seconds;
      end if;
      return D;
   end "-";
   
   function "<" (Left, Right : Time_Type) return Boolean
   is
      use type Stm.Bits_32;
      D : constant Time_Type := Left - Right;
   begin
      if D.Seconds > 2**31 then -- since we dont measure years (the msb is set)
	 return True;
      else return False;
      end if;
   end "<";
   
   function ">" (Left, Right : Time_Type) return Boolean
   is
      use type Stm.Bits_32;
      D : constant Time_Type := Right - Left;
   begin
      if D.Seconds > 2**31 then -- since we dont measure years (the msb is set)
	 return True;
      else return False;
      end if;
   end ">";
   
   
   function Image (T : Time_Type) return String
   is
      S : constant String := 
	--Unsigned.Image (System.Unsigned_Types.Unsigned (T.Seconds)) & "." & 
	--Unsigned.Image (System.Unsigned_Types.Unsigned (T.Subsecs));
	Stm.Bits_32'Image (T.Seconds) & "." & 
	Stm.Bits_32'Image (T.Subsecs);
   begin
      return S;
   end Image;
   
   
   ---------------
   -- interface --
   ---------------
      
   function Read_Time return Time_Type 
   is
      use type Stm.Bits_32;
      T : Time_Type;
   begin
      T.Seconds := R.Eth_Mac.Ptptshr;
      T.Subsecs := Stm.Bits_32 (R.Eth_Mac.Ptptslr.Stss);
      -- read it again to check for roll-over
      if  R.Eth_Mac.Ptptshr > T.Seconds then
	 if T.Subsecs > 2**30 then
	    return T;
	 else -- the bugger rolled over
	    T.Seconds := T.Seconds + 1;
	    return T;
	 end if;
      end if;
      return T;
   end Read_Time;
	
  
   -- R.Eth_Mac is the eth struct
   
   -- record the start time of some event and save it --
   procedure Start_Timer
   is
   begin
      Start_Time := Read_Time;
   end Start_Timer;
   
   
   -- record the end time of some event and find the time_interval
   -- since the last start_time.
   -- then record it in min_duration if it is shorter than 
   -- any before, and
   -- record it in max_duration if it is longer than any before
   procedure Stop_Timer
   is
      Delta_Time : Time_Type;
   begin
      Delta_Time := Read_time - Start_Time;
      if Delta_Time < Min_Duration then
	 Min_Duration := Delta_Time;
      elsif Delta_Time > Max_Duration then
	 Max_Duration := Delta_Time;
      end if;
   end Stop_Timer;
   
   
   -- report the smallest time measured for an event duration
   function Report_Min_Duration return Time_Type
   is
   begin
      return Min_Duration;
   end Report_Min_Duration;
   
   
   -- report the biggest time measured for an event duration.
   function Report_Max_Duration return Time_Type
   is
   begin
      return Max_Duration;
   end Report_Max_Duration;

   
   -- resets all variables and accumulators;
   procedure Reset 
   is
      use type Stm.Bits_32;
   begin
      Min_Duration.Seconds := 2**31;
      Max_Duration.seconds := 0;
      Max_Duration.Subsecs := 0;
   end Reset;
   
   
   -- starts this timer
   -- use done1 to check for completion
   procedure Start_Timer1 (Secs : Stm.Bits_31; Subsecs : Stm.Bits_32)
   is
   begin
      null;
   end Start_Timer1;
   
   
   -- check timer1 for completion
   -- use Start_Timer1 to start it.
   function Done1 return Boolean
   is (True);
   
   
   procedure Init
   is
      use type Stm.Bits_1;
      Macimr_Tmp       : Eth.Macimr_Register  := R.Eth_Mac.Macimr;
      Ptpt_Control_Tmp : Eth.PTPTSCR_Register := R.Eth_Mac.PTPTSCR;
      PTP_SSIR_Tmp     : Eth.PTPSSIR_Register := R.Eth_Mac.PTPSSIR;
      --PTPTSAR_Tmp      : new Eth.PTPTSAR_Register := 3_652_183_076;
      Ptptslur_Tmp     :  Eth.Ptptslur_Register;
   begin
      -- no interrupts
      Macimr_Tmp.TSTIM       := Eth.Int_Disabled;
      R.Eth_Mac.Macimr       := Macimr_Tmp; -- write it
      
      -- enable time stamping
      Ptpt_Control_Tmp.Tse   := Eth.Enabled;
      R.Eth_Mac.PTPTSCR      := Ptpt_Control_Tmp; -- write it
      
      -- set the time increase per tick --
      -- 10^9/2^31 nsecs / division in the counter
      -- so for 7 nsecs resolution add (7 * 2^31 / 10^9) per tick (scales to 7)
      PTP_SSIR_Tmp.Stssi     := 15;
      R.Eth_Mac.PTPSSIR      := PTP_SSIR_Tmp;  -- write it;
      
      -- figute out the update frequency --
      -- for each tick to be 7 nsecs the update frequency must be: 
      --    10^9 / 7 = 142_857_143 Hz.
      -- the addent then must be 
      --    2^32 * 142_857_143 / 168_000_000 = 3_652_183_076
      R.Eth_Mac.PTPTSAR      := 3_652_183_076; -- write it direct its 32 bits
      
      -- update it, and wait for it to be done
      Ptpt_Control_Tmp.Tsaru := Eth.Update;
      R.Eth_Mac.PTPTSCR      := Ptpt_Control_Tmp; -- write it
      while Ptpt_Control_Tmp.Tsaru /= Eth.Off loop
	 Ptpt_Control_Tmp    := R.Eth_Mac.PTPTSCR;
      end loop;
      
      -- we want fine mode
      Ptpt_Control_Tmp.Tsfcu := Eth.Fine;
      R.Eth_Mac.Ptptscr      := Ptpt_Control_Tmp; -- write it
      
      -- starting time value
      R.Eth_Mac.Ptptshur     := 0; -- hi update reg
      Ptptslur_Tmp.TSUPNS    := 0;
      Ptptslur_Tmp.TSUSS     := 0;
      R.Eth_Mac.Ptptslur     := Ptptslur_Tmp; -- lo update register
      
      -- and initialize the machine
      Ptpt_Control_Tmp.TSSTI := Eth.Init;
      R.Eth_Mac.PTPTSCR      := Ptpt_Control_Tmp; -- write it
   end Init;
   
   
begin
   Reset;
   Init;
end Finrod.Timer;
