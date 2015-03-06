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

with Finrod.Net.Eth.PHY;
with Finrod.Thread;
with Finrod.Board;

package body Finrod.Nmt_Init is
   
   package Thr renames Finrod.Thread;
   package Eth renames Finrod.Net.Eth;
   package Phy renames Finrod.Net.Eth.PHY;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   Fsm_State : State_Selector_Type := Nmt_Powered;
   
   -- there was no real need for an fsm here but since this is the theme
   -- of the project, it was also build in that shape.
   -- therefor the case discriminator in enclosed in a while loop
   procedure Fsm
   is
      use type Eth.State_Selector_Type;
      use type Phy.State_Selector_Type;
   begin
      while Fsm_State /= Nmt_Ready loop
      case Fsm_State is
	 when Nmt_Powered             =>
	    Fsm_State := Nmt_Initialising;
	    
	 when Nmt_Initialising        =>
	    
	    -- Initialize the basic board with comms, timer, etc
	    -- insofar not done on the ada startup layer
	    Finrod.Board.Init_Pins;
	    
	    -- board.set_macaddress         -- if special
	    -- board.set_ip_address         -- if special
	    
	    -- reads the hw id and applies it to the net addresses
	    Finrod.Board.Set_Id (1); 
	    -- reads the hw id and applies it to the net addresses
	    
	    -- board.set_master_ip_address  -- if special
	    
	 when Nmt_Reset_Phy           =>
	    PHY.Reset;
	    Thr.Scan;
	    Thr.Scan; -- so we are waiting now for the reset timeout
	    Fsm_State := Nmt_Reset_Application;
	    
	 when Nmt_Reset_Application   =>
	    null;
	    -- insert app init here
	    Thr.Scan;
	    Fsm_State := Nmt_Reset_Communication;
	 when Nmt_Reset_Communication =>
	    Finrod.Net.Eth.Reset;  -- resets the eth structure
	    Thr.Scan;
	    Fsm_State := Nmt_Wait_Communication;
	 when Nmt_Wait_Communication   =>
	    Thr.Scan;
	    if PHY.State = PHY.Phy_Ready and Eth.State = Eth.Eth_Ready then
	       Fsm_State := Nmt_Reset_Configuration;
	    end if;
	 when Nmt_Reset_Configuration =>  -- Could Be Used As A Restart After parms
					  -- have been changed trough the net.
	    null;
	    Thr.Scan;

	    --Thr.Delete_Job (Fsm'Access); -- happens only once cause then fsm 
					 -- does not get executed anymore
	    Fsm_State := Nmt_Ready;
	 when Nmt_Ready          =>
	    null;
      end case;
   end loop;
   end Fsm;
   
   
   procedure Reset
   is
   begin
      Fsm_State := Nmt_Initialising;
      --Thr.Insert_Job (Fsm'Access);
      Fsm;
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
end Finrod.Nmt_Init;
