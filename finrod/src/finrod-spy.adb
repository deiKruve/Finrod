------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                            F I N R O D . S P Y                           --
--                                                                          --
--                                 S p e c                                  --
--                                                                          --
--                     Copyright (C) 2015, Jan de Kruyf                     --
--                                                                          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--                Finrod  is maintained by J de Kruijf Engineers            --
--                     (email: jan.de.kruyf@hotmail.com)                    --
--                                                                          --
------------------------------------------------------------------------------
--
-- this is a state machine to work the serial com port.
-- and do diagnostics 
-- It works as described in finrod-thread.ads
--

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

--with System;
with Finrod.Board;
with Finrod.Sermon;
with Finrod.Thread;
with Finrod.Timer;
with Finrod.Net.Arp;
with Finrod.Last_Chance_Handler;

package body Finrod.Spy is
   
   package Board renames Finrod.Board;
   package V24   renames Finrod.Sermon;
   package Thr   renames Finrod.Thread;
   package Flch  renames Finrod.Last_Chance_Handler;
   package Timer renames Finrod.Timer;
   package Net   renames Finrod.Net;
   package Arp   renames Finrod.Net.Arp;
   
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   Error_String : constant String:= "Finrod.Spy: Uart did not start";
   Fsm_State             : State_Selector_Type := Idle;
   Disappearance_Request : Boolean             := False;
   Error_Counter         : Natural             := 0;
   
   
   ----------------------------------------------------
   -- finite state machine with persistant variables --
   ----------------------------------------------------
   
   First, M : V24.Srd_Index_Type;
   N        : Integer range -1 .. 10;
   
   procedure Fsm
   is
      use type V24.Uart_Data_Type;
      Dummy_Reply : Net.Test_Reply_Type;
   begin
      case Fsm_State is
	 when Spy_Health_Check            =>
	    if V24.Uart_Error then
	       V24.Init_Usart6;
	       Error_Counter := Error_Counter + 8;
	       return;
	    end if;
	    if V24.Dma2_Error then--------------------------------discovery
	       V24.Init_Usart6;
	       Error_Counter := Error_Counter + 8;
	       return;
	    end if;
	    if Error_Counter > 0 then
	       if Error_Counter > 32 then
		  Flch.Last_Chance_Handler (Error_String'Address, 79);
	       else 
		  Error_Counter := Error_Counter - 1;
	       end if;
	    end if;
	    Fsm_State := Spy_Is_Receiver_Full;
	    
	 when Spy_Is_Receiver_Full        =>
	    if V24.Receiver_Is_Full then
	       First := V24.Serial_Recd_Data_A.all'First;
	       M     := First + V24.Srd_Terminator_Index - 1;
	       Fsm_State := Spy_Wait_For_Receiver_Empty;
	    else
	       Fsm_State := Spy_Health_Check;
	    end if;
	    
	 when Spy_Wait_For_Receiver_Empty =>
	    if V24.Transmitter_Is_Empty then
	       Fsm_State := Spy_Try_Parse_Rsttimer;
	    end if;
	    
	 when Spy_Try_Parse_Rsttimer      =>
	    if V24.Serial_Recd_Data_A.all (First .. First + 7) =
	      "rsttimer" then
	       Timer.Reset;
	       Fsm_State := Spy_Rebase_Incoming;
	    else Fsm_State := Spy_Try_Parse_Rtime;
	    end if;
	    
	 when Spy_Try_Parse_Rtime         =>
	    if V24.Serial_Recd_Data_A.all (First .. First + 4) = 
	      "rtime" then
	       V24.Send_String 
		 (Timer.Image (Timer.Report_Min_Duration) & 
		    "   " & 
		    Timer.Image (Timer.Report_Max_Duration) &
		    " clock ticks.");
	       Fsm_State := Spy_Rebase_Incoming;
	    else Fsm_State := Spy_Echo_Junk;
	    end if;
	    
	 when Spy_Try_Parse_Arp_Req       =>
	    if V24.Serial_Recd_Data_A.all (First .. First + 3) = 
	      "xarp" then
	       if V24.Serial_Recd_Data_A.all (First + 4 .. First + 6) = 
		 "req" then
		  Dummy_Reply := Arp.Send_Arp_Request 
		    (Arp.Arp_Request, Board.Get_Master_Ip_Address);
		  Fsm_State := Spy_Rebase_Incoming;
	       elsif V24.Serial_Recd_Data_A.all (First + 4 .. First + 7) =
		 "prob" then
		  Dummy_Reply := Arp.Send_Arp_Request 
		    (Arp.Arp_Probe, Board.Get_Ip_Address);
		  Fsm_State := Spy_Rebase_Incoming;
	       elsif V24.Serial_Recd_Data_A.all (First + 4 .. First + 6) =
		 "ann" then
		  Dummy_Reply := Arp.Send_Arp_Request 
		    (Arp.Arp_Announce, Board.Get_Ip_Address);
		  Fsm_State := Spy_Rebase_Incoming;
	       else 
		  Fsm_State := Spy_Echo_Junk;
	       end if;
	    else
	       Fsm_State := Spy_Echo_Junk;
	    end if;
	    
	 when Spy_Try_Parse_Show_Farp     =>
	    if V24.Serial_Recd_Data_A.all (First .. First + 5) = 
	      "lsrarp" then
	       declare 
		  I : Integer := First + 6;
		  J : Natural range 0 .. 9;
	       begin
		  while V24.Serial_Recd_Data_A.all (I) = ' ' loop
		     I := I + 1;
		  end loop;
		  J := Positive'Value 
		    (String (V24.Serial_Recd_Data_A.all (I .. I)));
		  if J /= 0 then Arp.Display_Received (J); end if;
	       end;
	       Fsm_State := Spy_Rebase_Incoming;
	    elsif V24.Serial_Recd_Data_A.all (First .. First + 5) = 
	      "lsxarp" then
	       declare 
		  I : Integer := First + 6;
		  J : Natural range 0 .. 9;
	       begin
		  while V24.Serial_Recd_Data_A.all (I) = ' ' loop
		     I := I + 1;
		  end loop;
		  J := Positive'Value 
		    (String (V24.Serial_Recd_Data_A.all (I .. I)));
		  if J /= 0 then Arp.Display_Xmitted (J); end if;
	       end;
	       Fsm_State := Spy_Rebase_Incoming;
	    else Fsm_State := Spy_Echo_Junk;
	    end if;

	 when Spy_Echo_Junk               =>
	    V24.Send_String 
	      (String (V24.Serial_Recd_Data_A.all (First .. M - 1)));
	    Fsm_State := Spy_Rebase_Incoming;
	    
	 when Spy_Rebase_Incoming         =>
	    N := V24.Srd_Index - V24.Srd_Terminator_Index - 1;
	    if N >= 0 then
	       M := M + 1; -- first char after the terminator
	       V24.Serial_Recd_Data_A.all (First .. First + N) :=
		 V24.Serial_Recd_Data_A.all (M .. M + N);
	    end if;
	    
	    -- we have parsed the string, so set it to empty now
	    V24.Srd_Index := First + N + 1;
	    if Disappearance_Request then
	       Fsm_State := Idle;
	    else
	       Fsm_State := Spy_Health_Check;
	    end if;
	    
	 when Idle                        =>
	    Thr.Delete_Job (Fsm'Access); -- happens only once cause then fsm 
					 -- does not get executed anymore
	    Disappearance_Request := False;
      end case;
   end Fsm;
   
   
   --------------------
   -- public entries --
   --------------------
   
   procedure Insert_Spy
   is
   begin
      Fsm_State := Spy_Health_Check;
      Thr.Insert_Job (Fsm'Access);
   end Insert_Spy;
   
   
   procedure Delete_Spy
   is
   begin
      Disappearance_Request := True;
   end Delete_Spy;
   
   
   procedure Change_Spy_State ( St : State_Selector_Type)
   is
   begin
      Fsm_State := St;
   end Change_Spy_State;

end Finrod.Spy;
