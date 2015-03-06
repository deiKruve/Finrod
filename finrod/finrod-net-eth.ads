------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                       F I N R O D . N E T . E T H                        --
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
-- this is the finrod ethernet mac interface
-- 


--with System;
--with STM32F4;

package Finrod.Net.Eth is
   
   --package Stm renames STM32F4;
   
   
   ------------------------------
   -- some types and constants --
   ------------------------------
   
  
   ----------------------
   -- public interface --
   ----------------------
   
   function Poll_Received return Poll_R_Reply_Type;
   -- poll for a received frame and determine the type.
   -- stash any split 2nd halves
   
   function Poll_Xmit_Completed return Poll_X_Reply_Type;
   -- since we have a strictly sequential comms pattern we
   -- check for completed or error.
   -- in case of error, normally there is a re-transmission 
   -- after the error has been cleared.
   
   
   -------------------------------
   -- for the parent and        --  
   -- uncles only               --
   -------------------------------
    
   procedure Send_Frame (Ba : Frame_Address; Bbc : Frame_Length_Type);
   -- to send a frame build it first then pass the address and the length
   -- here for transmission.
   -- the frame can ony be released once it has been successfully sent.
   -- lets see if this works as a queueing mechanism.
   
   procedure Stash_For_Sending (Ba : Frame_Address; Bbc : Frame_Length_Type);
   -- queues a frame for sending,
   -- it is meant as a stage2 repost action, which can be executed just now
   
   procedure Send_Next;
   -- sends the next queued item. note that normally there should be
   -- no more than 1 item on the stack.
   -- so this command should happen after Stash_For_Sending without any
   -- ethernet send activity in between.
   -- use Poll_Xmit_Completed after this command to ascertain its gone.
   
   
   --------------------------
   --  for initialization  --
   --------------------------
   
   type State_Selector_Type is (Eth_Idle,
				Eth_Init_buffers,
				Eth_Dma_Reset,
				Eth_Set_Addresses,
				Eth_Init_Frame_Filter,
				Eth_Init_Maccr,
				Eth_Waiting_To_Start,
				Eth_Ready_To_Start,
				Eth_Starting,
				Eth_Ready);
   
   function State return State_Selector_Type with inline;
   -- when the initialization is done 'State' will return 'Phy_Ready'.
   
   procedure Reset with inline;
   -- starts the ETH initialization procedure from a soft reset.
   -- it will put the PHY's init fsm on the job stack for executing 1 pass
   -- every scan period.
   -- once finished the fsm will disappear from the jobstack and 
   -- the state selector will be at ready.
   
   function Eth_Start return Boolean with inline;
   -- starts all ethernet facilities.
   -- if not in State 'Eth_Ready_To_Start' the function will return false.
   -- else true.
   
   
   -------------------
   -- debugger      --
   -------------------
   
   type On_Off_Type is (Off, On);
   
   procedure Set_Mac_Loopback_Mode (B : On_Off_Type);
   -- sets the mac loopback mode on or off
   
end Finrod.Net.Eth;
