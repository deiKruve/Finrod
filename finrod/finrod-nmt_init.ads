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

package Finrod.Nmt_Init is
   
   type State_Selector_Type is (Nmt_Gs_Powered,
				--Nmt_Gs_Initialisation, -- baroque austrians
				Nmt_Gs_Initialising,
				Nmt_Gs_Reset_Application,
				Nmt_Gs_Reset_Communication,
				Nmt_Gs_Reset_Configuration,
				Idle);
   
   procedure NMT_Sw_Reset;
   -- resets to Nmt_Gs_Initialising
   -- and inserts this fsm onto the jobstack.
   -- this is where the machine starts on power up
   
   procedure NMT_Reset_Node;
   -- resets to Nmt_Gs_Reset_Application
   -- and inserts this fsm onto the jobstack.
   
   procedure NMT_Reset_Communication;
   -- resets to Nmt_Gs_Reset_Communication
   -- and inserts this fsm onto the jobstack.
   
   procedure NMT_Reset_Configuration;
   -- resets to Nmt_Gs_Reset_Configuration
   -- and inserts this fsm onto the jobstack.
   
end Finrod.Nmt_Init;
