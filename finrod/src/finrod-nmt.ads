------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                       F I N R O D . N M T _ I N I T                      --
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
-- the first initialization of the app
--
-- this is a state machine. It works as described in finrod-thread.ads
-- and section 7.1.2 of EPSG DSP 301 V1.2.0
--

package Finrod.Nmt is
   
   type State_Selector_Type is (Nmt_Powered,
				--Nmt_Gs_Initialisation, -- baroque austrians
				Nmt_Initialising,
				Nmt_Reset_Phy,
				Nmt_Reset_Application,
				Nmt_Reset_Communication,
				Nmt_Wait_Communication,
				Nmt_Wait_Communication_Ok,
				Nmt_Reset_Configuration,
				Nmt_Wait_Configuration_Ok,
				Nmt_ready);
   
   procedure Fsm;
   -- the init state machine
   -- insert it into the run thread to srt the board. or!????
   -- i think we will just start it at elaboration time;
   -- at the moment it is not threaded, just a loop
   
   procedure Reset;
   -- resets to Nmt_Initialising
   -- and NOT inserts this fsm onto the jobstack.
   -- this is where the machine should start on power up
   -- and it will, through the elaboration of the body.
   -- check this sequence though
   
   procedure Reset (State : State_Selector_Type);
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
   -- An immediate consequence is that it must be safe to enter into any of 
   -- the states, and restart from there.
   -- Any jobs started in an older scan (i.e. not part of the warm reset) 
   -- must either stay in the state they were at the warm reset, 
   -- or they must be able to run on to completion without any statemachine,
   -- or they must be included from scratch in this reset sequence.
   
   type App_Init_Type is access procedure;
   App_Init : App_Init_Type;
   
end Finrod.Nmt;
