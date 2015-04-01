
--with System.BB.Board_Support;

with STM32F4;

package Finrod.Timer is
   
   type Time_Type is record
      Seconds : Stm32F4.Bits_32;
      Subsecs : Stm32F4.Bits_32;
   end record;
   
   
   ------------------------------------
   -- some operations on 'Time_Type' --
   ------------------------------------
   
   function "+" (Left, Right : Time_Type) return Time_Type;
   
   function "-" (Left, Right : Time_Type) return Time_Type;
   
   function "<" (Left, Right : Time_Type) return Boolean;
   
   function ">" (Left, Right : Time_Type) return Boolean;
   
   function Image (T : Time_Type) return String;
   
   function Read_Time return Time_Type; 
   -- returns the time since timer_init
   
   
   ----------------------------------
   -- the period measuring machine --
   ----------------------------------
   
   procedure Start_Timer;
   -- record the start time of some event and save it.
   
   
   procedure Stop_Timer;
   -- record the end time of some event and find the time_interval
   -- since the last start_time.
   -- then record it in min_duration if it is shorter than 
   -- any before, and
   -- record it in max_duration if it is longer than any before.
   
   
   function Report_Min_Duration 
     return Time_Type;
   -- report the smallest time measured for an event duration
   
   
   function Report_Max_Duration 
     return Time_Type;
   -- report the biggest time measured for an event duration.
   
   
   procedure Reset;
   -- resets all variables and accumulators;
   
 
   ---------------
   --  timer 1  --
   ---------------
   
   procedure Start_Timer1 (Secs : Stm32f4.Bits_32; Subsecs : Stm32f4.Bits_32);
   -- starts timer1 
   -- input Secs    : number of seconds to run
   --       subSecs : nano seconds to run
   
   function Time1_Subsecs_Togo return Stm32f4.Bits_32 with Inline;
   -- returns the fractional part of the time to go on timer 1
   
   function Done1 return Boolean with Inline;
   -- Returns True when timer 1 has run down 
   
   
   ---------------
   --  timer 2  --
   ---------------
   
   procedure Start_Timer2 (Secs : Stm32f4.Bits_32; Subsecs : Stm32f4.Bits_32);
   -- starts timer2 
   -- input Secs    : number of seconds to run
   --       subSecs : nano seconds to run
   
   function Time2_Subsecs_Togo return Stm32f4.Bits_32 with Inline;
   -- returns the fractional part of the time to go on timer 2
   
   function Done2 return Boolean with Inline;
   -- Returns True when timer 2 has run down 
   
   
   ---------------
   --  timer 3  --
   ---------------
   
   procedure Start_Timer3 (Secs : Stm32f4.Bits_32; Subsecs : Stm32f4.Bits_32);
   -- starts timer3 
   -- input Secs    : number of seconds to run
   --       subSecs : nano seconds to run
   
   function Time3_Subsecs_Togo return Stm32f4.Bits_32 with Inline;
   -- returns the fractional part of the time to go on timer 3
     
   function Done3 return Boolean with Inline;
   -- Returns True when timer 3 has run down 
   
   
   ------------------------
   -- Init               --
   -- gets the ptp timer --
   -- going.             --
   ------------------------
   
   procedure Init;
   -- initializes the eth ptp structure timer.
   -- so we may log and use the timers from here on.
   
end Finrod.Timer;

   
