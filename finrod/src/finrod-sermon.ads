------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                         F I N R O D . S E R M O N                        --
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
-- a driver for uart1 for us by the diagnostic module
--
-- only procedure Init_USART1 ( for initializing in init_pins)
-- and procedure Send_String (S : String) are for general use
-- the rest of the interface is used in the sercom statemachine

-- set minicom to 
-- Baudrate 115200.
-- 8 databits, no parity, 2 stopbits, full duplex.
-- no handshaking, 3 wire connection.
--

with STM32F4;

package Finrod.Sermon with Elaborate_Body is
   
   ------------------------------------------
   -- Incoming Message Interface structure --
   -- rebase it after processing a message --
   -- or after an error                    --
   -- (but this should not be needed)      --
   ------------------------------------------
   
   Message_Length : constant Positive := 256;
   -- incoming message size for uart 6.
   -- check the use of this !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   -- look like mix between xmit and recv

   type Uart_Data_Type is new String (1 .. Message_Length);
   subtype Srd_Index_Type is Integer range 1 .. Message_Length;
   type Uart_Data_Access_Type is access all Uart_Data_Type;
   
   Serial_Recd_Data_A : Uart_Data_Access_Type;
   -- incoming message buffer access
   
   Srd_Index            : Srd_Index_Type := 1; 
   -- Last Written Char + 1.
   
   Srd_Terminator_Index : Srd_Index_Type := 1; 
   -- Last terminator Char + 1.
   
   Srd_Terminator       : constant Character := ASCII.CR;
   -- terminating character of a incoming message
   
   
   -----------------
   -- error flags --
   -----------------
   
   Receiver_Error : Boolean := False;
   -- set to true by client or locally on invalid Serial_Recd_Data
   -- reset internally on reception of the next Srd_Terminator
   -- so any info before the next terminator will be lost.
   
   
   ---------------------------
   -- initialize the sermon --
   ---------------------------
   
   procedure Init_USART6;
   -- initializes uart6 and its dma structure
   -- both for sending and receiving.
   -- Baudrate 115200.
   -- 8 databits, no parity, 2 stopbits, full duplex
   
   
   -----------------------
   -- polling functions --
   -----------------------
   
   function Receiver_Is_Full return Boolean with Inline;
   -- is the receiver full?
   
   function Transmitter_Is_Empty return Boolean with Inline;
   -- is the transmitter done?
   
   function Uart_Error return Boolean with Inline;
   -- did a uart error occur?
   -- no internal action is taken
   
   function Dma2_Error return Boolean with Inline;
   -- did a dma error occur?
   -- no internal action is taken
   
   
   procedure Send_String (S : String);
   -- sends a string record < 64 bytes out on uart3 
   -- string must be < 64 characters, a lf will be added
   -- at the end.
   
private
   Serial_Recd_Data : aliased Uart_Data_Type;
end Finrod.Sermon;
