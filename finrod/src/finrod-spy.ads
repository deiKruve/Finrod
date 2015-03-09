------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                            F I N R O D . S P Y                           --
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
-- this is a state machine to work the serial com port.
-- and do diagnostics 
-- It works as described in finrod-thread.ads
--
--
-- commands so far:
--  rsttimer                : reset the timer min and max registers
--                            the prob points must be inserted manually in the code 
--  rtime                   : report the min and max cycletime collected since reset
--  xarpreq                 : make an arp request 
--                        (the request is for the Master_Ip_adrress in Finrod.Board)
--  xarpprob                : do an arp probe
--  xarpann                 : make an arp announcement
--  lsrarp <number 1 .. 9>  : display 'number' received frames
--  lsxarp <number 1 .. 9>  : display 'number' transmitted frames
--  

package Finrod.Spy is
   
   type State_Selector_Type is (Spy_Health_Check,
				Spy_Is_Receiver_Full,
				Spy_Wait_For_Receiver_Empty,
				Spy_Try_Parse_Rsttimer,
				Spy_Try_Parse_Rtime,
				Spy_Try_Parse_Arp_Req,
				Spy_Try_Parse_Show_Farp,
				Spy_Echo_Junk,
				Spy_Rebase_Incoming,
				Idle);
   -- possible states of the state machine
   
			       
   procedure Insert_Spy;
   -- initializes the Spy at Spy_Health_Check and
   -- inserts the spy into the loop of things.
   
   procedure Delete_Spy;
   -- synchronizes the Spy and takes it out of 
   -- the loop of things.
   
   procedure Change_Spy_State ( St : State_Selector_Type);
   -- to get out of a knot
   -- not very useful here
   
   -- use
   -- Finrod.Sermon.Send_String (S : String); 
   -- to display anything on the v24 terminal
   -- on a Spy request.
   
end Finrod.Spy;
