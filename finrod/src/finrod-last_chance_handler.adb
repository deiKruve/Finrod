 
with STM32F4.O7xx.Registers;
with STM32F4.Gpio;

package body Finrod.Last_Chance_Handler is
   
   package Gpio renames STM32F4.Gpio;
   package R    renames STM32F4.O7xx.Registers;
   
   
   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer) is
      pragma Unreferenced (Msg, Line);
      use type STM32F4.Word;
      procedure OS_Exit (Status : Integer);
      pragma Import (C, OS_Exit, "exit");
      pragma No_Return (OS_Exit);
   begin
      R.GPIOC.Bsrr := R.GPIOC.Bsrr or 2 ** Gpio.Bs13; -- led off
      --  No return procedure.
      OS_Exit (1);
   end Last_Chance_Handler;

end Finrod.Last_Chance_Handler;
