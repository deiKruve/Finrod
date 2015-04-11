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
--

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");
pragma Warnings (Off, "*is not referenced");

with System.Storage_Elements;
with Ada.Unchecked_Conversion;
with Interfaces;

with STM32F4.o7xx.Ethbuf;
with STM32F4.o7xx.Eth;
with STM32F4.o7xx.Registers;
with STM32F4.O7xx.Syscfg;
with STM32F4.O7xx.Rcc;
with Finrod.Board;
with Finrod.Thread;
with Finrod.Log;

package body Finrod.Net.Eth is
   
   package Sto  renames  System.Storage_Elements;
   package Ifce renames  Interfaces;
   package Stm  renames  STM32F4;
   package Ebuf renames  STM32F4.o7xx.Ethbuf;
   package Eth  renames  STM32F4.o7xx.Eth;
   package R    renames  STM32F4.o7xx.Registers;
   package Thr  renames  Finrod.Thread;
   package Rcc  renames STM32F4.O7xx.Rcc;
   package Scfg renames STM32F4.O7xx.Syscfg;
   
   ------------------------------
   -- some types and constants --
   ------------------------------
   
   -- the frame buffers --
   
   -- four, they are unisex, can be used for xmit and recv
   type Buf_Idx_Type is mod 4;
   Buf : array (Buf_Idx_Type) of Sto.Storage_Array (1 .. 1024);
   
   type Frame_Store_Type;
   type Frame_Store_P_Type is access all Frame_Store_Type;
   type Frame_Store_Type is record
      Buf_Idx : Buf_Idx_Type;
      Faddr   : Frame_Address_Type;
      Free    : Boolean;
      Next    : Frame_Store_P_Type;
   end record;
   
   Frame_Store : Frame_Store_P_Type := null; -- anchor of availabe eth frames
   
   
   -- the descriptors --
   
   Rx_Desc_Idx : constant Rx_Desc_Idx_Type := 0;
   Tx_Desc_Idx : Tx_Desc_Idx_Type := 0;
   
   Rx_Desc : array (Rx_Desc_Idx_type) of Ebuf.Xl_Recv_Desc_Type;
   for Rx_Desc'Alignment use 4;
   Tx_Desc : array (Tx_Desc_Idx_Type) of Ebuf.Xl_Xmit_Desc_Type;
   for Tx_Desc'Alignment use 4;
   
   
   --  the stash  --
   
   type Stashed_Type;
   type Stashed_P_Type is access all Stashed_Type;
   type Stashed_Type is record
      Frame_Addr : Frame_Address_Type;
      Frame_Len  : Frame_Length_Type;
      Next       : Stashed_P_Type;
   end record;
   
   Stash_Root    : Stashed_P_Type := null;
   Mt_Stash_Root : Stashed_P_Type := null;
   
   -- saved error regs for diagnosis:
   
   Error_Dmasr : Stm.Bits_32 := 0;
   Error_Tdes0 : Stm.Bits_32 := 0;
   Error_Rdes0 : Stm.Bits_32 := 0;
   
   --  last received frame --
   
   
   ----------------------
   --  local helpers   --
   --  mainly to build -- 
   --  the circus tent --
   ----------------------
   
   -- conversions --
   
   function Tob is new
     Ada.Unchecked_Conversion (Source => System.Address,
   			       Target => Stm.Bits_32);
   function Toa is new
     Ada.Unchecked_Conversion (Source => Stm.Bits_32,
   			       Target => System.Address);
   
   
   -- inits a list of available eth frames
   procedure Init_Frame_Store
   is
   begin
      for I in Buf_Idx_Type'Range loop
	 declare
	    Fs : constant Frame_Store_P_Type := new Frame_Store_Type;
	 begin
	    Fs.Buf_Idx  := I;
	    Fs.Faddr    := Buf (I)'Address;
	    Fs.Free     := True;
	    Fs.Next     := Frame_Store;
	    Frame_Store := Fs;
	 end;
      end loop;
   end Init_Frame_Store;
   
   
   -- mark a eth buffer used
   procedure Mark_Used (Idx : Buf_Idx_Type)
   is
      Fs : Frame_Store_P_Type := Frame_Store;
   begin
      while Fs /= null and then Fs.Buf_Idx /= Idx loop
	 Fs := Fs.Next;
      end loop;
      
      if Fs /= null then 
	 Fs.Free := False;
	 
      else
	 Log.Log_Error (Log.Eth_Error_Buffers, "buffer not found.");
      end if;
   end Mark_Used;
   
   
   procedure Mark_Used (Fa : Frame_Address_Type)
   is
      use type System.Address;
      Fs : Frame_Store_P_Type := Frame_Store;
   begin
      while Fs /= null and then Fs.Faddr /= Fa loop
	 Fs := Fs.Next;
      end loop;
      
      if Fs /= null then 
	 Fs.Free := False;
	 
      else
	 Log.Log_Error (Log.Eth_Error_Buffers, "buffer not found.");
      end if;
   end Mark_Used;
   
   
   -- return an eth buffer to the free list
   procedure Mark_free (Idx : Buf_Idx_Type)
   is
      use type System.Address;
      Fs : Frame_Store_P_Type := Frame_Store;
   begin
      while Fs /= null and then Fs.Buf_Idx /= Idx loop
	 Fs := Fs.Next;
      end loop;
      
      if Fs /= null then 
	 Fs.Free := True;
	 
      else
	 Log.Log_Error (Log.Eth_Error_Buffers, "buffer not found.");
      end if;
   end Mark_Free;
   
   
   procedure Mark_Free (Fa : Frame_Address_Type)
   is
      use type System.Address;
      Fs : Frame_Store_P_Type := Frame_Store;
   begin
      while Fs /= null and then Fs.Faddr /= Fa loop
	 Fs := Fs.Next;
      end loop;
      
      if Fs /= null then 
	 Fs.Free := True;
	 
      else 
	 Log.Log_Error (Log.Eth_Error_Buffers, "buffer not found.");
      end if;
   end Mark_Free;
   
   
   --  find a free buffer  --
   function Find_Free ( Fa : out Frame_Address_Type) 
		      return Boolean
   is
      Fs : Frame_Store_P_Type := Frame_Store;
   begin
      while Fs /= null and then Fs.all.Free = false loop
	 Fs := Fs.Next;
      end loop;
      
      if Fs /= null then
	 Fa := Fs.all'Address;
	 return True;
	 
      else
	 Log.Log_Error (Log.Eth_Error_No_Buffers, "no eth buffers");
	 return False;
      end if;
   end Find_Free;
   
   
   function Find_Free (Idx : out Buf_Idx_Type) 
		      return Boolean 
   is
      Fs : Frame_Store_P_Type := Frame_Store;
   begin
      while Fs /= null and then Fs.Free = false loop
	 Fs := Fs.Next;
      end loop;
      
      if Fs /= null then
	 Idx := Fs.Buf_Idx;
	 return True;
	 
      else
	 Log.Log_Error (Log.Eth_Error_No_Buffers, "no eth buffers");
	 return False;
      end if;
   end Find_Free;
   

   procedure Init_buffers
   is
   begin
      --- initialize the rx descriptors, as far as known
      Rx_Desc (0).Rdes0.Own   := Ebuf.DMA;
      
      Rx_Desc (0).Rdes1.Dic   := Ebuf.Disable; -- interrupt on rec off for the time.
      Rx_Desc (0).Rdes1.Rbs2  := 0; -- second buffer size
      Rx_Desc (0).Rdes1.Rer   := Ebuf.Off;
      Rx_Desc (0).Rdes1.Rch   := Ebuf.Tru;
      Rx_Desc (0).Rdes1.Rbs1  := 1024;
      
      Rx_Desc (0).Rdes2.Rbap1_Rtsl := Tob (Buf (0)'address);
      Mark_Used (0);
      Rx_Desc (0).Rdes3.Rbap2_Rtsh := Tob (Rx_Desc (1)'Address);
      ---
      Rx_Desc (1).Rdes0.Own   := Ebuf.DMA;
      
      Rx_Desc (1).Rdes1.Dic   := Ebuf.Disable; -- interrupt on rec off for the time.
      Rx_Desc (1).Rdes1.Rbs2  := 0; -- second buffer size
      Rx_Desc (1).Rdes1.Rer   := Ebuf.Off;
      Rx_Desc (1).Rdes1.Rch   := Ebuf.Tru;
      Rx_Desc (1).Rdes1.Rbs1  := 1024;
      
      Rx_Desc (1).Rdes2.Rbap1_Rtsl := Tob (Buf (1)'address);
      Mark_Used (1);
      Rx_Desc (1).Rdes3.Rbap2_Rtsh := Tob (Rx_Desc (2)'Address);
      ---
      Rx_Desc (2).Rdes0.Own   := Ebuf.DMA;
      
      Rx_Desc (2).Rdes1.Dic   := Ebuf.Disable; -- interrupt on rec off for the time.
      Rx_Desc (2).Rdes1.Rbs2  := 0; -- second buffer size
      Rx_Desc (2).Rdes1.Rer   := Ebuf.Tru;
      Rx_Desc (2).Rdes1.Rch   := Ebuf.Tru;
      Rx_Desc (2).Rdes1.Rbs1  := 1024;
      
      Rx_Desc (2).Rdes2.Rbap1_Rtsl := Tob (Buf (2)'address);
      Mark_Used (2);
      Rx_Desc (2).Rdes3.Rbap2_Rtsh := Tob (Rx_Desc (0)'Address);
      ---
      --- initialize the tx descriptors, as far as known
      Tx_Desc (0).Tdes0.Own   := Ebuf.Me;
      Tx_Desc (0).Tdes0.Ic    := Ebuf.Off; -- no int on completion
      Tx_Desc (0).Tdes0.Ls    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc (0).Tdes0.Fs    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc (0).Tdes0.Dc    := Ebuf.Off;
      Tx_Desc (0).Tdes0.Dp    := Ebuf.Off;
      Tx_Desc (0).Tdes0.Ttse  := Ebuf.Enable; -- timestamp enable
      Tx_Desc (0).Tdes0.Cic   := Ebuf.Ck_Head_Payload; -- checksum
      Tx_Desc (0).Tdes0.Ter   := Ebuf.Off;
      Tx_Desc (0).Tdes0.Thc   := Ebuf.Tru;
      
      Tx_Desc (0).Tdes1.Tbs2  := 0; -- second buffer size
      Tx_Desc (0).Tdes1.Tbs1  := 0; --1024; -- to be set by appl
      
      Tx_Desc (0).Tdes2.Tbap1_Ttsl := 0; -- for the time being!!!!!
      
      Tx_Desc (0).Tdes3.Tbap2_Ttsh := Tob (Tx_Desc (1)'Address);
      ---
      Tx_Desc (1).Tdes0.Own   := Ebuf.Me;
      Tx_Desc (1).Tdes0.Ic    := Ebuf.Off; -- no int on completion
      Tx_Desc (1).Tdes0.Ls    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc (1).Tdes0.Fs    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc (1).Tdes0.Dc    := Ebuf.Off;
      Tx_Desc (1).Tdes0.Dp    := Ebuf.Off;
      Tx_Desc (1).Tdes0.Ttse  := Ebuf.Enable; -- timestamp enable
      Tx_Desc (1).Tdes0.Cic   := Ebuf.Ck_Head_Payload; -- checksum
      Tx_Desc (1).Tdes0.Ter   := Ebuf.Off;
      Tx_Desc (1).Tdes0.Thc   := Ebuf.Tru;
      
      Tx_Desc (1).Tdes1.Tbs2  := 0; -- second buffer size
      Tx_Desc (1).Tdes1.Tbs1  := 0; --1024; -- to be set by appl
      
      Tx_Desc (1).Tdes2.Tbap1_Ttsl := 0; -- for the time being!!!!!
      
      Tx_Desc (1).Tdes3.Tbap2_Ttsh := Tob (Tx_Desc (2)'Address);
      ---
      Tx_Desc (2).Tdes0.Own   := Ebuf.Me;
      Tx_Desc (2).Tdes0.Ic    := Ebuf.Off; -- no int on completion
      Tx_Desc (2).Tdes0.Ls    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc (2).Tdes0.Fs    := Ebuf.Tru; --!!!!!!!!!!!!!!!!!!!!!!!!!!
      Tx_Desc (2).Tdes0.Dc    := Ebuf.Off;
      Tx_Desc (2).Tdes0.Dp    := Ebuf.Off;
      Tx_Desc (2).Tdes0.Ttse  := Ebuf.Enable; -- timestamp enable
      Tx_Desc (2).Tdes0.Cic   := Ebuf.Ck_Head_Payload; -- checksum
      Tx_Desc (2).Tdes0.Ter   := Ebuf.Tru;
      Tx_Desc (2).Tdes0.Thc   := Ebuf.Tru;
      
      Tx_Desc (2).Tdes1.Tbs2  := 0; -- second buffer size
      Tx_Desc (2).Tdes1.Tbs1  := 0; --1024; -- to be set by appl
      
      Tx_Desc (2).Tdes2.Tbap1_Ttsl := 0; -- for the time being!!!!!
      
      Tx_Desc (2).Tdes3.Tbap2_Ttsh := Tob (Tx_Desc (0)'Address);
   end Init_Buffers;
   

   -- sets the dna bus mode and enables interrupts if needed
   -- sets first descriptor addresses
   procedure Set_Dma_Busmode
   is
      DMABMR_Tmp : Eth.DMABMR_Register := R.Eth_Mac.DMABMR;
   begin
      DMABMR_Tmp.USP  := Eth.On;        -- Use separate PBL (could be at the moment)
      DMABMR_Tmp.RDP  := Eth.RDP_2Beat; -- maximum number of beats (RxDMA)
      DMABMR_Tmp.FB   := Eth.On;        -- Fixed Burst
      DMABMR_Tmp.PBL  := Eth.PBL_2Beat; -- maximum number of beats (TxDMA)
      DMABMR_Tmp.EDFE := Eth.Enabled;   -- Enhanced Descriptor Enable
      -- I hope thats all. USP could be off id the buffers are vaguely equal size.
      R.Eth_Mac.DMABMR := DMABMR_Tmp;
      -- we are not going to use interrupts so
      -- Ethernet DMA interrupt enable register will stay at 0's.
      
      -- first descriptor addresses 
      R.Eth_Mac.DMARDLAR := Tob (Rx_Desc (Rx_Desc_Idx)'Address); 
      R.Eth_Mac.DMATDLAR := Tob (Tx_Desc (Tx_Desc_Idx)'Address);
   end Set_Dma_Busmode;
   
   
   -- next Set the 1st MAC address
   procedure Set_Addresses
   is
      use type Stm.Bits_48;
      use type Ifce.Unsigned_64;
      MACA0HR_Tmp : Eth.MACA0HR_Register := R.Eth_Mac.MACA0HR;
      Address  : constant Ifce.Unsigned_64  := 
	Ifce.Unsigned_64 (Board.Get_Mac_Address);
   begin
      R.Eth_Mac.MACA0LR  := Stm.Bits_32 (Address and 16#ffff_ffff#);
      MACA0HR_Tmp.MACA0H := Stm.Bits_16 (Ifce.Shift_Right (Address, 32));
      MACA0HR_Tmp.Mo     := 1;
      R.Eth_Mac.MACA0HR  := MACA0HR_Tmp;
      
      -- set broadcast address
      declare 
	 use type Stm.Bits_6;
	 --use type Stm.Bits_48;
	 --use type Ifce.Unsigned_64;
	 MACA0HR_Tmp : Eth.MACA0HR_Register := R.Eth_Mac.MACA0HR; -- test
	 MACA1HR_Tmp : Eth.MACA1HR_Register := R.Eth_Mac.MACA1HR;
	 Address  : constant Ifce.Unsigned_64  := 
	   Ifce.Unsigned_64 (Board.Get_Bcast_Address);
      begin
	 R.Eth_Mac.MACA1LR  := Stm.Bits_32 (Address and 16#ffff_ffff#);
	 MACA1HR_Tmp.MACA1H := Stm.Bits_16 (Ifce.Shift_Right (Address, 32));
	 MACA1HR_Tmp.Ae     := Eth.Enabled;
	 MACA1HR_Tmp.Sa     := Eth.Maca_Da;
	 MACA1HR_Tmp.Mbc    := Eth.Lsbyte + Eth.Byte2;
	 R.Eth_Mac.MACA1HR  := MACA1HR_Tmp;
      end;
   end Set_Addresses;
   
   
   -- the mac frame filter 
   procedure Init_Frame_Filter 
   is
      MACFFR_Tmp : Eth.MACFFR_Register := R.Eth_Mac.MACFFR;
   begin
      MACFFR_Tmp.RA    := Eth.Off;       -- Receive all
      MACFFR_Tmp.HPF   := Eth.Off;       -- for perfect, acc cube
      MACFFR_Tmp.SAF   := Eth.Off;       -- Source address filter enable
      MACFFR_Tmp.SAIF  := Eth.Off; 
      MACFFR_Tmp.PCF   := Eth.PCF_BlockAll;
      MACFFR_Tmp.BFD   := Eth.Pass_Allb; -- Broadcast frame disable
      MACFFR_Tmp.PAM   := Eth.Pass_Allm; -- Pass all mutlicast
      MACFFR_Tmp.DAIF  := Eth.Off; 
      MACFFR_Tmp.HM    := Eth.Off;       -- for perfect, acc cube
      MACFFR_Tmp.HU    := Eth.Normal;    -- for perfect, acc cube
      MACFFR_Tmp.PM    := Eth.Off;       -- Promiscuous mode off
      R.Eth_Mac.MACFFR := MACFFR_Tmp;
   end Init_Frame_Filter;
   

   -- mac control register
   procedure Init_Maccr
   is
      MACCR_Tmp : Eth.MACCR_Register := R.Eth_Mac.MACCR;
   begin
      MACCR_Tmp.CSTF  := Eth.Strip_Crc;
      MACCR_Tmp.Wd    := Eth.WD_On; -- according to cube (2048 bytes max)
      MACCR_Tmp.JD    := Eth.Jt_On; -- according to cube (2048 bytes max)
      MACCR_Tmp.IFG   := Eth.IFG_96Bit;
      MACCR_Tmp.CSD   := Eth.Cs_On; -- cube but -- check for RMII --------
      MACCR_Tmp.FES   := Eth.Mb_100;
      MACCR_Tmp.ROD   := Eth.Off;   -- enabled, acc to cube
      MACCR_Tmp.LM    := Eth.Off;   -- loopback off
      MACCR_Tmp.DM    := Eth.Off;   -- duplex mode off
      MACCR_Tmp.IPCO  := Eth.Enabled; -- ip checksum offload on
      MACCR_Tmp.RD    := Eth.Retr_Disabled; -- gives an error after 1 collision
					    -- this when working, and when starting up????----------------------
      MACCR_Tmp.APCS  := Eth.On;    -- Automatic Pad/CRC stripping
      MACCR_Tmp.Bl    := Eth.BL_10; -- back off time when collision.
      MACCR_Tmp.DC    := Eth.On;    -- deferral check max and give error.
      R.Eth_Mac.MACCR := MACCR_Tmp;
      
      -- and we are not done yet, everything is still off.
   end Init_Maccr;
   
   
   -- and here comes die ganze Zirkuskraft.
   procedure Starting with inline
   is
      MACCR_Tmp : Eth.MACCR_Register := R.Eth_Mac.MACCR;
   begin
      MACCR_Tmp.Te    := Eth.On;
      MACCR_Tmp.Re    := Eth.On;
      R.Eth_Mac.MACCR := MACCR_Tmp;
   end Starting;
   
   
   ----------------------
   -- public interface --
   ----------------------
   
   -- starts the receiver DMA
   procedure Start_Receive_DMA
   is
      Dmaomr_Tmp : Eth.DMAOMR_Register := R.Eth_Mac.Dmaomr;
   begin
      Dmaomr_Tmp.SR    := Eth.Start;
      R.Eth_Mac.Dmaomr := Dmaomr_Tmp;
   end Start_Receive_DMA;
   
   
   -- returns the erronous dma status image caught at the last Receive poll
   function Dma_Status_Image return String
   is (" DMAsr = " & Stm.Bits_32'Image (Error_Dmasr));
   
   
   -- returns the Rdescriptors status image of the last received frame.
   function Rx_Status_Image return String 
     is (" Rdes0 = " & Stm.Bits_32'Image (Error_Rdes0));
   
   
   -- returns the 2 status images of the last transmit
   function Tx_Status_Image return String
   is (" DMAsr = " & Stm.Bits_32'Image (Error_Dmasr) & 
	 " Tdes0 = " & Stm.Bits_32'Image (Error_Tdes0));
   -- Tdes0.ec trips when no cable (too many collisions)
   --
   -- DMAsr.tps = 6 Suspended; 
   --             Transmit descriptor unavailable or transmit buffer underflow
   -- DMAsr.tbus = 1 Transmit buffer unavailable status, (cause next one is mt?)
   
   
   -- poll for a received frame and determine the type.
   -- if the answer in 'Rx_Recvd' is yes the received frame details are in
   --  Recvd_Frame_P : Frame_Address_Type; 
   --  Recvd_Frame_L : Frame_Length_Type;
   ---
   -- can be posted in the job thread   
   -- in that case it removes itself on error and when a rx-frame is found.
   -- in order not to overwrite the received frame address in the case of
   -- a new received frame.
   -- so it must be reinserted after the details have been processed.
   procedure Rx_Poll
   is
      use type Stm.Bits_1;
      function Des0Tob is new
	Ada.Unchecked_Conversion (Source => Ebuf.Rdes0_Type,
				  Target => Stm.Bits_32);
      function DmasrTob is new
	Ada.Unchecked_Conversion (Source => Eth.DMASR_Register,
				  Target => Stm.Bits_32);
      Dmasr_Tmp : constant Eth.DMASR_Register := R.Eth_Mac.DMASR;
   begin
      if Dmasr_Tmp.Ais = Eth.Tripped then
	 Error_Dmasr  := DmasrTob (Dmasr_Tmp); -- for later analysis
	 Log.Log_Error (Log.Eth_Error_Rcve, DMA_Status_Image);
	 Rx_Recvd     := Error_Fatal; -- until we know better.
	 -- remove yrself out of the thread
	 Thr.Delete_Job (Rx_Poll'Access);
	 
      elsif Dmasr_Tmp.Rs = Eth.F_Recd then
	 for I in Rx_Desc_Idx_Type'Range loop
	    if Rx_Desc (I).Rdes0.Own = Ebuf.Me then -- got a frame
	       if Rx_Desc (I).Rdes0.Es = Ebuf.Tripped then -- but is it faulty?
		  Error_Rdes0  := des0tob (Rx_Desc (I).Rdes0);
		  Log.Log_Error (Log.Eth_Error_Rcve, Rx_Status_Image);
		  Rx_Recvd     := Error_Fatal; -- until we know better.
	       else
		  Rx_Recvd     := Yes;
	       end if;
	       -- remove yrself out of the thread
	       Thr.Delete_Job (Rx_Poll'Access);
	       return;
	    end if;
	 end loop;
	 Log.Log_Error (Log.Eth_Error_Rcve, "no own buffer found.");
	 Rx_Recvd     := Error_Fatal; -- until we know better.
	 -- remove yrself out of the thread
	 Thr.Delete_Job (Rx_Poll'Access);
	 
      else
	 Rx_Recvd     := No;
      end if;
   end Rx_Poll;
   
   
   -------------------------------
   -- for the parent and        --  
   -- uncles only               --
   -------------------------------
   
   -- to send a frame build it first then pass the address and the length
   -- here for transmission.
   -- the frame can ony be released once it has been successfully sent.
   -- 
   -- the function returns false when 
   -- the next descriptor in the array is still in use. 
   -- If this were to happen the eth net quality is most likely very poor, 
   -- since there are buffers waiting to be transmitted.
   -- use Poll_Xmit_Completed after this command to ascertain its gone.
   procedure Send_Frame (Ba  : in Frame_Address_Type; 
			Bbc : in Frame_Length_Type)
   is
      use type Stm.Bits_1;
      Tdes0_Tmp : Ebuf.Tdes0_Type := Tx_Desc (Tx_Desc_Idx).Tdes0;
   begin
      if Tdes0_Tmp.Own = Ebuf.Me then
	 Tdes0_Tmp.Ls                      := Ebuf.Tru; --!!!!!!!
	 Tdes0_Tmp.Fs                      := Ebuf.Tru; --!!!!!!!
	 Tdes0_Tmp.Ttse                    := Ebuf.Enable; -- timestamp enable
	 Tdes0_Tmp.Cic                     := Ebuf.Ck_Head_Payload; -- checksum
	 Tx_Desc (Tx_Desc_Idx).Tdes0       := Tdes0_Tmp;
	 Tx_Desc (Tx_Desc_Idx).Tdes1.Tbs1  := Bbc;
	 Tx_Desc (Tx_Desc_Idx).Tdes2.Tbap1_Ttsl  := Tob (Ba);
	 Tdes0_Tmp.Own                     := Ebuf.Dma; -- control to DMA
	 Tx_Desc (Tx_Desc_Idx).Tdes0       := Tdes0_Tmp;
	 
	 -- and start transmission
	 R.Eth_Mac.DMATDLAR := Tob (Tx_Desc (Tx_Desc_Idx)'Address);
	 declare 
	    Dmaomr_Tmp : Eth.DMAOMR_Register := R.Eth_Mac.Dmaomr;
	 begin
	    Dmaomr_Tmp.ST    := Eth.Start;
	    R.Eth_Mac.Dmaomr := Dmaomr_Tmp;
	 end;
	 Dix             := Tx_Desc_Idx;       -- for return to app for polling
	 Tx_Desc_Idx     := Tx_Desc_Idx + 1;   -- assume it is empty
	 
	 Dix_Done        := Ongoing;           -- it is being xmitted
      else
	 Log.Log_Error 
	   (Log.Eth_Error_Xmit, "ethernet sits too long on buffers");
	 Dix_Done        := Error_Fatal;
      end if;
   end Send_Frame;
   
   
   -- queues a frame for sending,
   -- it is meant as a stage2 repost action, which can be executed just now
   procedure Stash_For_Sending (Ba  : Frame_Address_Type; 
				Bbc : Frame_Length_Type)
   is
      Stash : Stashed_P_Type;
      St    : Stashed_P_Type;
      
   begin
      if Mt_Stash_Root /= null then
	 Stash         := Mt_Stash_Root;
	 Mt_Stash_Root := Mt_Stash_Root.Next;
      else
	 Stash         := new Stashed_Type;
      end if;
      
      Stash.Frame_Addr := Ba;
      Stash.Frame_Len  := Bbc;
      
      -- add at the end of the list
      Stash.Next       := null;
      
      if Stash_Root = null then
	 Stash_Root    := Stash;
	 
      else
	 St            := Stash_Root;
	 while St.next /= null loop
	    St         := St.Next;
	 end loop;
	 
	 St.Next       := Stash;
      end if;
   end Stash_For_Sending;
   
   
   -- sends the next queued item. 
   -- gets the next tx_descriptor and fits the frame into it.
   -- then send through DMA to the mac and transmits.
   --
   -- note that normally there should be no more than 1 item on the stack.
   -- so this command should happen after Stash_For_Sending without any
   -- ethernet send activity in between.
   -- the function returns false when 
   -- the next descriptor in the array is still in use. 
   -- If this were to happen the eth net quality is most likely very poor, 
   -- since there are buffers waiting to be transmitted.
   -- use Poll_Xmit_Completed after this command to ascertain its gone.
   ---
   -- can be posted in the job thread
   procedure Send_Next
   is
      use type Stm.Bits_1;
      Stash : constant Stashed_P_Type    := Stash_Root;
      St    : Stashed_P_Type;
   begin
      if Tx_Desc (Tx_Desc_Idx).Tdes0.Own = Ebuf.Me then
	 Tx_Desc (Tx_Desc_Idx).Tdes1.Tbs1       := Stash.Frame_Len;
	 Tx_Desc (Tx_Desc_Idx).Tdes2.Tbap1_Ttsl := Tob (Stash.Frame_Addr);
	 Tx_Desc (Tx_Desc_Idx).Tdes0.Own        := Ebuf.Dma; -- control to DMA
	 
	 -- and start transmission
	 R.Eth_Mac.DMATDLAR  := Tob (Tx_Desc (Tx_Desc_Idx)'Address);
	 declare 
	    Dmaomr_Tmp : Eth.DMAOMR_Register := R.Eth_Mac.Dmaomr;
	 begin
	    Dmaomr_Tmp.ST    := Eth.Start;
	    R.Eth_Mac.Dmaomr := Dmaomr_Tmp;
	 end;
	 
	 if Stash_Root = Stash then
	    St              := Stash_Root;         -- out of the chain and
	    Stash_Root      := St.Next;
	    St.Next         := Mt_Stash_Root;      -- into the empty chain
	    Mt_Stash_Root   := St;
	    
	 else
	     Log.Log_Error 
	       (Log.Eth_Error_Xmit, "programming error");
	     Dix_Done        := Error_Fatal;
	 end if;
	 
	 Dix             := Tx_Desc_Idx;        -- for return to app
	 Tx_Desc_Idx     := Tx_Desc_Idx + 1;    -- assume it is empty
	 
	 Dix_Done        := Ongoing;              -- it is being xmitted
      else
	 Log.Log_Error 
	   (Log.Eth_Error_Xmit, "ethernet sits too long on buffers");
	 Dix_Done        := Error_Fatal;
      end if;
      Thr.Delete_Job (Send_Next'Access);
   end Send_Next;
   
    
   -- since we have a strictly sequential comms pattern we
   -- check for completed or error.
   -- in case of error, normally there is a re-transmission 
   -- after the error has been cleared.
   ---
   -- can be posted in the job thread
   procedure Poll_Xmit_Completed
   is
      use type Stm.Bits_1;
      function Des0Tob is new
	Ada.Unchecked_Conversion (Source => Ebuf.Tdes0_Type,
				  Target => Stm.Bits_32);
      function DmasrTob is new
	Ada.Unchecked_Conversion (Source => Eth.DMASR_Register,
				  Target => Stm.Bits_32);
      Tdes0_Tmp : constant Ebuf.Tdes0_Type    := Tx_Desc (Dix).Tdes0;
      Dmasr_Tmp : constant Eth.DMASR_Register := R.Eth_Mac.DMASR;
   begin
      if Dmasr_Tmp.Ais = Eth.Tripped or Tdes0_Tmp.Es = Ebuf.Tripped then
	 Error_Dmasr  := DmasrTob (Dmasr_Tmp); -- for later analysis
	 Error_Tdes0  := des0tob (Tdes0_Tmp);
	 Log.Log_Error (Log.Eth_Error_Xmit, Tx_Status_Image);
	 Dix_Done     := Error_Retry;
	 -- remove yrself here
	 Thr.Delete_Job (Poll_Xmit_Completed'Access);
	 
      elsif Tdes0_Tmp.Own = Ebuf.Dma then
	 Dix_Done     := Ongoing;
	   
      else
	 declare
	    subtype Tdec3_Time_Type is Ebuf.Tdes3_Type;
	    subtype Tdec2_Time_Type is Ebuf.Tdes2_Type;
	 begin
	    Time.Seconds := Tdec3_Time_Type (Tx_Desc (Dix).Tdes3).Tbap2_Ttsh;
	    Time.Subsecs := Tdec2_Time_Type (Tx_Desc (Dix).Tdes2).Tbap1_Ttsl;
	 end;
	 Dix_Done := Complete;
	 -- return the buffer for reuse
	 Mark_Free (Toa (Tx_Desc (Dix).Tdes3.Tbap2_Ttsh));
	 -- remove yrself here
	 Thr.Delete_Job (Poll_Xmit_Completed'Access);
      end if;
   end Poll_Xmit_Completed;
   
  
   
   --------------------------
   --  for initialization  --
   --------------------------
   
   -- sets the ehh interface to RMII
   -- this must be done before Init_Pins
   procedure Set_Eth_Interface
   is
      PMC_Tmp      : Scfg.PMC_Register   := R.Syscfg.PMC;
   begin
      -- before all else select the eth media interface
      -- reduced interface on Olimex
      PMC_Tmp.MII_RMII_SEL    := Scfg.RMII;
      -- write to hardware
      R.Syscfg.PMC            := PMC_Tmp;
   end Set_Eth_Interface;

   -- starts the ethernet clock
   -- and resets the MAC
   procedure Init_Eth_Clock
   is
      Ahb1en_Tmp   : Rcc.AHB1EN_Register  := R.Rcc.AHB1ENR;
   begin
       Ahb1en_Tmp.ETHMAC    := Rcc.Enable;  -- mac clock
       Ahb1en_Tmp.ETHMACRX  := Rcc.Enable;  -- receive clock
       Ahb1en_Tmp.ETHMACTX  := Rcc.Enable;  -- transmit clock
       R.Rcc.AHB1ENR        := Ahb1en_Tmp;
       
       -- reset the ethernet mac
       declare
	  Ahb1rst_Tmp  : Rcc.AHB1RST_Register := R.Rcc.AHB1RSTR;
       begin
	  Ahb1rst_Tmp.ETHMAC   := Rcc.Off;
	  R.Rcc.AHB1RSTR       := Ahb1rst_Tmp;
	  
	  Ahb1rst_Tmp.ETHMAC   := Rcc.Reset;
	  R.Rcc.AHB1RSTR       := Ahb1rst_Tmp;
	  
	  Ahb1rst_Tmp.ETHMAC   := Rcc.Off;
	  R.Rcc.AHB1RSTR       := Ahb1rst_Tmp;
       end;
   end Init_Eth_Clock;
   
      
   -- resets all MAC subsystem internal registers and logic
   -- After reset all the registers holds their respective reset values
   procedure Soft_Reset
   is
      use type Stm.Bits_1;
      Dmabmr_Tmp : Eth.DMABMR_Register := R.Eth_Mac.DMABMR;
   begin
      Dmabmr_Tmp.SR := Eth.Reset;
      R.Eth_Mac.DMABMR := Dmabmr_Tmp;
      while Dmabmr_Tmp.SR /= Eth.Off loop
	 Dmabmr_Tmp := R.Eth_Mac.DMABMR;
      end loop;
   end Soft_Reset;
   
   
   ------------------------------
   --  for initialization  of  --
   -- the finite state machine --
   ------------------------------
   
   Fsm_State : State_Selector_Type := Eth_Idle;
   
   procedure Fsm
   is
   begin
      case Fsm_State is
	 when Eth_Idle              =>
	    null;
	 when Eth_Init_Buffers      =>
	    Init_Frame_Store;
	    Init_Buffers;
	    Fsm_State := Eth_Set_Addresses;
	 when Eth_Set_Addresses     =>
	    Set_Dma_Busmode;
	    Set_Addresses;
	    Fsm_State := Eth_Init_Frame_Filter;
	 when Eth_Init_Frame_Filter =>
	    Init_Frame_Filter;
	    Fsm_State := Eth_Init_Maccr;
	 when Eth_Init_Maccr        =>
	    Init_Maccr;
	    fsm_State := Eth_Waiting_To_Start;
	 when Eth_Waiting_To_Start  =>
	    Thr.Delete_Job (Fsm'Access);
	    fsm_State := Eth_Ready_To_Start;
	 when Eth_Ready_To_Start    =>
	    null; -- hang here until the phy is done
	 when Eth_Starting          =>
	    Starting;
	    Thr.Delete_Job (Fsm'Access);
	    Fsm_State := Eth_Ready;
	 when Eth_Ready             =>
	    null;
      end case;
   end Fsm;
   
   
   -- when the initialization is done 'State' will return 'Eth_Ready_To_Start'.
   -- when the initialization is done 'State' will return 'Eth_Ready'.
   function State return State_Selector_Type 
   is (Fsm_State);
   
   
   -- starts the ETH initialization procedure from Eth_Init_Buffers.
   --  (a soft reset was done already before initing the PTP timer)
   --  (so when a soft reset is required also the PTP timer must be restarted)
   -- the PHY's init fsm must have been on the job stack already, since
   -- it takes about half a sec to complete.
   -- once finished the fsm will disappear from the jobstack and 
   -- the state selector will be at Eth_Ready_To_Start; awaiting
   -- Eth_Start.
   procedure Reset
   is
   begin
      -- Soft_Reset;
      Fsm_State := Eth_Init_Buffers;
      Thr.Insert_Job (Fsm'Access);
   end Reset;
   
   
   -- starts all ethernet facilities, after eth and Phy are initialized and ready
   -- if not in State 'Eth_Ready_To_Start' the function will return false.
   -- else true.
   -- 
   procedure Eth_Start
   is
   begin
      if Fsm_State = Eth_Ready_To_Start then
	 Fsm_State := Eth_Starting;
	 Thr.Insert_Job (Fsm'Access);
      end if;
   end Eth_Start;
   
   
   ---------------------
   -- debug interface --
   ---------------------
   
   -- sets the mac loopback mode on or off
   procedure Set_Mac_Loopback_Mode (B : On_Off_Type)
   is
   begin
      null;
   end Set_Mac_Loopback_Mode;
   

end Finrod.Net.Eth;
