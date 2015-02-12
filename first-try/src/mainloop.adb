
--pragma Restrictions (Max_tasks => 1);
pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");
--with 
with Init;
with Sermon;

package body Mainloop is

   procedure Tryit 
   is

      First, M : Sermon.Srd_Index_Type;
      N        : Integer range -1 .. 10;
   begin
      
      Init.Init_Pins;
      Sermon.Send_String ("Hallo I am up!");-----------------------
      loop
	 if Sermon.Uart_Error then
	    null;
	 end if;
	 if Sermon.Dma1_Error then
	    null;
	 end if;
	 if Sermon.Receiver_Is_Full then
	    -- echo the string, but wait for transmitter empty
	    if Sermon.Transmitter_Is_Empty then
	       First := Sermon.Serial_Recd_Data_A.all'First;
	       M     := First + Sermon.Srd_Terminator_Index;
	       Sermon.Send_String 
		 (String (Sermon.Serial_Recd_Data_A.all (First .. M - 1)));
	       -- and rebase the 'Serial_Recd_Data' string, should not be needed
	       --  but this -is- very important in the whole scheme of things
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
      end loop;     
   end tryit;

begin
   Tryit;
end Mainloop;

