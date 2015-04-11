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
--with Finrod.Net.Eth;
with Finrod.Timer;

package Finrod.Net is
   
   package Stm renames STM32F4;
   
   
   ------------------------------
   -- some types and constants --
   ------------------------------
   
   type Frame is tagged record   -- the root of all ethernet frames
      null;
   end record;
   for Frame'Bit_Order use System.High_Order_First;
   pragma Warnings (Off, "*no component clause");
   for Frame'Scalar_Storage_Order use System.High_Order_First;
   pragma Warnings (On);
   -- its Big Endian
   
   subtype Frame_Address_Type is System.Address; 
   -- used in the children of 'Frame' and a few other places.
   -- note that frame addresses must skip the first 4 bytes of a 'Frame' record
   -- since it is a tagged record.
   
   subtype Frame_Length_Type is Stm.Bits_13;
   -- cause thats how the descriptor defines it
   
   
   type Rx_Desc_Idx_Type is mod 3;
   type Tx_Desc_Idx_Type is mod 3;
   -- the frame descriptor index types
   -- when you need to know something about a descriptor,
   -- pass a var of this type, with the desc nuber  (0 .. 2 at the moment)
   -- 3 of each, until we need more
   
   
   type Test_Reply_Type is (Fit,
			    Stashed_For_Sending,  -- must be processed later
			    Stashed_For_ArpTable, -- must be processed later
			    Fits_With_Error,    -- there is a sender and an id!
			    No_Fit,
			    None_Recd,
			    Fatal_error);
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
   function Poll_Received return Test_Reply_Type with Inline;
   -- poll for a received frame and determine the type.
   -- stash any split 2nd halves
   
   function Poll_Xmit_Completed (Dix : in  Tx_Desc_Idx_Type;
				 Time : out Timer.Time_type)
				return Poll_X_Reply_Type with Inline;
   -- this still in a wide bag.--------------------------------
   -- since we have a strictly sequential comms pattern we
   -- check for completed or error.
   -- in case of error, normally there is a re-transmission 
   -- after the error has been cleared.
   
   procedure Execute_Stashed;
   -- execute the next stashed job, 
   -- used in time syncing and ReqRep.
   
private
   --  type Frame is tagged record 
   --     null;
   --  end record;
   
end Finrod.Net;
