

with STM32F4;

package Timer is
   
   --pragma Warnings (Off, "*internal GNAT unit");
   ---subtype Time_Interval is Bits_64;
   -- I think this is in nanoseconds, but do check
   -- units: 1 masterclock period = 5.95238095238e-9 seconds
   -- for a 168_000_000 clock.
   
   type Time_Type is record
      Seconds : Stm32F4.Bits_32;
      Subsecs : Stm32F4.Bits_32;
   end record;
   
   function "-" (Left, Right : Time_Type) return Time_Type;
   
   function "<" (Left, Right : Time_Type) return Boolean;
   
   function ">" (Left, Right : Time_Type) return Boolean;
   
   function Image (T : Time_Type) return String;
   
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
   
end Timer;

   
