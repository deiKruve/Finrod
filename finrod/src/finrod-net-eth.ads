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
with System.Storage_Elements;
with Finrod.Timer;

package Finrod.Net.Eth is
   
   --package Stm renames STM32F4;
   
   
   ------------------------------
   -- some types and constants --
   ------------------------------
   
   -- the frame descriptor index types
   -- when you need to know something about a descriptor,
   -- pass a var of this type, with the desc nuber  (0 .. 2 at the moment)
   -- 3 of each, until we need more
   --type Rx_Desc_Idx_Type is mod 3;
   --type Tx_Desc_Idx_Type is mod 3;
   -- moved up one level
   
   
   Recvd_Frame_P : Frame_Address_Type; 
   Recvd_Frame_L : Frame_Length_Type;
   -- address and length of the last received good frame.
   
   
   -- the frame buffers --
   -- they are unisex, can be used for xmit and recv
   type Buf_Idx_Type is mod 4;
   -- allow for 4 buffers;
   type 
   Buf_Type is array (Buf_Idx_Type) of 
     System.Storage_Elements.Storage_Array (1 .. 1024);
   Buf : aliased Buf_Type;
   for Buf'Alignment use 4;
   -- the buffer definition
   
   
   ----------------------
   -- public interface --
   ----------------------
   
   function Find_Free ( Fa : out Frame_Address_Type) 
		      return Boolean;
   --  find a free buffer  --
   
   function Find_Free (Idx : out Buf_Idx_Type) 
		      return Boolean;
   --  find a free buffer  --
   
   procedure Start_Receive_DMA with Inline;
   -- starts the receiver DMA
   -- after all is setup and ready. this is the last step.
   
   function Dma_Status_Image return String with Inline;
   -- returns the erronous dma status image caught at the last Receive poll
   
   function Rx_Status_Image return String with Inline;
   -- returns the Rdescriptors status image of the last received frame.
   
   function Tx_Status_Image return String with Inline;
   -- returns the 2 status images of the last transmit
   
   -- flags for communication between threadable routines:  --
   Rx_Recvd : Poll_R_Reply_Type;
   -- holds the return of  'Rx_Poll'.
   
   procedure Rx_Poll;
   -- poll for a received frame and determine the type.
   -- if the answer in 'Rx_Recvd' is yes the received frame details are in
   --  Recvd_Frame_P : Frame_Address_Type; 
   --  Recvd_Frame_L : Frame_Length_Type;
   ---
   -- can be posted in the job thread   
   -- in that case it removes itself on error and when a rx-frame is found.
   -- in order not to overwrite the received frame address in the case of
   -- a new received frame.
   -- so it must be reinserted after the details have been processed.

   
   -------------------------------
   -- for the parent and        --  
   -- uncles only               --
   -------------------------------
   
   -- flags for communication between threadable routines:
   
   Dix      : Tx_Desc_Idx_Type := 0;
   -- holds the xmit descriptor index of the last send frame 
   -- (can be used for polling).
   
   Dix_Buf  : System.Address := System.Null_Address;
   -- last send frame buffer   
   
   Dix_Done : Poll_X_Reply_Type := Complete;
   -- the last frame was successfully send
   
   Time     : Timer.Time_Type;
   -- timestamp of the last xmitted frame
   -- for use in syncing
   

    
   procedure Send_Frame (Ba  : Frame_Address_Type; 
			 Bbc : Frame_Length_Type);
   -- to send a frame build it first then pass the address and the length
   -- here for transmission.
   -- the frame can ony be released once it has been successfully sent.
   -- 
   -- in Dix the descriptor index is returned for polling use.
   -- the function returns false when 
   -- the next descriptor in the array is still in use. 
   -- If this were to happen the eth net quality is most likely very poor, 
   -- since there are buffers waiting to be transmitted.
   -- use Poll_Xmit_Completed after this command to ascertain its gone.
   
   
   procedure Stash_For_Sending (Ba  : Frame_Address_Type; 
				Bbc : Frame_Length_Type);
   -- queues a frame for sending,
   -- it is meant as a stage2 repost action, which can be executed just now
   -- the caller must return status 'Stashed_For_Sending' to its caller
   -- so that animal may then call 'Send_Next'.
   -- and then check for completion if needed by calling
   -- 'Poll_Xmit_Completed'
   
   
   procedure Send_Next;
   -- sends the next queued item. 
   -- and writes 'Dix' wich is the descriptor index (can be used for polling).
   -- this is an internal flag.
   --
   -- note that normally there should be no more than 1 item on the stack.
   -- so this command should happen after Stash_For_Sending without any
   -- ethernet send activity in between.
   -- the function returns false when 
   -- the next descriptor in the array is still in use. 
   -- If this were to happen the eth net quality is most likely very poor, 
   -- since there are buffers waiting to be transmitted.
   -- use Poll_Xmit_Completed after this command to ascertain its gone.
   ---
   -- can be posted in the job thread
   
   
   procedure Poll_Xmit_Completed;
   -- uses 'Dix', the index of the descriptor that was send.
   -- once send the 'Dix_Done' flag is set (see Poll_R_Reply_Type for details)
   -- since we have a strictly sequential comms pattern we check for
   -- completed or error; in case of error normally there is a re-transmission 
   -- after the error has been cleared.
   ---
   -- can be posted in the job thread
   
   
   --procedure Mark_free (Idx : Buf_Idx_Type); -- wait a bit with this one
   -- return an eth buffer to the free list
   -- this must be done by any family that is thru with a frame.
   
   procedure Mark_Free (Fa : Frame_Address_Type);
   -- return an eth buffer to the free list

   
   --------------------------
   --  for initialization  --
   --------------------------
   
   procedure Set_Eth_Interface;
   -- sets the ehh interface to RMII
   -- this must be done before Init_Pins
   
   procedure Init_Eth_Clock;
   -- starts the ethernet clock
   -- and resets the MAC
   
   procedure Soft_Reset;
   -- resets all MAC subsystem internal registers and logic
   -- After reset all the registers holds their respective reset values
   
   type State_Selector_Type is (Eth_Idle,
				Eth_Init_buffers,
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
   
   procedure Eth_Start with inline;
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
