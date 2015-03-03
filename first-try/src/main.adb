
--pragma Restrictions (Max_tasks => 1);
--pragma restrictions (no_secondary_stack);
pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");
pragma Warnings (Off, "*is not referenced");

with Machine_Reset;
with Setup_Pll;
with Last_Chance_Handler;
with Memory_Compare;
with Memory_Copy;
with Memory_Move;
with Memory_Set;
with Secondary_Stack;

with Init;
with Sermon;
with Timer;

--package body Mainloop is

   procedure Main --Tryit 
   is
      use type Sermon.Uart_Data_Type;
      First, M : Sermon.Srd_Index_Type;
      N        : Integer range -1 .. 10;
   begin
      
      Init.Init_Pins;
      Sermon.Send_String ("Hallo I am up!");-----------------------
      loop
	 Timer.Start_Timer;-------------------for testing
	 if Sermon.Uart_Error then
	    null;
	 end if;
	 if Sermon.Dma2_Error then--------------------------------discovery
	    null;
	 end if;
	 if Sermon.Receiver_Is_Full then
	    First := Sermon.Serial_Recd_Data_A.all'First;
	    -- M now points to  the terminator
	    M     := First + Sermon.Srd_Terminator_Index - 1;
	    
	    -- wait for transmitter empty
	    while not Sermon.Transmitter_Is_Empty loop
	       null;
	    end loop;
	    
	    -- since the terminator is not copied to 
	    -- Sermon.Serial_Recd_Data_A.all, the last command
	    -- will be repeated when you press the 'Enter' in a
	    -- terminal window.
	    
	    -- try parse "rsttimer"
	    if Sermon.Serial_Recd_Data_A.all (First .. First + 7) =
	      "rsttimer" then
	       Timer.Reset;
	       
	    -- try parse "rtime"
	    elsif Sermon.Serial_Recd_Data_A.all (First .. First + 4) = 
	      "rtime" then
	       Sermon.Send_String 
		 (timer.Image (Timer.Report_Min_Duration) & 
		    "   " & 
		    Timer.Image (Timer.Report_Max_Duration) &
		    " clock ticks.");
	       
	    -- else echo the string
	    else
	       Sermon.Send_String 
		 (String (Sermon.Serial_Recd_Data_A.all (First .. M - 1)));

	    end if;
	    
	    -- now rebase the 'Serial_Recd_Data' string, 
	    -- should not be needed if we keep up with the uart,
	    -- but this -is- very important in the whole scheme of things
	    N := Sermon.Srd_Index - Sermon.Srd_Terminator_Index - 1;
	    if N >= 0 then
	       M := M + 1; -- first char after the terminator
	       Sermon.Serial_Recd_Data_A.all (First .. First + N) :=
		 Sermon.Serial_Recd_Data_A.all (M .. M + N);
	    end if;
	    
	    -- we have parsed the string, so set it to empty now
	    Sermon.Srd_Index := First + N + 1;
	 end if;
	 
	 Timer.Stop_Timer;--------------------------testing
      end loop;     
   --end tryit;

--begin
   --Tryit;
end Main;

