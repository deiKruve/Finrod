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

with System.Storage_Elements;
with Ada.Unchecked_Conversion;

with STM32F4.o7xx.Ethbuf;
with STM32F4.o7xx.Registers;

package body Finrod.Net.Eth is
   
   package Sto  renames  System.Storage_Elements;
   package Ebuf renames  STM32F4.o7xx.Ethbuf;
   package R    renames  STM32F4.o7xx.Registers;
      
   ------------------------------
   -- some types and constants --
   ------------------------------
   
   -- Bd   : Sto.Storage_Offset; -- in case we need an index
   Buf1 : Sto.Storage_Array (1 .. 1024);
   Buf2 : Sto.Storage_Array (1 .. 1024);
   Buf3 : Sto.Storage_Array (1 .. 1024);
   Buf4 : Sto.Storage_Array (1 .. 1024);
   
   function Tob is new
     Ada.Unchecked_Conversion (Source => System.Address,
   			       Target => Stm.Bits_32);
   function Toa is new
     Ada.Unchecked_Conversion (Source => Stm.Bits_32,
			       Target => System.Address);
   
   -- type Sto.Integer_Address is mod Memory_Size;
   -- Sto.To_Integer (Value : Address) return Integer_Address;
   -- Sto.To_Address (Value : Integer_Address) return Address;
   
   --type Rx_Access_Type is access all Ebuf.Xl_Recv_Desc_Type;
   --type Tx_Access_Type is access all Ebuf.Xl_Xmit_Desc_Type;
   
   Rx_Desc_1 : Ebuf.Xl_Recv_Desc_Type;
   Rx_Desc_2 : Ebuf.Xl_Recv_Desc_Type;
   Rx_Desc_3 : Ebuf.Xl_Recv_Desc_Type;
   
   
   Tx_Desc_1 : Ebuf.Xl_Xmit_Desc_Type;
   Tx_Desc_2 : Ebuf.Xl_Xmit_Desc_Type;
   Tx_Desc_3 : Ebuf.Xl_Xmit_Desc_Type;
   
   ----------------------
   -- public interface --
   ----------------------
   
   
   -- builds the circus tent
   procedure Init_Ethernet
   is
   begin
      --- initialize the rx descriptors, as far as known
      Rx_Desc_1.Rdes0.Own   := Ebuf.Me;
      
      Rx_Desc_1.Rdes1.Dic   := Ebuf.Disable; -- interrupt on rec off for the time.
      Rx_Desc_1.Rdes1.Rbs2  := 0; -- second buffer size
      Rx_Desc_1.Rdes1.Rer   := Ebuf.Off;
      Rx_Desc_1.Rdes1.Rch   := Ebuf.Tru;
      Rx_Desc_1.Rdes1.Rbs1  := 1024;
      
      Rx_Desc_1.Rdes2.Rbap1 := Tob (Buf1'address);
      
      Rx_Desc_1.Rdes3.Rbap2 := Tob (Rx_Desc_2'Address);
      ---
      Rx_Desc_2.Rdes0.Own   := Ebuf.Me;
      
      Rx_Desc_2.Rdes1.Dic   := Ebuf.Disable; -- interrupt on rec off for the time.
      Rx_Desc_2.Rdes1.Rbs2  := 0; -- second buffer size
      Rx_Desc_2.Rdes1.Rer   := Ebuf.Off;
      Rx_Desc_2.Rdes1.Rch   := Ebuf.Tru;
      Rx_Desc_2.Rdes1.Rbs1  := 1024;
      
      Rx_Desc_2.Rdes2.Rbap1 := Tob (Buf2'address);
      
      Rx_Desc_2.Rdes3.Rbap2 := Tob (Rx_Desc_3'Address);
      ---
      Rx_Desc_3.Rdes0.Own   := Ebuf.Me;
      
      Rx_Desc_3.Rdes1.Dic   := Ebuf.Disable; -- interrupt on rec off for the time.
      Rx_Desc_3.Rdes1.Rbs2  := 0; -- second buffer size
      Rx_Desc_3.Rdes1.Rer   := Ebuf.Tru;
      Rx_Desc_3.Rdes1.Rch   := Ebuf.Tru;
      Rx_Desc_3.Rdes1.Rbs1  := 1024;
      
      Rx_Desc_3.Rdes2.Rbap1 := Tob (Buf3'address);
      
      Rx_Desc_3.Rdes3.Rbap2 := Tob (Rx_Desc_1'Address);
      ---
      --- initialize the tx descriptors, as far as known
      Tx_Desc_1.Tdes0.Own   := Ebuf.Me;
      Tx_Desc_1.Tdes0.Ic    := Ebuf.Off; -- no int on completion
      Tx_Desc_1.Tdes0.Ls    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc_1.Tdes0.Fs    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc_1.Tdes0.Dc    := Ebuf.Off;
      Tx_Desc_1.Tdes0.Dp    := Ebuf.Off;
      Tx_Desc_1.Tdes0.Ttse  := Ebuf.Enable; -- timestamp enable
      Tx_Desc_1.Tdes0.Cic   := Ebuf.Ck_Head_Payload; -- checksum
      Tx_Desc_1.Tdes0.Ter   := Ebuf.Off;
      Tx_Desc_1.Tdes0.Thc   := Ebuf.Tru;
      
      Tx_Desc_1.Tdes1.Tbs2  := 0; -- second buffer size
      Tx_Desc_1.Tdes1.Tbs1  := 0; --1024; -- to be set by appl
      
      Tx_Desc_1.Tdes2.Tbap1 := Tob (Buf4'Address); -- for the time being!!!!!
      
      Tx_Desc_1.Tdes3.Tbap2 := Tob (Tx_Desc_2'Address);
      ---
      Tx_Desc_2.Tdes0.Own   := Ebuf.Me;
      Tx_Desc_2.Tdes0.Ic    := Ebuf.Off; -- no int on completion
      Tx_Desc_2.Tdes0.Ls    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc_2.Tdes0.Fs    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc_2.Tdes0.Dc    := Ebuf.Off;
      Tx_Desc_2.Tdes0.Dp    := Ebuf.Off;
      Tx_Desc_2.Tdes0.Ttse  := Ebuf.Enable; -- timestamp enable
      Tx_Desc_2.Tdes0.Cic   := Ebuf.Ck_Head_Payload; -- checksum
      Tx_Desc_2.Tdes0.Ter   := Ebuf.Off;
      Tx_Desc_2.Tdes0.Thc   := Ebuf.Tru;
      
      Tx_Desc_2.Tdes1.Tbs2  := 0; -- second buffer size
      Tx_Desc_2.Tdes1.Tbs1  := 0; --1024; -- to be set by appl
      
      Tx_Desc_2.Tdes2.Tbap1 := Tob (Buf4'Address); -- for the time being!!!!!
      
      Tx_Desc_2.Tdes3.Tbap2 := Tob (Tx_Desc_3'Address);
      ---
      Tx_Desc_3.Tdes0.Own   := Ebuf.Me;
      Tx_Desc_3.Tdes0.Ic    := Ebuf.Off; -- no int on completion
      Tx_Desc_3.Tdes0.Ls    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc_3.Tdes0.Fs    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc_3.Tdes0.Dc    := Ebuf.Off;
      Tx_Desc_3.Tdes0.Dp    := Ebuf.Off;
      Tx_Desc_3.Tdes0.Ttse  := Ebuf.Enable; -- timestamp enable
      Tx_Desc_3.Tdes0.Cic   := Ebuf.Ck_Head_Payload; -- checksum
      Tx_Desc_3.Tdes0.Ter   := Ebuf.Tru;
      Tx_Desc_3.Tdes0.Thc   := Ebuf.Tru;
      
      Tx_Desc_3.Tdes1.Tbs2  := 0; -- second buffer size
      Tx_Desc_3.Tdes1.Tbs1  := 0; --1024; -- to be set by appl
      
      Tx_Desc_3.Tdes2.Tbap1 := Tob (Buf4'Address); -- for the time being!!!!!
      
      Tx_Desc_3.Tdes3.Tbap2 := Tob (Tx_Desc_1'Address);
      
      -- next section
      declare 
	 
      begin
	 
      end;
	
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
   
   
   -- queues a frame for sending,
   -- it is meant as a stage2 repost action, which can be executed just now
   procedure Stash_For_Sending (Ba : Frame_Address; Bbc : Frame_Length_Type)
   is
   begin
      null;
   end Stash_For_Sending;
   
   
   -- sends the next queued item. note that normally there should be
   -- no more than 1 item on the stack.
   -- so this command should happen after Stash_For_Sending without any
   -- ethernet send activity in between.
   -- use Poll_Xmit_Completed after this command to ascertain its gone.
   procedure Send_Next
   is
   begin
      null;
   end Send_Next;
   
    
   -- to send a frame build it first then pass the address and the length
   -- here for transmission.
   -- the frame can ony be released once it has been successfully sent.
   -- lets see if this works as a queueing mechanism.
   procedure Send_Frame (Ba : Frame_Address; Bbc : Frame_Length_Type)
   is
   begin
      null;
   end Send_Frame;
      
      
end Finrod.Net.Eth;
