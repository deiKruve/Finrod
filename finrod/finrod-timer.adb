
-- this is a dummy module, for compiling on x86

package body Finrod.Timer is
   
   procedure Start_Timer
   is
   begin
      null;
   end Start_Timer;
   
   procedure Stop_Timer
   is
   begin
      null;
   end Stop_Timer;
   
   function Report_Min_Duration 
     return Time_Interval
   is
   begin
      return 0;
   end Report_Min_Duration;
   
   function Report_Max_Duration 
     return Time_Interval
   is
   begin
      return 0;
   end Report_Max_Duration;
   
   procedure Reset
   is
   begin
      null;
   end Reset;
   
end Finrod.Timer;
