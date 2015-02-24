with Finrod.Nmt_Init;      
pragma Unreferenced (Finrod.Nmt_Init);
--  The Finrod.Nmt_Init package contains the task that actually starts and 
--  controls the app so
--  although it is not referenced directly in the main procedure, we need it
--  in the closure of the context clauses so that it will be included in the
--  executable.

with Board1_App;
pragma Unreferenced (Board1_App);
-- The Board1_App package is where all the user action is. It registers 
-- itself with Finrod.Nmt_Init, so we need to load and elaborate it now.

with Last_Chance_Handler;  
pragma Unreferenced (Last_Chance_Handler);
--  The "last chance handler" is the user-defined routine that is called when
--  an exception is propagated. We need it in the executable, therefore it
--  must be somewhere in the closure of the context clauses.

with System;

procedure Board1 is
   pragma Priority (System.Priority'First);
begin
   loop
      null;
   end loop;
end Board1;
