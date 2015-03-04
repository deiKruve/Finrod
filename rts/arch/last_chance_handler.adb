package body Last_Chance_Handler is

   -------------------------
   -- Last_Chance_Handler --
   -------------------------

   procedure Last_Chance_Handler (Msg : System.Address; Line : Integer) is
      pragma Unreferenced (Msg, Line);

      procedure OS_Exit (Status : Integer);
      pragma Import (C, OS_Exit, "exit");
      pragma No_Return (OS_Exit);
      --  jdk.procedure OS_Exit (Status : Integer) with No_Return
      --  is
      --     pragma Unreferenced (Status);
      --  begin
      --     loop
      --        null;
      --     end loop;
      --  end OS_Exit;
   begin
      --  No return procedure.
      OS_Exit (1);
   end Last_Chance_Handler;

end Last_Chance_Handler;
