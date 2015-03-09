
--with System.BB.Board_Support;

with STM32F4;

-- this is a dummy module, for compiling on x86

package Finrod.Timer is
   
   type Time_Type is record
      Seconds : Stm32F4.Bits_32;
      Subsecs : Stm32F4.Bits_32;
   end record;
   
   function "-" (Left, Right : Time_Type) return Time_Type;
   
   function "<" (Left, Right : Time_Type) return Boolean;
   
   function ">" (Left, Right : Time_Type) return Boolean;
   
   function Image (T : Time_Type) return String;
   
   function Read_Time return Time_Type; 
   -- returns the time since eth_init
   
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
   
   procedure Start_Timer1 (Secs : Stm32f4.Bits_31; Subsecs : Stm32f4.Bits_32);
   -- starts timer1 
   -- input Secs    : number of seconds to run
   --       subSecs : nano seconds to run
   
   function Done1 return Boolean with Inline;
   -- Returns True when timer 1 has run down 
   
   
   procedure Init;
   -- initializes the eth ptp structure timer.
   -- so we may log from here on.
   
end Finrod.Timer;

   
