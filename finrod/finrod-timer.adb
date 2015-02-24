

--with System.BB.Board_Support;

package body Finrod.Timer is
   
   pragma Warnings (Off, "*internal GNAT unit");
   
   package Bbbs renames System.BB.Board_Support;
   
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   Start_Time   : Time_Interval := 0;
   Min_Duration : Time_Interval := 0;
   Max_duration : Time_Interval := 0;
   
   
   ---------------
   -- interface --
   ---------------
   
   
   -- record the start time of some event and save it --
   procedure Start_Timer
   is
   begin
      Start_Time := Bbbs.Read_Clock;
      null;
   end Start_Timer;
   
   
   -- record the end time of some event and find the time_interval
   -- since the last start_time.
   -- then record it in min_duration if it is shorter than 
   -- any before, and
   -- record it in max_duration if it is longer than any before
   procedure Stop_Timer
   is
      use type Bbbs.Timer_Interval;
      Delta_Time : Time_Interval;
   begin
      Delta_Time := Bbbs.Read_Clock - Start_Time;
      if Delta_Time < Min_Duration then
	 Min_Duration := Delta_Time;
      elsif Delta_Time > Max_Duration then
	 Max_Duration := Delta_Time;
      end if;
      null;
   end Stop_Timer;
   
   
   -- report the smallest time measured for an event duration
   function Report_Min_Duration return Time_Interval
   is
   begin
      return Min_Duration;
   end Report_Min_Duration;
   
   
   -- report the biggest time measured for an event duration.
   function Report_Max_Duration return Time_Interval
   is
   begin
      return Max_Duration;
   end Report_Max_Duration;

   
   -- resets all variables and accumulators;
   procedure Reset 
   is
   begin
      Min_Duration := Bbbs.Max_Timer_Interval;
      Max_Duration := 0;
      null;
   end Reset;
   
begin
   Reset;
end Finrod.Timer;
