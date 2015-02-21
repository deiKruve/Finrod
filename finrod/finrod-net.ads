------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                            F I N R O D . N E T                           --
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
-- this is the top of the finrod ethernet interface
-- It looks like the hardware driver will be in here which can be polled
-- by any state-machine.
-- the individual frame handlers are child packages and register themselves 
-- here, so the can be called to handle received frames.
--
-- the packet send routine will be an upcall here from the individual frame-
-- handler packages.


with System;
with STM32F4;

package Finrod.Net is
   
   package Stm renames STM32F4;
   
   
   ------------------------------
   -- some types and constants --
   ------------------------------
   
   type Frame is tagged record   -- the root of all ethernet frames
      null;
   end record;
   
   subtype Frame_Address is System.Address; 
   -- note that frame addresses must skip the first 4 bytes of a record
   -- since it is a tagged record.
   
   subtype Frame_Length_Type is Stm.Bits_13;
   -- cause thats how the descriptor defines it
   
   
   type Test_Reply_Type is (Fits,
			    Fits_With_Error, -- there is a sender and an id!
			    No_Fit);
   -- reply type of the test_frame functions in the children.
   
   
   type Poll_R_Reply_Type is (Yes,
			      Broken_With_Sender,
			      Broken_No_Sender,
			      Error_Fatal,
			      No);
   -- answer to the receiver poll, I am sure more will develop here
   
   type Poll_X_Reply_Type is (Ongoing,
			      Complete,
			      Error_Retry,
			      Error_Fatal);
   -- answer to the xmit complete poll, and here
   
   
   ----------------------
   -- public interface --
   ----------------------
   
   procedure Init_Ethernet;
   -- builds the circus tent
   
   function Poll_Received return Poll_R_Reply_Type;
   -- poll for a received frame and determine the type.
   -- stash any split 2nd halves
   
   function Poll_Xmit_Completed return Poll_X_Reply_Type;
   -- since we have a strictly sequential comms pattern we
   -- check for completed or error.
   -- in case of error, normally there is a re-transmission 
   -- after the error has been cleared.
   
   procedure Execute_Stashed;
   -- execute the next stashed job, 
   -- used in time syncing and ReqRep.
   
   
   -------------------------------
   -- for the children only     --
   -- could this be in private? --
   -------------------------------
   
   procedure Send_Frame (Ba : Frame_Address; Bbc : Frame_Length_Type);
   -- to send a frame build it first then pass the address and the length
   -- here for transmission.
   -- the frame can ony be released once it has been successfully sent.
   -- lets see if this works as a queueing mechanism.
   
private
   --  type Frame is tagged record 
   --     null;
   --  end record;
   
end Finrod.Net;
