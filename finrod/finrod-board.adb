------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                          F I N R O D . B O A R D                         --
--                                                                          --
--                                 B o d y                                  --
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

with Ada.Unchecked_Conversion;

with STM32F4.O7xx.Syscfg;
with STM32F4.O7xx.Registers;
with STM32F4.O7xx.Rcc;
with STM32F4.Gpio;

with Finrod.Sermon;
with Finrod.Net.Eth;

package body Finrod.Board is
   
   package Stm  renames STM32F4;
   package Gpio renames STM32F4.Gpio;
   package R    renames STM32F4.O7xx.Registers;
   package Rcc  renames STM32F4.O7xx.Rcc;
   package Scfg renames STM32F4.O7xx.Syscfg;
  
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   My_Id : Board_Id;
   
   
  -- inits the pins and then calls any other init functions --
  -- that might be needed                                   --
  --  procedure Init_Pins_Olimex 
  --  is
  --     Ahb1en_Tmp   : Rcc.AHB1EN_Register := R.Rcc.AHB1ENR;
  --     Apb1en_Tmp   : Rcc.APB1EN_Register := R.Rcc.APB1ENR;
  --     dModer_Tmp   : Stm.Bits_16x2       := R.GPIOD.MODER;
  --     dOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOD.Ospeedr;
  --     dOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOD.Otyper;
  --     dPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOD.Pupdr;
  --     dAfrh_Tmp    : Gpio.Afrh_Register  := R.GPIOD.Afrh;
  --  begin
  --     -- start some clocks.
  --     Ahb1en_Tmp.Gpiod     := Rcc.Enable;  -- for uart3 pins
  --     Ahb1en_Tmp.Dma1      := Rcc.Enable;  -- for uart3 dma
  --     R.Rcc.AHB1ENR        := Ahb1en_Tmp;
     
  --     -- enable uart3
  --     Apb1en_Tmp.Uart3     := Rcc.Enable;
  --     R.Rcc.APB1ENR        := Apb1en_Tmp;
     
  --     -- set up uart3 pins to gpio.port D pins 8 and 9.
  --     dModer_Tmp (8 .. 9)   := (others => Gpio.Alt_Func);
  --     R.GPIOD.MODER         := dModer_Tmp;
  --     dOspeedr_Tmp (8 .. 9) := (others => Gpio.Speed_50MHz);
  --     R.GPIOD.Ospeedr       := dOspeedr_Tmp;
  --     dOtyper_Tmp (8 .. 9)  := (others => Gpio.Push_Pull);
  --     R.GPIOD.Otyper        := dOtyper_Tmp;
  --     dPupdr_Tmp (8 .. 9)   := (others => Gpio.Pull_Up);
  --     R.GPIOD.Pupdr         := dPupdr_Tmp;
  --     dAfrh_Tmp (8 .. 9)    := (others => Gpio.Af7);
  --     R.GPIOD.Afrh          := dAfrh_Tmp;
     
  --     -- init the usart and its dma:
  --     --Sermon.Init_Usart3;--------------------------------------------
  --  end Init_Pins_Olimex;
  --   pragma Unreferenced (Init_Pins_Olimex);
  
  -- inits the pins and then calls any other init functions --
  -- that might be needed                                   --
  procedure Init_Pins
  is
     PMC_Tmp      : Scfg.PMC_Register   := R.Syscfg.PMC;
     Ahb1en_Tmp   : Rcc.AHB1EN_Register := R.Rcc.AHB1ENR;
     Apb2en_Tmp   : Rcc.APB2EN_Register := R.Rcc.APB2ENR;
     
     aModer_tmp   : Stm.Bits_16x2       := R.GPIOa.Moder;
     aOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOa.Ospeedr;
     aOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOa.Otyper;
     aPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOa.Pupdr;
     aAfrl_Tmp    : Gpio.Afrl_Register  := R.GPIOa.Afrl;
     
     cModer_tmp   : Stm.Bits_16x2       := R.GPIOc.Moder;
     cOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOc.Ospeedr;
     cOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOc.Otyper;
     cPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOc.Pupdr;
     cAfrl_Tmp    : Gpio.Afrl_Register  := R.GPIOc.Afrl;
     
     gModer_tmp   : Stm.Bits_16x2       := R.GPIOg.Moder;
     gOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOg.Ospeedr;
     gOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOg.Otyper;
     gPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOg.Pupdr;
     gAfrl_Tmp    : Gpio.Afrl_Register  := R.GPIOg.Afrl;
     
     bModer_Tmp   : Stm.Bits_16x2       := R.GPIOB.MODER;
     bOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOB.Ospeedr;
     bOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOB.Otyper;
     bPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOB.Pupdr;
     bAfrl_Tmp    : Gpio.Afrl_Register  := R.GPIOB.Afrl;
  begin
     -- before all else select the eth media interface
     PMC_Tmp.MII_RMII_SEL := Scfg.RMII;  -- reduced interface on Olimex
     -- write it
     R.Syscfg.PMC         := PMC_Tmp;
     
     -- start some clocks.
     -- uart first
     Ahb1en_Tmp.Gpiob     := Rcc.Enable;  -- for uart1 pins
     Ahb1en_Tmp.Dma2      := Rcc.Enable;  -- for uart1 dma
     
     -- then ethernet
     Ahb1en_Tmp.GPIOA     := Rcc.Enable;  -- for eth_rmii interface pins
     Ahb1en_Tmp.GPIOC     := Rcc.Enable;  -- for eth_rmii interface pins
     Ahb1en_Tmp.GPIOG     := Rcc.Enable;  -- for eth_rmii interface pins
     Ahb1en_Tmp.ETHMAC    := Rcc.Enable;  -- mac clock
     Ahb1en_Tmp.ETHMACRX  := Rcc.Enable;  -- receive clock
     Ahb1en_Tmp.ETHMACTX  := Rcc.Enable;  -- transmit clock
     
     -- and I am sure we need this
     Ahb1en_Tmp.ETHMACPTP := Rcc.Enable;  -- the ptp clock
     
     -- lastly write it
     R.Rcc.AHB1ENR        := Ahb1en_Tmp;
     
     -- enable uart1
     Apb2en_Tmp.Uart1     := Rcc.Enable;
     R.Rcc.APB2ENR        := Apb2en_Tmp;
     
     -- set up eth_rmii interface pins
     Amoder_Tmp (1 ..3, 7) := (others => Gpio.Alt_Func);
     R.Gpioa.Moder         := Amoder_Tmp;
     
     
     aAfrl_Tmp (1 ..3, 7) := (others => Gpio.Af11);
     R.Gpioa.Afrl         := AAfrl_Tmp;
     
     -- set up uart1 pins to gpio.port B pins 6 and 7.
     bModer_Tmp (6 .. 7)   := (others => Gpio.Alt_Func);
     R.GPIOB.MODER         := bModer_Tmp;
     bOspeedr_Tmp (6 .. 7) := (others => Gpio.Speed_50MHz);
     R.GPIOB.Ospeedr       := bOspeedr_Tmp;
     bOtyper_Tmp (6 .. 7)  := (others => Gpio.Push_Pull);
     R.GPIOB.Otyper        := bOtyper_Tmp;
     bPupdr_Tmp (6 .. 7)   := (others => Gpio.Pull_Up);
     R.GPIOB.Pupdr         := bPupdr_Tmp;
     bAfrl_Tmp (6 .. 7)    := (others => Gpio.Af7);
     R.GPIOB.Afrl          := bAfrl_Tmp;
     
     -- init the usart and its dma:
     Finrod.Sermon.Init_Usart1;
     --,init the ethernet with dma and ptp
     Finrod.Net.Eth.Init_Ethernet;
  end Init_Pins;
  
  
  function Get_Id return Board_Id
  is
  begin
     return My_id;
  end Get_Id;
  
  
  function Get_Mac_Address return Mac_Address
  is
  begin
     return My_Mac_Address;
  end Get_Mac_Address;
  
  
  function Get_Ip_Address return Ip_Address
  is
  begin
     return My_Ip_Address;
  end Get_Ip_Address;
  
  
  function Get_Master_Ip_Address return Ip_Address
  is
  begin
     return Master_Ip_Address;
  end Get_Master_Ip_Address;
  
  
  procedure Set_Id (Id : Board_Id)
  is
     use type Stm.Bits_16;
     use type Stm.Bits_32;
     use type Stm.Bits_48;
     Tid : constant Stm.Bits_16 := Stm.Bits_16 (Id) * 16#100#;
  begin
     My_Id := Id;
     My_Mac_Address := 
       (My_Mac_Address and 16#ff_ff_ff_ff_00_ff#) or Stm.Bits_48 (Tid);
     My_Ip_Address  := 
       (My_Ip_Address and 16#ff_ff_00_ff#) or Stm.Bits_32 (Tid);
  end Set_Id;
  
  
  procedure Set_Mac_Address (M : Mac_Address)
  is
  begin
     My_Mac_Address := M;
  end Set_Mac_Address;
  
  
  procedure Set_Ip_Address (Ip : Ip_Address)
  is
  begin
     My_Ip_Address := Ip;
  end Set_Ip_Address;
  
  
  procedure Set_Master_Ip_Address (Ip : Ip_Address)
  is
  begin
     Master_Ip_Address := Ip;
  end Set_Master_Ip_Address;
  
  
end Finrod.Board;
