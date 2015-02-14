
--pragma Restrictions (Max_tasks => 1);
pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

with Init;
with Sermon;
with Timer;

package body Mainloop is

   procedure Tryit 
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
	    
	    -- wait for transmitter empty
	    while not Sermon.Transmitter_Is_Empty loop
	       null;
	    end loop;
	    
	    -- parse "rsttimer"
	    if Sermon.Serial_Recd_Data_A.all (First .. First + 7) =
	      "rsttimer" then
	       Timer.Reset;
	       
	    -- parse "rtime"
	    elsif Sermon.Serial_Recd_Data_A.all (First .. First + 4) = 
	      "rtime" then
	       Sermon.Send_String 
		 (Timer.Time_Interval'Image (Timer.Report_Min_Duration) & 
		    "   " & 
		    Timer.Time_Interval'Image (Timer.Report_Max_Duration) &
		    " clock ticks.");
	       
	    -- echo the string
	    else
	       --First := Sermon.Serial_Recd_Data_A.all'First;
	       M     := First + Sermon.Srd_Terminator_Index - 1;
	       Sermon.Send_String 
		 (String (Sermon.Serial_Recd_Data_A.all (First .. M)));
	       
	       -- and rebase the 'Serial_Recd_Data' string, 
	       -- should not be needed if we keep up with the uart,
	       -- but this -is- very important in the whole scheme of things
	       N := Sermon.Srd_Index - Sermon.Srd_Terminator_Index - 1;
	       if N >= 0 then
		  Sermon.Serial_Recd_Data_A.all (First .. First + N) :=
		    Sermon.Serial_Recd_Data_A.all (M .. M + N);
	       end if;
	       
	       -- we have parsed the string, so set it to empty now
	       Sermon.Srd_Index := First + N + 1;
	    end if;
	    null;
	 end if;
	 Timer.Stop_Timer;--------------------------testing
      end loop;     
   end tryit;

begin
   Tryit;
end Mainloop;

