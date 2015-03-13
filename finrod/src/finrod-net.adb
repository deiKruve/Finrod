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

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

with Finrod.Net.Eth;
with Finrod.Net.Arp;
with Finrod.Log;

package body Finrod.Net is
   
   --package Eth renames  Finrod.Net.Eth; ---- automagic in ada
   
   
   ----------------------
   --  interface       --
   ----------------------
   
   -- poll for a received frame and determine the type.
   -- stash any split 2nd halves
   function Poll_Received return Test_Reply_Type
   is 
   begin
      case Eth.Rx_Poll is
	 when No          =>
	    return None_recd;--------------return
	 when Error_Fatal =>
	    return Fatal_Error;------------return
	 when Yes         =>
	    case Arp.Test_Frame (Eth.Recvd_Frame_P, Eth.Recvd_Frame_L) is
	       when No_Fit               =>
		  null; -- do nothing  here, to the next test
	       when Stashed_For_Sending  =>
		  return Stashed_For_Sending;------------return
	       when Stashed_For_ArpTable =>
		  return Stashed_For_ArpTable;-----------return
	       when others               =>
		  Log.Log_Error (Log.Net_Error, "bad return fron test for arp");
		  return Fatal_Error;------------return
	    end case;
	    -- other tests
	    null;
	 when others      =>
	    return  None_recd; -- for the time being-------------
      end case;
      return  None_recd;
   end Poll_Received;
   
   
   -- since we have a strictly sequential comms pattern we
   -- check for completed or error.
   -- in case of error, normally there is a re-transmission 
   -- after the error has been cleared.
   function Poll_Xmit_Completed (Dix : in  Tx_Desc_Idx_Type;
				 Time : out Timer.Time_type)
				return Poll_X_Reply_Type
   is  
   begin
      case Eth.Poll_Xmit_Completed (Dix, Time) is-------------------------junk
	 when Ongoing          =>
	    return Ongoing;
	 when Complete         =>
	    return Complete;
	 when Error_Fatal      =>
	    return Error_Fatal;
	 when Error_Retry      =>
	    null;
      end case;
      return Error_Fatal;
   end Poll_Xmit_Completed;
   
   -- execute the next stashed job, 
   -- used in time syncing and ReqRep.
   procedure Execute_Stashed
   is
   begin
      null;
   end Execute_Stashed;
   
  
end Finrod.Net;
