-- with System;
with Ada.Unchecked_Conversion;

with STM32F4.O7xx.Registers;
with STM32F4.O7xx.Rcc;
with STM32F4.Gpio;

package body Init is
  -- inits the pins and then calls any other init functions 
  -- that might be needed
  package Stm  renames STM32F4;
  package Gpio renames STM32F4.Gpio;
  package R    renames STM32F4.O7xx.Registers;
  package Rcc  renames STM32F4.O7xx.Rcc;
  
  
  procedure Init_Pins
  is
     Ahb1en_Tmp  : Rcc.AHB1EN_Register := R.Rcc.AHB1ENR;
     Apb1en_Tmp  : Rcc.APB1EN_Register := R.Rcc.APB1ENR;
     Moder_Tmp   : Stm.Bits_16x2       := R.GPIOD.MODER;
     Ospeedr_Tmp : Stm.Bits_16x2       := R.GPIOD.Ospeedr;
     Otyper_Tmp  : Stm.Bits_16x1       := R.GPIOD.Otyper;
     Pupdr_Tmp   : Stm.Bits_16x2       := R.GPIOD.Pupdr;
     Afrh_Tmp    : Gpio.Afrh_Register  := R.GPIOD.Afrh;
  begin
     -- start some clocks.
     Ahb1en_Tmp.Gpiod     := Rcc.Enable;  -- for uart3 pins
     Ahb1en_Tmp.Dma1      := Rcc.Enable;  -- for uart3 dma
     R.Rcc.AHB1ENR        := Ahb1en_Tmp;
     -- enable uart3
     Apb1en_Tmp.Uart3     := Rcc.Enable;
     R.Rcc.APB1ENR        := Apb1en_Tmp;
     -- set up uart3 pins to gpio.port D pins 8 and 9.
     Moder_Tmp (8 .. 9)   := (others => Gpio.Alt_Func);
     R.GPIOD.MODER        := Moder_Tmp;
     Ospeedr_Tmp (8 .. 9) := (others => Gpio.Speed_50MHz);
     R.GPIOD.Ospeedr      := Ospeedr_Tmp;
     Otyper_Tmp (8 .. 9)  := (others => Gpio.Push_Pull);
     R.GPIOD.Otyper       := Otyper_Tmp;
     Pupdr_Tmp (8 .. 9)   := (others => Gpio.Pull_Up);
     R.GPIOD.Pupdr        := Pupdr_Tmp;
     Afrh_Tmp (8 .. 9)    := (others => Gpio.Af7);
     R.GPIOD.Afrh         := Afrh_Tmp;
     
  end Init_Pins;
  
  
end Init;
