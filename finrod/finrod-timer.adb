
-- this is a dummy module, for compiling on x86

package body Finrod.Timer is
   
   package Stm  renames  STM32F4;
   
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
   
   function Report_Min_Duration return Time_Interval
   is (0);

   
   function Report_Max_Duration return Time_Interval
   is (0);

   
   procedure Reset
   is
   begin
      null;
   end Reset;
   
   procedure Start_Timer1 (Secs : Stm.Bits_31; Subsecs : Stm.Bits_32)
   is
   begin
      null;
   end Start_Timer1;
   
   function Done1 return Boolean
   is (True);

   
end Finrod.Timer;
