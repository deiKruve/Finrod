------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                        F I N R O D . N E T . A R P                       --
--                                                                          --
--                                  B o d y                                 --
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
-- handles arp requests.
--

package body Finrod.Net.Arp is
   
   
   -- test a received frame, defined by the frame address and the length, 
   -- for ownership.
   function Test_Frame 
     (Ba : Frame_Address; Bbc : Frame_Length_Type)
     return Test_Reply_Type
   is
   begin
      return No_Fit;
   end Test_Frame;
   
   
   
   -- builds an ARP frame and transmits it
   -- note that you have to poll for any anwer yourself.
   procedure Send_Arp_Request (Req : Arp_Request_Type)
   is
   begin
      null;
   end Send_Arp_Request;
   
   
end Finrod.Net.Arp;
