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

with Finrod.Board;
with Finrod.Net.Arptable;

package body Finrod.Net.Arp is
   
   Package Board     renames Finrod.Board;
   package Arp_Table renames Finrod.Net.Arptable;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   -- a bare copy of the arp record wich is NOT tagged
   -- that can be overlayed on a received frame for data extraction.
   type bArp_Packet is record
      Dest    : Stm.Bits_48; -- destination mac address, broadcast
      Srce    : Stm.Bits_48; -- sender i/f mac address
      Proto   : Stm.Bits_16; -- eth protocol
      Htype   : Stm.Bits_16; -- Hardware type 
      Ptype   : Stm.Bits_16; -- Protocol type
      Hlen    : Stm.Byte;    -- Hardware address length
      Plen    : Stm.Byte;    -- ip address length
      Oper    : Stm.Bits_16; -- mode: 1 = request, 2 = reply
      Sha     : Stm.Bits_48; -- sender i/f mac address
      Spa     : Stm.Bits_32; -- sender i/f ip address
      Tha     : Stm.Bits_48; -- target i/f mac address
      Tpa     : Stm.Bits_32; -- tatget i/f ip address
   end record;
   
   for bArp_Packet use record             -- note the start address at byte 4
      Dest   at  0 range  0 .. 47;       -- this is to skip the tag.
      Srce   at  6 range  0 .. 47;       -- I am sure this is not portable
      Proto  at 12 range  0 .. 15;
      Htype  at 14 range  0 .. 15;
      Ptype  at 16 range  0 .. 15;
      Hlen   at 18 range  0 ..  7;
      Plen   at 19 range  0 ..  7;
      Oper   at 20 range  0 .. 15;
      Sha    at 22 range  0 .. 47;
      Spa    at 28 range  0 .. 31;
      Tha    at 32 range  0 .. 47;
      Tpa    at 38 range  0 .. 31;
      -- end before byte 40
      -- so length = 40 bytes
   end record;
   
   for bArp_Packet'Bit_Order use System.High_Order_First;
   for bArp_Packet'Scalar_Storage_Order use System.High_Order_First;
   -- its Big Endian
   BArp_Packet_Length : constant Stm.Bits_13 := 40;
   type BArp_Packet_Access_Type is access BArp_Packet;
   
   ----------------------
   -- public interface --
   ----------------------
   
   -- test a received frame, defined by the frame address and the length, 
   -- for ownership.
   function Test_Frame 
     (Ba : Frame_Address; Bbc : Frame_Length_Type)
     return Test_Reply_Type
   is
      use type Stm.Bits_48;
      use type Stm.Bits_32;
      use type Stm.Bits_16;
      use type Stm.Byte;
      F : BArp_Packet;
      for F'Address use Ba;
   begin
      if    F.Proto /= Arp_Proto then return No_Fit;
      elsif F.Ptype /= Arp_Ptype then return No_Fit;
      elsif F.Hlen  /= Arp_Hlen  then return No_Fit;
      elsif F.Plen  /= Arp_Plen  then return No_Fit;
      elsif F.Oper  /= Arp_Req and F.Oper /=  Arp_Rep then return No_Fit;
      elsif F.Htype /= Arp_Htype then return No_Fit;
      
      elsif F.Spa    = Ip_Null and F.Sha   = Mac_Null then 
	 -- arp probe
	 F.Oper := 2;
	 F.Sha  := Board.Get_Mac_Address;
	 F.Spa  := Board.Get_Ip_Address;
	 F.Tha  := F.Srce;   -- this is the sender. to be entered in the dict?
	 F.Dest := F.Srce;
	 F.Srce := Board.Get_Mac_Address;
	 Stash_For_Sending (Ba, Bbc);
	 return Stashed_For_Sending;
	 
      elsif F.Tpa = F.Spa and F.Tha = Mac_null then   
	 -- arp.anouncement.
	 Arp_Table.Stash (F.Sha, F.Spa);
	 return Stashed_For_ArpTable;
	 
      elsif F.Oper = Arp_Rep then
	 -- fish the content out of a reply packet, 
	 -- must reply packets be broadcast then?
	 Arp_Table.Stash (F.Sha, F.Spa);
	 Arp_Table.Stash (F.Tha, F.Tpa);
      end if;
      
      return No_Fit; -- non reachable code, but thats what the compiler likes
   end Test_Frame;
   
   
   
   -- builds an ARP frame and transmits it
   -- note that you have to poll for any anwer yourself.
   function Send_Arp_Request (Req : Arp_Request_Type  := Arp_Probe; 
			      Tpa : Stm.Bits_32       := Ip_Null)
			     return Test_Reply_Type
   is
      F : BArp_Packet_Access_Type := new BArp_Packet;
   begin
      F.Dest  := Mac_Xmas;
      F.Srce  := Board.Get_Mac_Address;
      F.Proto := Arp_Proto;
      F.Htype := Arp_Htype;
      F.Ptype := Arp_Ptype;
      F.Hlen  := Arp_Hlen;
      F.Plen  := Arp_Plen;
      F.Oper  := Arp_Req;
      --F.Sha   := F.Srce;
      --F.Spa   := Board.Get_Ip_Address;
      F.Tha   := Mac_Null;
      --F.Tpa   := Tpa;
      case Req is
	 when Arp_Request  =>
	    F.Sha   := F.Srce;
	    F.Spa   := Board.Get_Ip_Address;
	    F.Tpa   := Tpa;
	 when Arp_Probe    =>
	    F.Sha := Mac_Null;
	    F.Spa := Ip_Null;
	 when Arp_Announce =>
	    F.Spa   := Board.Get_Ip_Address;
	    F.Tpa := F.Spa;
	    --F.Tha := Mac_null;
      end case;
      Stash_For_Sending (F.all'Address , BArp_Packet_Length);
      return Stashed_For_Sending;

   end Send_Arp_Request;
   
   
   -- for debugging.
   -- sends the content of the last received frame to the spy.
   procedure Display_Last_Received
   is
      
   begin
      null;
   end Display_Last_Received;
   
   
   -- for debugging.
   -- sends the content of the last transmitted frame to the spy.
   procedure Display_Last_Xmitted
   is
   begin
      null;
   end Display_Last_Xmitted;
   
   
   
end Finrod.Net.Arp;
