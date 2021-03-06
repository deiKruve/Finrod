------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                          F I N R O D . B O A R D                         --
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
-- implements basic board functions necessary to bring up the rest 
-- of the board for powerlink.
--
-- A Note on Board addresses:
-- if we start of with the 10.0.0.0 net
-- and if we use the last but 1 group for the board addressing then
-- we have 255 addresses on each board for mailboxes outside the high speed 
-- interface, for calibration, id strings etc.
-- it is proposed that the master lives at address 10.0.1.0
-- if we leave the addresses 250 .. 255 unused for evt spy boxes, bridges etc
-- that gives a maximum of 248 stations (10.0.2.0/255 .. 10.0.249.0/255).
--
-- a 2nd note on board addresses:
-- the last but 1 group of both the ip address and the mac address of
-- Each Board can contain the Board ID that is set up on the hardware.


with STM32F4.o7xx.Eth;

package Finrod.Board is
   
   subtype Board_Type  is STM32F4.Byte;
   subtype Board_Id    is STM32F4.Byte;
   subtype Mac_Address is STM32F4.Bits_48;
   subtype Ip_Address  is STM32F4.Bits_32;
   
   procedure Init_Clocks;
   --  RCC enable registers for some blocks
   --  ethernet is not in this routine, it needs to be started later
   
   procedure Init_Pins;
   -- inits the basic board with serial and eth comms and id pins
   -- it will call any other  resource init functions 
   -- that might be needed
   
   function Get_Type return Board_Type;
   -- returns the board type
   -- the type should match the software functions of the board.
   
   function Get_Id return Board_Id;
   -- returns the board id
   -- this is supposed to guide the software into executing the 
   -- right subset of functions.
   
   function Get_Mac_Address return Mac_Address with Inline;
   -- returns the mac address. This is the systems basic Mac address with 
   -- the address set on hardware switches as the last group
   
   function Get_Ip_Address return Ip_Address with Inline;
   -- returns the ip address. this is the systems basic IP address with
   -- the address set on hardware switches as the last group
   
   function Get_Master_Ip_Address return Ip_Address with Inline;
   -- returns the ip address of the bus master,
   -- hope this can stay here
   
   function Get_Bcast_Address return Mac_Address with Inline;
   -- returns the system-lan's broadcast address;
   
   function Get_PHY_Address return STM32F4.Bits_5 with Inline;
   -- returns the harware PHY address;
   
   function Get_PHY_Mspeed return STM32F4.Bits_3 with Inline;
   --  returns the PHY service bus speed;
   
   procedure Set_Type (Typ : Board_Type) with Inline;
   -- sets the board type
   
   procedure Set_Id (Id : Board_Id) with Inline;
   -- new description is needed here
   
   -- sets the board id and incorporates it into the net addresses
   -- as explained above.
   -- this should really be an internal procedure, but jus in case it is 
   -- declared here.
   -- To be set by the application in Init at top level.
   
   procedure Set_Mac_Address (M : Mac_Address) with Inline;
   -- Sets the mac address of the stm board.
   -- To be set by the application in Init at top level
   
   procedure Set_Ip_Address (Ip : Ip_Address) with Inline;
   -- Sets the ip address of the stm board.
   -- To be set by the application in Init at top level.
   
   procedure Set_Master_Ip_Address (Ip : Ip_Address) with Inline;
   -- Sets the ip address of the bus masternode.
   -- To be set by the application if needed.
   -- Easiest would be to leave it where it is.
   
private
   
   My_Mac_Address       : Stm32F4.Bits_48  := 16#02_00_00_00_00_00#;
   My_Ip_Address        : Stm32F4.Bits_32  := 16#10_00_00_00#;
   -- the addresses of the board.
   -- To be set by the application, by transferring the value defined in
   -- hw_def-b<x>.ads
   
   Master_Ip_Address : Stm32F4.Bits_32  := 16#10_00_01_00#;
   -- the Ip Address of the master node
   -- must also be set by the application if change is needed
   
   Broadcast_Mac_Address : Stm32F4.Bits_48  := 16#03_00_00_00_00_00#;
   
   
   -------------------------------------------------------------
   --  below are some constants for Olimex stm32-e407 boards  --
   --  They should not need changing                          --
   -------------------------------------------------------------
   
   PHY_Address : constant Stm32F4.Bits_5    := 0;
   -- harware PHY address as strapped on the Olimex board;
   
   PHY_mSpeed   : constant STM32F4.Bits_3  := STM32F4.o7xx.Eth.CR_Div102;
   --  PHY mdio clock. 
   --  change this when your board runs at a different HCK from 168MHz
   
end Finrod.Board;
