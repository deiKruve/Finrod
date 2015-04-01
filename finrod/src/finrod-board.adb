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

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

with Ada.Unchecked_Conversion;

with STM32F4.O7xx.Registers;
with STM32F4.O7xx.Rcc;
with STM32F4.Gpio;

package body Finrod.Board is
   
   package Stm  renames STM32F4;
   package Gpio renames STM32F4.Gpio;
   package R    renames STM32F4.O7xx.Registers;
   package Rcc  renames STM32F4.O7xx.Rcc;
  
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
   
   
       
   --  RCC enable registers for some blocks
   --  ethernet is not in this routine, it needs to be started later
   procedure Init_Clocks
     is
      Ahb1en_Tmp   : Rcc.AHB1EN_Register  := R.Rcc.AHB1ENR;
      Apb2en_Tmp   : Rcc.APB2EN_Register  := R.Rcc.APB2ENR;
   begin
      -- start the syscfg block
      Apb2en_Tmp.Syscfg    := Rcc.Enable;
      R.Rcc.APB2ENR        := Apb2en_Tmp;
      
      -- start uart
      Ahb1en_Tmp.Gpiob     := Rcc.Enable;  -- for uart1 pins
      Ahb1en_Tmp.Dma2      := Rcc.Enable;  -- for uart1 dma
      
      -- then ethernet pins
      Ahb1en_Tmp.GPIOA     := Rcc.Enable;  -- for eth_rmii interface pins
      Ahb1en_Tmp.GPIOB     := Rcc.Enable;  -- 
      Ahb1en_Tmp.GPIOC     := Rcc.Enable;  -- for eth_rmii interface pins
      Ahb1en_Tmp.GPIOG     := Rcc.Enable;  -- for eth_rmii interface pins
      R.Rcc.AHB1ENR        := Ahb1en_Tmp;
   end Init_Clocks;
  

  -- inits the pins and then calls any other init functions --
  -- that might be needed                                   --
   procedure Init_Pins
   is
   begin
      --  RCC reset registers
      declare
         RCC_CR_Tmp   : Rcc.CR_Register      := R.Rcc.Cr;         -- test
         pragma unreferenced (RCC_CR_Tmp);
         PLLCFGR_Tmp  : Rcc.PLLCFG_Register  := R.Rcc.PLLCFGR;    -- test
         pragma unreferenced (PLLCFGR_Tmp);
	 Ahb1rst_Tmp  : Rcc.AHB1RST_Register := R.Rcc.AHB1RSTR;
	 --Apb1rst_Tmp  : Rcc.APB1RST_Register := R.Rcc.APB1RSTR;
	 Apb2rst_Tmp  : Rcc.APB2RST_Register := R.Rcc.APB2RSTR;
      begin
	 --Ahb1rst_Tmp.ETHMAC   := Rcc.Off; -- pulse it, according to cube
	 Ahb1rst_Tmp.DMA1     := Rcc.Off;
	 Ahb1rst_Tmp.DMA2     := Rcc.Off;
	 Ahb1rst_Tmp.GPIOA    := Rcc.Off;
	 Ahb1rst_Tmp.GPIOB    := Rcc.Off;
	 Ahb1rst_Tmp.GPIOC    := Rcc.Off;
	 Ahb1rst_Tmp.GPIOG    := Rcc.Off;
	 R.Rcc.AHB1RSTR       := Ahb1rst_Tmp;
	 Apb2rst_Tmp.Uart1    := Rcc.Off;
	 Apb2rst_Tmp.Uart6    := Rcc.Off;
	 R.Rcc.APB2RSTR       := Apb2rst_Tmp;
	 
	 --Ahb1rst_Tmp.ETHMAC   := Rcc.Reset;
	 Ahb1rst_Tmp.DMA1     := Rcc.Reset;
	 Ahb1rst_Tmp.DMA2     := Rcc.Reset;
	 Ahb1rst_Tmp.GPIOA    := Rcc.Reset;
	 Ahb1rst_Tmp.GPIOB    := Rcc.Reset;
	 Ahb1rst_Tmp.GPIOC    := Rcc.Reset;
	 Ahb1rst_Tmp.GPIOG    := Rcc.Reset;
	 --Apb1rst_Tmp.
	 Apb2rst_Tmp.Uart1    := Rcc.Reset; -- reset the discovery channel if needed
	 Apb2rst_Tmp.Uart6    := Rcc.Reset;
	 -- write to hardware
	 R.Rcc.AHB1RSTR       := Ahb1rst_Tmp;
	 --R.Rcc.APB1RST        := APB1RST_Tmp;
	 R.Rcc.APB2RSTR       := Apb2rst_Tmp;
	 
	 Ahb1rst_Tmp.ETHMAC   := Rcc.Off; -- pulse it, according to cube
	 Ahb1rst_Tmp.DMA1     := Rcc.Off;
	 Ahb1rst_Tmp.DMA2     := Rcc.Off;
	 Ahb1rst_Tmp.GPIOA    := Rcc.Off;
	 Ahb1rst_Tmp.GPIOB    := Rcc.Off;
	 Ahb1rst_Tmp.GPIOC    := Rcc.Off;
	 Ahb1rst_Tmp.GPIOG    := Rcc.Off;
	 R.Rcc.AHB1RSTR       := Ahb1rst_Tmp;
	 Apb2rst_Tmp.Uart1    := Rcc.Off;
	 Apb2rst_Tmp.Uart6    := Rcc.Off;
	 R.Rcc.APB2RSTR       := Apb2rst_Tmp;
      end;
      
      
      --  GPIOA registers
      declare
	 aModer_tmp   : Stm.Bits_16x2       := R.GPIOa.Moder;
	 aOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOa.Ospeedr;
	 aOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOa.Otyper;
	 aPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOa.Pupdr;
	 aAfrl_Tmp    : Gpio.Afrl_Register  := R.GPIOa.Afrl;
      begin
	 --  do not use
	 --  PA0 is wake-up button
	 --  PA8 is on USB power signal
	 --  PA9, 10, 11, 12 are on USB_OTG1 (could perhaps be used)
	 --  PA13, 14, 15 are on jtag
	 ------------------------------------
	 -- set up eth_rmii interface pins
	 --
	 -- PA1  -- REF_CLK, 50 MHz Reference Clock, in
	 -- PA2  -- MDIO Management data I/O line
	 -- PA3  -- interrupt from PHY, not part of the rmii, in
	 -- PA7  -- Carrier Sense (CRS)/RX_Data Valid(RX_DV), in
	 Amoder_Tmp (1 ..2)    := (others => Gpio.Alt_Func);
	 Amoder_Tmp (7)        := Gpio.Alt_Func;
	 aOspeedr_Tmp (2)      := Gpio.Speed_50MHz;
	 aPupdr_Tmp (1)        := Gpio.Pull_Up;
	 aOtyper_Tmp (2)       := Gpio.Push_Pull;
	 aAfrl_Tmp (1 ..2)     := (others => Gpio.Af11);
	 aAfrl_Tmp (7)         := Gpio.Af11;
	 -- write to hardware
	 R.Gpioa.Moder         := Amoder_Tmp;
	 R.Gpioa.Ospeedr       := AOspeedr_Tmp;
	 R.Gpioa.Pupdr         := APupdr_Tmp;
	 R.Gpioa.Otyper        := AOtyper_Tmp;
	 R.Gpioa.Afrl          := AAfrl_Tmp;
      end;
      
      --  GPIOB registers
      --  declare
      --  	 bModer_Tmp   : Stm.Bits_16x2       := R.GPIOB.MODER;
      --  	 bOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOB.Ospeedr;
      --  	 bOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOB.Otyper;
      --  	 bPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOB.Pupdr;
      --  	 bAfrl_Tmp    : Gpio.Afrl_Register  := R.GPIOB.Afrl;
      --  begin
      --  	 --  do not use
      --  	 --  PB0, 1 are on USB power signal
      --  	 --  PB2 is the boot1 jumper
      --  	 --  PB3, 4 are on jtag
      --  	 --  PB8, 9 are on UEXT
      --  	 --  PB10, 11 are on the boot socket (could perhaps be used)
      --  	 --  PB12, 13, 14, 15 are on USB_OTG2 (could perhaps be used)
      --  	 ---------------------------------------
      --  	 -- set up uart1 pins to gpio.port B pins 6 and 7.
      --  	 bModer_Tmp (6 .. 7)   := (others => Gpio.Alt_Func);
      --  	 bOspeedr_Tmp (6 .. 7) := (others => Gpio.Speed_50MHz);
      --  	 bOtyper_Tmp (6 .. 7)  := (others => Gpio.Push_Pull);
      --  	 bPupdr_Tmp (6 .. 7)   := (others => Gpio.Pull_Up);
      --  	 bAfrl_Tmp (6 .. 7)    := (others => Gpio.Af7);
      --  	 -- write to hardware
      --  	 R.GPIOB.MODER         := bModer_Tmp;
      --  	 R.GPIOB.Ospeedr       := bOspeedr_Tmp;
      --  	 R.GPIOB.Otyper        := bOtyper_Tmp;
      --  	 R.GPIOB.Pupdr         := bPupdr_Tmp;
      --  	 R.GPIOB.Afrl          := bAfrl_Tmp;
      --  end;
      
      --  GPIOC registers
      declare
	 cModer_tmp   : Stm.Bits_16x2       := R.GPIOc.Moder;
	 cOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOc.Ospeedr;
	 cOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOc.Otyper;
	 cPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOc.Pupdr;
	 cAfrl_Tmp    : Gpio.Afrl_Register  := R.GPIOc.Afrl;  
      begin
	 --  do not use
	 --  PC2, 3, 6, 7 are on UEXT
	 --  PC8, 9, 10, 11, 12 are on SD card
	 --  PC13 is an LED
	 --  PC14, 15 are clock crystal
	 ----------------------------------------
	 -- set up eth_rmii interface pins
	 --
	 -- PC1  -- MDC Management data clock line, out
	 -- PC4  -- RXD0 Receive data bit 0, in
	 -- PC5  -- RXD1 Receive data bit 1, 1
	 CModer_Tmp (1)        := Gpio.Alt_Func;
	 CModer_Tmp (4 .. 5)   := (others => Gpio.Alt_Func);
	 cOspeedr_Tmp (1)      := Gpio.Speed_50MHz;
	 cOtyper_Tmp (1)       := Gpio.Push_Pull;
	 cPupdr_Tmp (4 .. 5)   := (others => Gpio.Pull_Up);
	 cAfrl_Tmp (1)         := Gpio.Af11;
	 cAfrl_Tmp (4 .. 5)    := (others => Gpio.Af11);
	 ---------------------------------------
	 -- set up uart6 pins to gpio.port C pins 6 and 7.
	 --
	 --  PC6 is TX
	 --  PC7 is RX
	 cModer_Tmp (6 .. 7)   := (others => Gpio.Alt_Func);
      	 cOspeedr_Tmp (6 .. 7) := (others => Gpio.Speed_50MHz);
      	 cOtyper_Tmp (6 .. 7)  := (others => Gpio.Push_Pull);
      	 cPupdr_Tmp (6 .. 7)   := (others => Gpio.Pull_Up);
      	 cAfrl_Tmp (6 .. 7)    := (others => Gpio.Af8);
	 ----------------------------------------------
	 -- set up the LED on PC13
	 cModer_Tmp (13)       := Gpio.Output;
	 cOspeedr_Tmp (13)     := Gpio.Speed_2MHz;
	 cOtyper_Tmp (13)      := Gpio.Open_Drain;
	 cPupdr_Tmp (13)       := Gpio.Pull_Up;
	 ----------------------------------------------
	 -- write to hardware
	 R.GPIOc.Moder         := CModer_Tmp;  
	 R.GPIOc.Ospeedr       := COspeedr_Tmp;
	 R.GPIOc.Otyper        := COtyper_Tmp; 
	 R.GPIOc.Pupdr         := CPupdr_Tmp;   
	 R.GPIOc.Afrl          := CAfrl_Tmp;     
      end;
      
      --  GPIOD registers
      --  do not use
      --  PD2 is on SD card
      
      --  GPIOE registers
      
      --  GPIOF registers
      --  do not use
      --  PF11 is on USB power signal
      
      --  GPIOG registers
      declare
	 gModer_tmp   : Stm.Bits_16x2       := R.GPIOg.Moder;
	 gOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOg.Ospeedr;
	 gOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOg.Otyper;
	 gPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOg.Pupdr;
	 --gAfrl_Tmp    : Gpio.Afrl_Register  := R.GPIOg.Afrl;  
	 gAfrh_Tmp    : Gpio.Afrh_Register  := R.GPIOg.Afrh;  
      begin
	 --  do not use
	 --  PG10 is on UEXT
	 ----------------------------------------
	 -- set up eth_rmii interface pins
	 --
	 -- PG6   -- RST, not part of rmii, out
	 -- PG11  -- TX_EN When high, clock data on TXD0 and TXD1 to the transmitter 
	 -- PG13  -- TXD0 Transmit data bit 0
	 -- PG14  -- TXD1 Transmit data bit 1
	 GModer_Tmp (6)        := Gpio.Output;
	 GModer_Tmp (11)       := Gpio.Alt_Func;
	 GModer_Tmp (13 .. 14) := (others => Gpio.Alt_Func);
	 GOspeedr_Tmp (6)      := Gpio.Speed_25MHz;
	 GOspeedr_Tmp (11)     := Gpio.Speed_100MHz;
	 GOspeedr_Tmp (13 .. 14) := (others => Gpio.Speed_100MHz);
	 GOtyper_Tmp (6)       := Gpio.Push_Pull;
	 GOtyper_Tmp (11)      := Gpio.Push_Pull;
	 GOtyper_Tmp (13 .. 14) := (others => Gpio.Push_Pull);
	 GPupdr_Tmp (6)        := Gpio.Pull_Down;
	 GPupdr_Tmp (11)       := Gpio.Pull_Down;
	 GPupdr_Tmp (13 .. 14) := (others => Gpio.Pull_Down);
	 GAfrh_Tmp (11)        := Gpio.Af11;
	 GAfrh_Tmp (13 .. 14)  := (others => Gpio.Af11);
	 -- write to hardware
	 R.GPIOg.Moder         := GModer_Tmp;
	 R.GPIOg.Ospeedr       := GOspeedr_Tmp;
	 R.GPIOg.Otyper        := GOtyper_Tmp; 
	 R.GPIOg.Pupdr         := GPupdr_Tmp;  
	 --R.GPIOg.Afrl          := GAfrl_Tmp;
	 R.GPIOg.Afrh          := GAfrh_Tmp;
      end;
      
      --  RCC enable registers for the auxiliaries
      declare
	 Ahb1en_Tmp   : Rcc.AHB1EN_Register  := R.Rcc.AHB1ENR;
	 Apb2en_Tmp   : Rcc.APB2EN_Register  := R.Rcc.APB2ENR;
      begin
	 --Ahb1en_Tmp.ETHMAC    := Rcc.Enable;  -- mac clock
	 --Ahb1en_Tmp.ETHMACRX  := Rcc.Enable;  -- receive clock
	 --Ahb1en_Tmp.ETHMACTX  := Rcc.Enable;  -- transmit clock
	 -- and I am sure we need this
	 Ahb1en_Tmp.ETHMACPTP := Rcc.Enable;  -- the ptp clock
	 -- enable uart1 -- this is the discovery animal we use uart6
	 -- Apb2en_Tmp.Uart1     := Rcc.Enable;
	 Apb2en_Tmp.Uart6     := Rcc.Enable;
	 -- write to hardware
	 R.Rcc.AHB1ENR        := Ahb1en_Tmp;
	 R.Rcc.APB2ENR        := Apb2en_Tmp;
      end;
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
  
  function Get_Bcast_Address return Mac_Address
  is
  begin
     return Broadcast_Mac_Address;
  end Get_Bcast_Address;
     
  function Get_PHY_Address return Stm32F4.Bits_5
  is
  begin
     return PHY_Address;
  end Get_PHY_Address;
  
  function Get_PHY_Mspeed return Stm.Bits_3
  is
  begin
     return PHY_MSpeed;
  end Get_PHY_Mspeed;
     
  
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
