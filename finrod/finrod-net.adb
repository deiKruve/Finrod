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
--


package body Finrod.Net is
   
   
   
   ----------------------
   --  interface       --
   ----------------------
   
   -- builds the circus tent
   procedure Init_Ethernet
   is
   begin
      null;
   end Init_Ethernet;
   
   
   -- poll for a received frame and determine the type.
   -- stash any split 2nd halves
   function Poll_Received return Poll_R_Reply_Type
   is
   begin
      return No;
   end Poll_Received;
   
   
   -- since we have a strictly sequential comms pattern we
   -- check for completed or error.
   -- in case of error, normally there is a re-transmission 
   -- after the error has been cleared.
   function Poll_Xmit_Completed return Poll_X_Reply_Type
   is
   begin
      return Ongoing;
   end Poll_Xmit_Completed;
   
   
   -- execute the next stashed job, 
   -- used in time syncing and ReqRep.
   procedure Execute_Stashed
   is
   begin
      null;
   end Execute_Stashed;
   
   
   -- to send a frame build it first then pass the address and the length
   -- here for transmission.
   -- the frame can ony be released once it has been successfully sent.
   -- lets see if this works as a queueing mechanism.
   procedure Send_Frame (Ba : Frame_Address; Bbc : Frame_Length_Type)
   is
   begin
      null;
   end Send_Frame;
   
   
end Finrod.Net;
