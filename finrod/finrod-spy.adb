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

with Finrod.Sermon;
with Finrod.Thread;

package body Finrod.Spy is
   package V24 renames Finrod.Sermon;
   package Thr renames Finrod.Thread;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   Fsm_State : State_Selector_Type := Idle;
   
   
   
   First, M : V24.Srd_Index_Type;
   N        : Integer range -1 .. 10;
   
   procedure Fsm
   is
      use type V24.Uart_Data_Type;
   begin
      case Fsm_State is
	 when Spy_Health_Check            =>
	    if V24.Uart_Error then
	       null;------------------------------------------------error--
	       return;
	    end if;
	    if V24.Dma2_Error then--------------------------------discovery
	       null;------------------------------------------------error--
	       return;
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
		 (Timer.Time_Interval'Image (Timer.Report_Min_Duration) & 
		    "   " & 
		    Timer.Time_Interval'Image (Timer.Report_Max_Duration) &
		    " clock ticks.");
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
	    Fsm_State := Spy_Health_Check;
	 when Idle                        =>
	    null;
      end case;
   end Fsm;
   
   
   procedure Insert_Spy
   is
   begin
      null;
   end Insert_Spy;
   
   
   procedure Delete_Spy
   is
   begin
      null;
   end Delete_Spy;

end Finrod.Spy;
