------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                        F I N R O D . N E T . A R P                       --
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
-- handles arp requests.
--

with System;
with STM32F4;

package Finrod.Net.Arp is
   
   package Stm renames STM32F4;
   
   Mac_Xmas : constant Stm.Bits_48 := 16#ff_ff_ff_ff_ff_ff#;
   Mac_Null : constant Stm.Bits_48 := 16#00_00_00_00_00_00#;
   Ip_Null  : constant Stm.Bits_32 := 16#00_00_00_00#;
   
   Arp_Proto : constant Stm.Bits_16 := 16#0806#; -- eth protocol
   Arp_Htype : constant Stm.Bits_16 := 1;        -- Hardware type 
   Arp_Ptype : constant Stm.Bits_16 := 16#0800#; -- Protocol type IPv4
   Arp_Hlen  : constant Stm.Byte    := 6;        -- Hardware address length
   Arp_Plen  : constant Stm.Byte    := 4;        -- ip address length
   Arp_Req   : constant Stm.Bits_16 := 1;        -- mode: 1 = request
   Arp_Rep   : constant Stm.Bits_16 := 2;        -- mode: 2 = reply
   
   type Arp_Packet is private;
   
   
   -------------------------
   -- just for the parent --
   -------------------------
   
   function Test_Frame 
     (Ba : Frame_Address; Bbc : Frame_Length_Type)
     return Test_Reply_Type;
   -- test a received frame, defined by the frame address and the length, 
   -- for ownership.
   
   ----------------------
   -- public interface --
   ----------------------
   type Arp_Request_Type is (Arp_Request,
			     Arp_Probe,
			     Arp_Announce);
   -- different types of arp frames that might be send,
   
   function Send_Arp_Request (Req : Arp_Request_Type  := Arp_Probe; 
			      Tpa : Stm.Bits_32       := Ip_Null)
     return Test_Reply_Type;
   -- builds an ARP frame and transmits it
   -- Tpa: 
   -- note that you have to poll for any anwer yourself, if needed.
   
   procedure Display_Received (Num : Positive := 1);
   -- for debugging.
   -- sends the content of the last received frame to the spy.
   
   procedure Display_Xmitted (Num : Positive := 1);
   -- for debugging.
   -- sends the content of the last transmitted frame to the spy.
   
private
   
   type Arp_Packet is new Frame with record
      Dest    : Stm.Bits_48 := Mac_xmas; -- destination mac address, broadcast
      Srce    : Stm.Bits_48 := Mac_null; -- sender i/f mac address
      Proto   : Stm.Bits_16 := 16#0806#; -- eth protocol
      Htype   : Stm.Bits_16 := 1;        -- Hardware type 
      Ptype   : Stm.Bits_16 := 16#0800#; -- Protocol type
      Hlen    : Stm.Byte    := 6;        -- Hardware address length
      Plen    : Stm.Byte    := 4;        -- ip address length
      Oper    : Stm.Bits_16 := 1;        -- mode: 1 = request, 2 = reply
      Sha     : Stm.Bits_48 := Mac_null; -- sender i/f mac address
      Spa     : Stm.Bits_32 := Ip_Null;  -- sender i/f ip address
      Tha     : Stm.Bits_48 := Mac_null; -- target i/f mac address
      Tpa     : Stm.Bits_32 := Ip_null;  -- tatget i/f ip address
   end record;
   
   for Arp_Packet use record             -- note the start address at byte 4
      Dest   at  4 range  0 .. 47;       -- this is to skip the tag.
      Srce   at 10 range  0 .. 47;       -- I am sure this is not portable
      Proto  at 16 range  0 .. 15;
      Htype  at 18 range  0 .. 15;
      Ptype  at 20 range  0 .. 15;
      Hlen   at 22 range  0 ..  7;
      Plen   at 23 range  0 ..  7;
      Oper   at 24 range  0 .. 15;
      Sha    at 26 range  0 .. 47;
      Spa    at 32 range  0 .. 31;
      Tha    at 36 range  0 .. 47;
      Tpa    at 42 range  0 .. 31;
   end record;
   
   for Arp_Packet'Bit_Order use System.High_Order_First;
   for Arp_Packet'Scalar_Storage_Order use System.High_Order_First;
   -- its Big Endian
   
  
   
end Finrod.Net.Arp;

