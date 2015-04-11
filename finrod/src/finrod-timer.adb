
--with System.Unsigned_Types;   -- for arm only
with STM32F4.o7xx.Eth;
with STM32F4.O7xx.Registers;
--with Img_Uns;                 -- for arm only


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
   
   Timer1       : Time_type := (0, 0);
   timer2       : Time_type := (0, 0);
   timer3       : Time_type := (0, 0);
   
   
   ------------------------------------
   -- some operations on 'Time_Type' --
   -- part of interface;             --
   ------------------------------------
   
   function "+" (Left, Right : Time_Type) return Time_Type
   is
      use type Stm.Bits_32;
      D : Time_Type := (0, 0);
   begin
      D.Subsecs := Left.Subsecs + Right.Subsecs;
      if D.Subsecs > 999_999_999 then
	 D.Subsecs := (D.Subsecs - 1_000_000_000);
	 D.Seconds := Left.Seconds + Right.Seconds + 1;
      else
	 D.Seconds := Left.Seconds + Right.Seconds;
      end if;
      return D;
   end "+";
   
   function "-" (Left, Right : Time_Type) return Time_Type
   is
      use type Stm.Bits_32;
      D : Time_Type := (0, 0);
   begin
      D.Subsecs := Left.Subsecs - Right.Subsecs;
      if D.Subsecs > 999_999_999 then           --  2**31 then
	 D.Subsecs := (D.Subsecs + 1_000_000_000);-- and (2**31 - 1);
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
      if D.Seconds >= 2**31 then -- since we dont measure years (the msb is set)
	 return True;
      else return False;
      end if;
   end "<";
   
   function ">" (Left, Right : Time_Type) return Boolean
   is
      use type Stm.Bits_32;
      D : constant Time_Type := Right - Left;
   begin
      if D.Seconds >= 2**31 then -- since we dont measure years (the msb is set)
	 return True;
      else return False;
      end if;
   end ">";
   
   
   function Image (T : Time_Type) return String
   is
      S : constant String := 
	Stm.Bits_32'Image (T.Seconds) & " s," & 
	Stm.Bits_32'Image (T.Subsecs) & " ns.";
   begin
      return S;
   end Image;
   
   
   ----------------------------------
   -- the period measuring machine --
   ----------------------------------
      
   function Read_Time return Time_Type 
   is
      use type Stm.Bits_32;
      T : Time_Type;
   begin
      T.Seconds := R.Eth_Mac.Ptptshr;
      T.Subsecs := Stm.Bits_32 (R.Eth_Mac.Ptptslr.Stss);
      -- read it again to check for roll-over
      if  R.Eth_Mac.Ptptshr > T.Seconds then
	 if T.Subsecs > 444_444_445 then
	    return T;
	 else -- the bugger rolled over between readings
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
   
   
   ---------------
   --  timer 1  --
   ---------------
   
   -- starts this timer
   -- use done1 to check for completion
   procedure Start_Timer1 (Secs : Stm.Bits_32; Subsecs : Stm.Bits_32)
   is
      T : constant Time_Type := (Secs, Subsecs);
   begin
      Timer1 := Read_Time + T;
   end Start_Timer1;
   
   
   -- returns the fractional part of the time to go on timer 1
   function Time1_Subsecs_Togo return Stm.Bits_32
   is 
      T : constant Time_Type := Timer1 - Read_Time;
   begin
      return T.Subsecs;
   end Time1_Subsecs_Togo;
   
   
   -- check timer1 for completion
   -- use Start_Timer1 to start it.
   function Done1 return Boolean
   is
   begin
      if Read_Time > Timer1 then return True;
      else return False;
      end if;
   end Done1;
   
   
   ---------------
   --  timer 2  --
   ---------------
   
   -- starts this timer
   -- use done2 to check for completion
   procedure Start_Timer2 (Secs : Stm.Bits_32; Subsecs : Stm.Bits_32)
   is
      T : constant Time_Type := (Secs, Subsecs);
   begin
      Timer2 := Read_Time + T;
   end Start_Timer2;
   
   
   -- returns the fractional part of the time to go on timer 2
   function Time2_Subsecs_Togo return Stm.Bits_32
   is 
      T : constant Time_Type := Timer2 - Read_Time;
   begin
      return T.Subsecs;
   end Time2_Subsecs_Togo;
   
   
   -- check timer2 for completion
   -- use Start_Timer2 to start it.
   function Done2 return Boolean
   is
   begin
      if Read_Time > Timer2 then return True;
      else return False;
      end if;
   end Done2;
   
   
   ---------------
   --  timer 3  --
   ---------------
   
   -- starts this timer
   -- use done3 to check for completion
   procedure Start_Timer3 (Secs : Stm.Bits_32; Subsecs : Stm.Bits_32)
   is
      T : constant Time_Type := (Secs, Subsecs);
   begin
      Timer3 := Read_Time + T;
   end Start_Timer3;
   
   
   -- returns the fractional part of the time to go on timer 3
   function Time3_Subsecs_Togo return Stm.Bits_32
   is 
      T : constant Time_Type := Timer3 - Read_Time;
   begin
      return T.Subsecs;
   end Time3_Subsecs_Togo;
   
   
   -- check timer3 for completion
   -- use Start_Timer3 to start it.
   function Done3 return Boolean
   is
   begin
      if Read_Time > Timer3 then return True;
      else return False;
      end if;
   end Done3;
   
   
   ------------------------
   -- Init               --
   -- gets the ptp timer --
   -- going.             --
   ------------------------
   
   procedure Init
   is
      use type Stm.Bits_1;
      Macimr_Tmp       : Eth.Macimr_Register  := R.Eth_Mac.Macimr;
      Ptpt_Control_Tmp : Eth.PTPTSCR_Register := R.Eth_Mac.PTPTSCR;
      PTP_SSIR_Tmp     : Eth.PTPSSIR_Register := R.Eth_Mac.PTPSSIR;
      Ptptslur_Tmp     :  Eth.Ptptslur_Register;
   begin
      
      -- no interrupts
      Macimr_Tmp.TSTIM       := Eth.Int_Disabled;
      R.Eth_Mac.Macimr       := Macimr_Tmp; -- write it
      
      -- enable time stamping
      Ptpt_Control_Tmp.Tse   := Eth.Enabled;
      Ptpt_Control_Tmp.TSSSR := Eth.On;  --  999 999 999  roll over
      Ptpt_Control_Tmp.TSSIPV4FE := Eth.Enabled;
      Ptpt_Control_Tmp.TSSARFE   := Eth.Enabled;
      --  and some others, wait for later
      Ptpt_Control_Tmp.TSPTPPSV2E := Eth.Enabled;
      -- prepare the updat flag (if needed at all)
      Ptpt_Control_Tmp.Tsaru := Eth.Off;
      R.Eth_Mac.PTPTSCR      := Ptpt_Control_Tmp; -- write it
      
      -- set the time increase per tick --
      -- 10^9 - 1 divisions in the counter
      -- so for 20 nsec resolution the increment must be 20
      PTP_SSIR_Tmp.Stssi     := 20;
      R.Eth_Mac.PTPSSIR      := PTP_SSIR_Tmp;  -- write it;

      -- figute out the update frequency --
      -- for each tick to be 20 nsecs the update frequency must be: 
      --   10^9 / 20 = 50_000_000 Hz
      -- the addent then must be 
      -- 2^32 * 50_000_000 / 168_000_000 = 1_278_264_076
      R.Eth_Mac.PTPTSAR      := 1_278_264_076; -- write it direct, its 32 bits
      
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
   
end Finrod.Timer;
