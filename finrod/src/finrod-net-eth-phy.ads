------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                    F I N R O D . N E T . E T H . P H Y                   --
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
-- this is the finrod ethernet PHY interface
-- it serves to initialize the PHY;
-- and perhaps poll for errors (after the interrupt staatus says something is wrong)
-- 


package Finrod.Net.Eth.PHY is
   pragma Elaborate_Body;
   
   type State_Selector_Type is (Phy_Idle,
				Phy_Reset,
				Phy_Wait1,
				Phy_Init1,
				Phy_Init2,
				Phy_Ask_Error,
				Phy_Wait2,
				Phy_Ready);
   
   type Error_Type is (No_Error,
		       Remote_Fault_Detected,
		       Link_Down);
   
   function State return State_Selector_Type with inline;
   -- when the initialization is done 'State' will return 'Phy_Ready'.
   
   procedure Reset with inline;
   -- starts the PHY initialization procedure from a soft reset.
   -- it will put the PHY's init fsm on the job stack for executing 1 pass
   -- every scan period.
   -- once finished the fsm will disappear from the jobstack and 
   -- the state selector will be at ready.
   
   function Phy_Interrupted return Boolean with Inline;
   -- poll the phy interrupt on GPIOA pin 3
   
   procedure Ask_Error;
   -- asks the PHY to reveal its status.
   -- After 'State' returns 'Phy_Ready' the error can be gotten with 
   -- 'Which_Error'
   
   function Which_Error return Error_Type with Inline;
   -- will return the Error_Type;
   
end  Finrod.Net.Eth.PHY;
