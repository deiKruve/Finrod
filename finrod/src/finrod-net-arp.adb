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

-- direct query:
-- give sender ip- and mac address
-- give targets ip address, target mac address = null
-- transmit to xmas
-- box with the tatget ip address responds with mac address
--
-- ARP probe:
-- sender ip address (SPA) = null, 
-- to indicate this is a request for conflict resolution
-- target ip address (TPA) given (my ip address), target mac address (THA) = null
-- transmit to xmas
-- box with the target ip address responds with mac address (if any box exists)
--
-- ARP announcement:
-- ARP request containing the senders ip address (SPA) in the 
-- target field (TPA=SPA).
--
-- ARP reply:
-- Oper = reply
-- sender ip address (SPA) = the replying IP address
-- target ip address (TPA) = the questioning IP address (the original requester)
-- same for MAC addresses
--

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");
pragma Warnings (Off, "*-fstrict-volatile-bitfields]");

with System.Storage_Elements;
--with System.Address_To_Access_Conversions;
with Ada.Unchecked_Conversion;
with Finrod.Board; 
with Finrod.Net.Eth;
with Finrod.Net.Arptable;
with Finrod.Sermon;

package body Finrod.Net.Arp is
   
   package Sse       renames System.Storage_Elements;
   --package Atoa      renames System.Address_To_Access_Conversions;
   package Board     renames Finrod.Board;
   package Arp_Table renames Finrod.Net.Arptable;
   package Eth       renames Finrod.Net.Eth;
   package V24       renames Finrod.Sermon;
   
   
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
      Padd    : Stm.Bits_16; -- padding to make 64 byte frame
      Padd1   : Stm.Bits_32; -- padding to make 64 byte frame
      Padd2   : Stm.Bits_32; -- padding to make 64 byte frame
      Padd3   : Stm.Bits_32; -- padding to make 64 byte frame
      Padd4   : Stm.Bits_32; -- padding to make 64 byte frame
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
      Padd   at 42 range  0 .. 15;
      Padd1  at 44 range  0 .. 31;
      Padd2  at 48 range  0 .. 31;
      Padd3  at 52 range  0 .. 31;
      Padd4  at 56 range  0 .. 31;
      
      -- 38 + 32 / 8 = 42
      -- so length = 42 bytes, 
      -- but theoretically this should be paddedto 60 bytes
   end record;
   
   for bArp_Packet'Bit_Order use System.High_Order_First;
   for bArp_Packet'Scalar_Storage_Order use System.High_Order_First;
   -- its Big Endian
   BArp_Packet_Length : constant Stm.Bits_13 := 60;
   -- pragma Unreferenced (BArp_Packet_Length);
   type BArp_Packet_Access_Type is access BArp_Packet;
   
   Display_Rframes : Natural := 0;
   Display_Xframes : Natural := 0;
   
   
   ---------------
   -- utilities --
   ---------------
   
   -- build a byte representation of a frame and send it to the v24 interface --
   procedure Show (A : System.Address) is
      Arr : Sse.Storage_Array (1 .. 42);
      for Arr'Address use A;
      pragma Import (Ada, Arr);
      Slen : Integer;
      pragma Unreferenced (Slen);
   begin
      declare -- hardcoded for speed
	 S : constant String := 
	   "Arp " &
	   Arr (1)'Img & ' ' &
	   Arr (2)'Img & ' ' & 
	   Arr (3)'Img & ' ' &
	   Arr (4)'Img & ' ' & 
	   Arr (5)'Img & ' ' &
	   Arr (6)'Img & ' ' & 
	   Arr (7)'Img & ' ' &
	   Arr (8)'Img & ' ' & 
	   Arr (9)'Img & ' ' &
	   Arr (10)'Img & ' ' & 
	   Arr (11)'Img & ' ' &
	   Arr (12)'Img & ' ' & 
	   Arr (13)'Img & ' ' &
	   Arr (14)'Img & ASCII.CR & ASCII.LF & 
	   Arr (15)'Img & ' ' &
	   Arr (16)'Img & ' ' & 
	   Arr (17)'Img & ' ' & 
	   Arr (18)'Img & ' ' &
	   Arr (19)'Img & ' ' & 
	   Arr (20)'Img & ' ' &
	   Arr (21)'Img & ' ' &
	   Arr (22)'Img & ' ' &
	   Arr (23)'Img & ' ' &
	   Arr (24)'Img & ' ' &
	   Arr (25)'Img & ' ' &
	   Arr (26)'Img & ' ' &
	   Arr (27)'Img & ' ' &
	   Arr (28)'Img & ' ' &
	   Arr (29)'Img & ' ' &
	   Arr (30)'Img & ' ' &
	   Arr (31)'Img & ' ' &
	   Arr (32)'Img & ' ' &
	   Arr (33)'Img & ' ' &
	   Arr (34)'Img & ' ' &
	   Arr (35)'Img & ' ' &
	   Arr (36)'Img & ' ' &
	   Arr (37)'Img & ' ' &
	   Arr (38)'Img & ' ' &
	   Arr (39)'Img & ' ' &
	   Arr (40)'Img & ' ' &
	   Arr (41)'Img & ' ' &
	   Arr (42)'Img;
      begin
	 Slen := S'Length;
	 V24.Send_String (S);
      end;
   end Show;
   
   ----------------------
   -- public interface --
   ----------------------
   
   -- test a received frame, defined by the frame address and the length, 
   -- for ownership.
   function Test_Frame 
     (Ba : Frame_Address_Type; Bbc : Frame_Length_Type)
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
	 -- nothing to the arptable since the sender is confused
	 -- reply directly
	 if Display_Rframes > 0 then Show (Ba); end if;
	 F.Oper := 2;
	 F.Sha  := Board.Get_Mac_Address;
	 F.Spa  := Board.Get_Ip_Address;
	 F.Tha  := F.Srce;
	 F.Dest := F.Srce;
	 F.Srce := Board.Get_Mac_Address;
	 Eth.Stash_For_Sending (Ba, Bbc);
	 if Display_Xframes > 0 then Show (Ba); end if;
	 return Stashed_For_Sending;
	 
	 pragma Warnings (Off);
      elsif F.Tpa = F.Spa and F.Tha = Mac_null then   
	 pragma Warnings (On);
	 -- arp.anouncement.
	 if Display_Rframes > 0 then Show (Ba); end if;
	 Arp_Table.Stash (F.Sha, F.Spa);
	 Eth.Mark_Free (Ba);
	 return Stashed_For_ArpTable;
	 
	 pragma Warnings (Off);
      elsif F.Oper = Arp_Req and F.Tpa = Board.Get_Ip_Address then
	 pragma Warnings (On);
	 -- regular arp request
	 if Display_Rframes > 0 then Show (Ba); end if;
	 Arp_Table.Stash (F.Sha, F.Spa); -- remember the sender, for later entry
	 F.Srce := Board.Get_Mac_Address;
	 F.Dest := Mac_Xmas;
	 F.Oper := 2;
	 F.Tha  := F.Sha;
	 F.Sha  := F.Srce;
	 declare
	    pragma Warnings (Off);
	    FSpa   : constant Stm.Bits_32 := F.Tpa;
	    pragma Warnings (On);
	    Ftpa   : constant Stm.Bits_32 := F.Spa;
	 begin
	    F.Tpa  := Ftpa;
	    F.Spa  := Fspa;
	    Eth.Stash_For_Sending (Ba, Bbc);
	    if Display_Xframes > 0 then Show (Ba); end if;
	    return Stashed_For_Sending;
	 end;
	 
      elsif F.Oper = Arp_Rep then
	 -- fish the content out of any reply packet, 
	 -- must reply packets be broadcast then?
	 if Display_Rframes > 0 then Show (Ba); end if;
	 Arp_Table.Stash (F.Sha, F.Spa);
	 pragma Warnings (Off);
	 Arp_Table.Stash (F.Tha, F.Tpa);
	 pragma Warnings (On);
	 Eth.Mark_Free (Ba);
	 return Stashed_For_ArpTable;
      end if;
      
      return No_Fit; -- non reachable code, but thats what the compiler likes
   end Test_Frame;
   
   
   
   -- builds an ARP frame and transmits it
   -- note that you have to poll for any anwer yourself.
   function Send_Arp_Request (Req : Arp_Request_Type  := Arp_Probe; 
			      Tpa : Stm.Bits_32       := Ip_Null)
			     return Test_Reply_Type
   is
      function Toba is new
	Ada.Unchecked_Conversion (Source => System.Address,
				  Target => BArp_Packet_Access_Type);
      F   : BArp_Packet_Access_Type;
      Idx : Eth.Buf_Idx_Type;
   begin
      if not Eth.Find_Free (Idx) then
	 -- do nothing, an error has been logged already
	 return Fatal_Error;
      else
	 F       := Toba (Eth.Buf'Address); 
	 -- the BArp_Packet's address is now the buffer address.
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
	       F.Tpa   := Tpa; -- see if our address is in use somewhere
	    when Arp_Announce =>
	       F.Spa   := Board.Get_Ip_Address;
	       F.Sha   := F.Srce;
	       F.Tpa   := F.Spa; -- to indicate an anouncement.
				 --F.Tha := Mac_null;
	 end case;
	 Eth.Stash_For_Sending (F.all'Address , BArp_Packet_Length);
	 Show (F.all'Address);
	 return Stashed_For_Sending;
      end if;
   end Send_Arp_Request;
   
   
   -- for debugging.
   -- sends the content of the next received frame to the spy.
   procedure Display_Received (Num : Positive := 1)
   is
   begin
      Display_Rframes := Num;
   end Display_Received;
   
   
   -- for debugging.
   -- sends the content of the next transmitted frame to the spy.
   procedure Display_Xmitted (Num : Positive := 1)
   is
   begin
      Display_Xframes := Num;
   end Display_Xmitted;
   
   -- how and when do we wipe a spend frame?
   -- So The Polling Must Happen Here !?
     -- as soon as a new one is transmitted! so have a pointer.
   
end Finrod.Net.Arp;
