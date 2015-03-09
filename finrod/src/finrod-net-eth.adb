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
with Interfaces;

with STM32F4.o7xx.Ethbuf;
with STM32F4.o7xx.Eth;
with STM32F4.o7xx.Registers;

with Finrod.Board;
with Finrod.Thread;

package body Finrod.Net.Eth is
   
   package Sto  renames  System.Storage_Elements;
   package Ifce renames  Interfaces;
   package Stm  renames  STM32F4;
   package Ebuf renames  STM32F4.o7xx.Ethbuf;
   package Eth  renames  STM32F4.o7xx.Eth;
   package R    renames  STM32F4.o7xx.Registers;
   package Thr  renames  Finrod.Thread;
      
   ------------------------------
   -- some types and constants --
   ------------------------------
   
   -- the frame buffers
   -- four, they are unisex, can be used for xmit and recv
   Buf1 : Sto.Storage_Array (1 .. 1024);
   Buf2 : Sto.Storage_Array (1 .. 1024);
   Buf3 : Sto.Storage_Array (1 .. 1024);
   Buf4 : Sto.Storage_Array (1 .. 1024);
   

   -- the frame descriptors
   -- 3 of each, until we need more
   Rx_Desc_1 : Ebuf.Xl_Recv_Desc_Type;
   Rx_Desc_2 : Ebuf.Xl_Recv_Desc_Type;
   Rx_Desc_3 : Ebuf.Xl_Recv_Desc_Type;

   Tx_Desc_1 : Ebuf.Xl_Xmit_Desc_Type;
   Tx_Desc_2 : Ebuf.Xl_Xmit_Desc_Type;
   Tx_Desc_3 : Ebuf.Xl_Xmit_Desc_Type;
   
   -- conversions 
   function Tob is new
     Ada.Unchecked_Conversion (Source => System.Address,
   			       Target => Stm.Bits_32);
   --  function Toa is new
   --    Ada.Unchecked_Conversion (Source => Stm.Bits_32,
   --  			       Target => System.Address);
   
   
   ----------------------
   --  local helpers   --
   --  mainly to build -- 
   --  the circus tent --
   ----------------------
   
   procedure Init_buffers
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
   end Init_Buffers;
   
   
   -- next section, do a warm dma reset incase this was a warm init.
   procedure Dma_Reset
   is
      use type Stm.Bits_1;
      Dmabmr_Tmp : Eth.DMABMR_Register := R.Eth_Mac.DMABMR;
   begin
      Dmabmr_Tmp.SR := Eth.Reset;
      R.Eth_Mac.DMABMR := Dmabmr_Tmp;
      while Dmabmr_Tmp.SR /= Eth.Off loop
	 Dmabmr_Tmp := R.Eth_Mac.DMABMR;
      end loop;
   end Dma_Reset;
   
   
   -- next Set the 1st MAC address
   procedure Set_Addresses
   is
      use type Stm.Bits_48;
      use type Ifce.Unsigned_64;
      MACA0HR_Tmp : Eth.MACA0HR_Register := R.Eth_Mac.MACA0HR;
      Address  : constant Ifce.Unsigned_64  := Ifce.Unsigned_64 (Board.Get_Mac_Address);
   begin
      R.Eth_Mac.MACA0LR  := Stm.Bits_32 (Address);
      MACA0HR_Tmp.MACA0H := Stm.Bits_16 (Ifce.Shift_Right (Address, 32));
      MACA0HR_Tmp.Mo     := 1;
      R.Eth_Mac.MACA0HR  := MACA0HR_Tmp;
      
      -- set broadcast address
      declare 
	 use type Stm.Bits_6;
	 --use type Stm.Bits_48;
	 --use type Ifce.Unsigned_64;
	 MACA1HR_Tmp : Eth.MACA1HR_Register := R.Eth_Mac.MACA1HR;
	 Address  : constant Ifce.Unsigned_64  := Ifce.Unsigned_64 (Board.Get_Bcast_Address);
      begin
	 R.Eth_Mac.MACA1LR  := Stm.Bits_32 (Address);
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
	    Init_Buffers;
	    Fsm_State := Eth_Dma_Reset;
	 when Eth_Dma_Reset         =>
	    Dma_Reset;
	    Fsm_State := Eth_Set_Addresses;
	 when Eth_Set_Addresses     =>
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
   
   
   -- starts the ETH initialization procedure from a soft reset.
   -- it will put the PHY's init fsm on the job stack for executing 1 pass
   -- every scan period.
   -- once finished the fsm will disappear from the jobstack and 
   -- the state selector will be at ready.
   procedure Reset
   is
   begin
      Fsm_State := Eth_Init_Buffers;
      Thr.Insert_Job (Fsm'Access);
   end Reset;
   
   
   -- starts all ethernet facilities.
   -- if not in State 'Eth_Ready_To_Start' the function will return false.
   -- else true.
   function Eth_Start return Boolean 
   is
   begin
      if Fsm_State = Eth_Ready_To_Start then
	 Thr.Insert_Job (Fsm'Access);
	 return True;
      else return False;
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
