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

with Finrod.Thread;
with Finrod.Board;

package body Finrod.Nmt_Init is
   
   package Thr renames Finrod.Thread;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   Fsm_State : State_Selector_Type := Nmt_Gs_Powered;
   
   
   procedure Fsm
   is
   begin
      case Fsm_State is
	 when Nmt_Gs_Powered             =>
	    Fsm_State := Nmt_Gs_Initialising;
	    
	 when Nmt_Gs_Initialising        =>
	    
	    -- Initialize the basic board with comms, timer, etc
	    -- insofar not done on the ada startup layer
	    Finrod.Board.Init_Pins;
	    
	    -- board.set_macaddress         -- if special
	    -- board.set_ip_address         -- if special
	    
	    -- reads the hw id and applies it to the net addresses
	    Finrod.Board.Set_Id (1); 
	    -- reads the hw id and applies it to the net addresses
	    
	    -- board.set_master_ip_address  -- if special
	    
	    Fsm_State := Nmt_Gs_Reset_Application;
	    
	 when Nmt_Gs_Reset_Application   =>
	    null;
	    
	    Fsm_State := Nmt_Gs_Reset_Communication;
	 when Nmt_Gs_Reset_Communication =>
	    null;
	    
	    Fsm_State := Nmt_Gs_Reset_Configuration;
	 when Nmt_Gs_Reset_Configuration =>
	    null;
	    
	    Fsm_State := Idle;
	 when Idle                       =>
	    Thr.Delete_Job (Fsm'Access); -- happens only once cause then fsm 
					 -- does not get executed anymore
      end case;
   end Fsm;
   
   
   procedure NMT_Sw_Reset
   is
   begin
      Fsm_State := Nmt_Gs_Initialising;
      Thr.Insert_Job (Fsm'Access);
   end NMT_Sw_Reset;
   
   
   procedure NMT_Reset_Node
   is
   begin
      Fsm_State := Nmt_Gs_Reset_Application;
      Thr.Insert_Job (Fsm'Access);
   end NMT_Reset_Node;
   
   
   procedure NMT_Reset_Communication
   is
   begin
      Fsm_State := Nmt_Gs_Reset_Communication;
      Thr.Insert_Job (Fsm'Access);
   end NMT_Reset_Communication;
   
   
   procedure NMT_Reset_Configuration
   is
   begin
      Fsm_State := Nmt_Gs_Reset_Configuration;
      Thr.Insert_Job (Fsm'Access);
   end NMT_Reset_Configuration;
   
begin
   NMT_Sw_Reset;
   Thr.Scan;
end Finrod.Nmt_Init;
