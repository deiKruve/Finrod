------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                       F I N R O D . N M T _ I N I T                      --
--                                                                          --
--                                 B o d y                                  --
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
-- the first initialization of the app
--
-- this is a state machine. It works as described in finrod-thread.ads
-- and section 7.1.2 of EPSG DSP 301 V1.2.0
--

---pragma Warnings (Off, "*may call Last_Chance_Handler");
---pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

with finrod.Last_Chance_Handler; -- in testing
Pragma Unreferenced (finrod.Last_Chance_Handler);-- in testing

with STM32F4.O7xx.Registers;
with STM32F4.Gpio;

with Finrod.Net.Eth.PHY;
with Finrod.Thread;
with Finrod.Board;
with Finrod.Sermon;
with Finrod.Spy;
with Finrod.Timer;
with Finrod.Log;

package body Finrod.Nmt is
   
   package Stm  renames STM32F4;
   package Gpio renames STM32F4.Gpio;
   package R    renames STM32F4.O7xx.Registers;
   package Thr  renames Finrod.Thread;
   package Eth  renames Finrod.Net.Eth;
   package Phy  renames Finrod.Net.Eth.PHY;
   package Spy  renames Finrod.Spy;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   Lch_Message : String := "finrod-nmt done!";
   Pragma Unreferenced (Lch_Message);
   
   Fsm_State : State_Selector_Type := Nmt_Powered;
   
   
   ------------------------
   --  public interface  --
   ------------------------
   
   Lamp : Boolean := False;
   -- there was no real need for an fsm here but since this is the theme
   -- of the project, it was also build in that shape.
   -- therefor the case discriminator in enclosed in a while loop
   procedure Fsm
   is
      use type Stm.Word;
      use type Eth.State_Selector_Type;
      use type Phy.State_Selector_Type;
   begin
      --while Fsm_State /= Nmt_Ready loop
      loop
	 case Fsm_State is
	    when Nmt_Powered                    =>
	       Fsm_State := Nmt_Initialising;
	       
	    when Nmt_Initialising               =>
	       -- Initialize the basic board with comms, timer, etc
	       Board.Init_Clocks; -- but not the eth clock
	       Eth.Set_Eth_Interface;
	       Board.Init_Pins;
	       -- the running light must be off here, (for diagnostics) 
	       R.GPIOC.Bsrr := R.GPIOC.Bsrr or 2 ** Gpio.Bs13;
	       -- start the eth clock and resets the eth block
	       Eth.Init_Eth_Clock;
	       --  Start The Uart so we have a terminal
	       Finrod.Sermon.Init_Usart6;
	       -- reset all eth registers to default.
	       Eth.Soft_Reset;
	       -- the ptp timer and derivatives
	       Timer.Reset;
	       Timer.Init;
	       Spy.Insert_Spy; -- so we have a V24 interface.
	       
	       -- board.set_macaddress         -- if special
	       -- board.set_ip_address         -- if special
	       
	       -- reads the hw id and applies it to the net addresses
	       Finrod.Board.Set_Id (1); 
	       -- reads the hw id and applies it to the net addresses
	       
	       -- board.set_master_ip_address  -- if special
	       
	       R.GPIOC.Bsrr := R.GPIOC.Bsrr or 2 ** Gpio.Br13; -- led on
	       Log.Log ("finished Nmt_Initialising.");
	       Fsm_State := Nmt_Reset_Phy;
	       
	    when Nmt_Reset_Phy                  =>
	       PHY.Reset;
	       Thr.Scan;
	       Thr.Scan; -- so we are waiting now for the reset timeout
	       Fsm_State := Nmt_Reset_Application;
	       
	    when Nmt_Reset_Application          =>
	       -- init the application.
	       App_Init.all;
	       Thr.Scan;
	       Log.Log ("finished PHY and application init.");
	       Fsm_State := Nmt_Reset_Communication;
	    when Nmt_Reset_Communication =>
	       Finrod.Net.Eth.Reset;  -- resets the eth structure
	       Thr.Scan;
	       Fsm_State := Nmt_Wait_Communication;
	       
	    when Nmt_Wait_Communication         =>
	       Thr.Scan;
	       if PHY.State = PHY.Phy_Ready and 
		 Eth.State = Eth.Eth_Ready_To_Start then
		  Phy.Power_Up;
		  Eth.Start_Receive_DMA; -- so the receiver is now operational
		  Finrod.Net.Eth.Eth_Start; -- enable the xmitter and receiver
		  Fsm_State := Nmt_Wait_Communication_Ok;
	       end if;
	       Thr.Scan;
	       
	    when Nmt_Wait_Communication_Ok      =>
	       if Eth.State = Eth.Eth_Ready and then 
		 PHY.State = PHY.Phy_Ready then
		  Log.Log ("communication ok now.");
		  --Eth.Start_Receive_DMA; -- so the receiver is now operational
		  Fsm_State := Nmt_Reset_Configuration;
	       end if;
	       Thr.Scan;
	       
	    when Nmt_Reset_Configuration        =>  
	       -- Could Be Used As A Restart After parms
	       -- have been changed through the net.
	       null;
	       Fsm_State := Nmt_Wait_Configuration_Ok;
	       Thr.Scan;
	       
	    when Nmt_Wait_Configuration_Ok      =>  
	       Log.Log ("Initialization succesful.");
	       R.GPIOC.Bsrr := R.GPIOC.Bsrr or 2 ** Gpio.Bs13; -- led off
	       Fsm_State := Nmt_Ready;
	       
	    when Nmt_Ready                      =>
	       loop
		  if not Lamp and then Timer.Done2 then
		     -- led on
		     R.GPIOC.Bsrr := R.GPIOC.Bsrr or 2 ** Gpio.Br13;
		     Timer.Start_Timer3 (1, 0); -- 1 sec
		     Lamp := True;
		  elsif Lamp and then Timer.Done3 then
		     -- led off
		     R.GPIOC.Bsrr := R.GPIOC.Bsrr or 2 ** Gpio.Bs13;
		     Timer.Start_Timer2 (1, 0); -- 1 sec
		     Lamp := False;
		  end if;
		  Thr.Scan;
	       end loop;
	       --    the following is now dead code
	       --  Last_Chance_Handler.Last_Chance_Handler 
	       --  	 (Msg  => Lch_Message'Address,
	       --  	  Line => 156); -- done in the test setup
	       --  null;----------------------------------carry on here
	 end case;
	 
	 -- error handling:
	 declare 
	    Err : constant Log.Init_Error_Type := Log.Check_Error;
	 begin
	    if (Err'Valid) then
	       case  Err is
		  when Log.Init_Error_Initialize   =>
		     Fsm_State := Nmt_Initialising;
		  when Log.Init_Error_Reset_Phy    =>
		     Fsm_State := Nmt_Reset_Phy;
		  when Log.Init_Error_Reset_App    =>
		     Fsm_State := Nmt_Reset_Application;
		  when Log.Init_Error_Reset_Comms  =>
		     Fsm_State := Nmt_Reset_Communication;
		  when Log.Init_Error_Reset_Config =>
		     Fsm_State := Nmt_Reset_Configuration;
		  when others                      =>
		     null;
	       end case;
	    end if;
	 end;
	 
      end loop;
   end Fsm;
   
   
   procedure Reset
   is
   begin
      Fsm_State := Nmt_Initialising;
      --Thr.Insert_Job (Fsm'Access);
      --Fsm;
      -- and go to the next looped fsm here
      -- like pre-stage1.
   end Reset;
   
   
   -- resets to State
   -- meant to turn back the clock in case of some error
   -- carefully look at the state sequence when you decide on this.
   --
   -- this should also invalidate the job stack since:
   -- a. any scan has run its course, although some jobs might be suspended
   --    in mid air.
   -- b. we cant have statemachine jobs still executing when we reset the 
   --    application.
   --
   -- an immediate consequence is that it must be safe to enter into any of 
   -- the states, and restart from there.
   -- any jobs started in an older scan (i.e. not part of the warm reset) 
   -- must either stay in the state they were at the warm reset 
   -- or they must be able to run on to completion
   -- on or they must be included from scratch in this reset sequence.
   procedure Reset (State : State_Selector_Type)
   is
   begin
      Fsm_State := State;
   end Reset;
   
begin
   Reset;
   -- Thr.Scan;
end Finrod.Nmt;
