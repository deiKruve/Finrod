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

with STM32F4;

package Finrod.Board is
   
   subtype Board_Id is Natural;
   subtype Mac_Address is STM32F4.Bits_48;
   subtype Ip_Address  is STM32F4.Bits_32;
   
   procedure Init_Pins;
   -- inits the basic board with serial and eth comms and id pins
   -- it will call any other  resource init functions 
   -- that might be needed
   
   function Get_Id return Board_Id;
   -- returns the board id
   -- this is supposed to guide the software into executing the 
   -- right subset of functions.
   
   function Get_Mac_Address return Mac_Address;
   -- returns the mac address. This is the systems basic Mac address with 
   -- the address set on hardware switches as the last group
   
   function Get_Ip_Address return Ip_Address;
   -- returns the ip address. this is the systems basic IP address with
   -- the address set on hardware switches as the last group
   
end Finrod.Board;
