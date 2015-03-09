with System;

package Finrod.Last_Chance_Handler is

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer);
   -- msg is a pointer to a string, line is presumbly the length.
   -- it is not clear in the original -- jdk
   pragma Export (C, Last_Chance_Handler, "__gnat_last_chance_handler");
   pragma No_Return (Last_Chance_Handler);

end Finrod.Last_Chance_Handler;
