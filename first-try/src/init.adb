
with Ada.Unchecked_Conversion;

with STM32F4.O7xx.Registers;
with STM32F4.O7xx.Rcc;
with STM32F4.Gpio;

with Sermon;

package body Init is
   
  package Stm  renames STM32F4;
  package Gpio renames STM32F4.Gpio;
  package R    renames STM32F4.O7xx.Registers;
  package Rcc  renames STM32F4.O7xx.Rcc;
  
  
  -- inits the pins and then calls any other init functions --
  -- that might be needed                                   --
  procedure Init_Pins
  is
     Ahb1en_Tmp   : Rcc.AHB1EN_Register := R.Rcc.AHB1ENR;
     Apb1en_Tmp   : Rcc.APB1EN_Register := R.Rcc.APB1ENR;
     dModer_Tmp   : Stm.Bits_16x2       := R.GPIOD.MODER;
     dOspeedr_Tmp : Stm.Bits_16x2       := R.GPIOD.Ospeedr;
     dOtyper_Tmp  : Stm.Bits_16x1       := R.GPIOD.Otyper;
     dPupdr_Tmp   : Stm.Bits_16x2       := R.GPIOD.Pupdr;
     dAfrh_Tmp    : Gpio.Afrh_Register  := R.GPIOD.Afrh;
  begin
     -- start some clocks.
     Ahb1en_Tmp.Gpiod     := Rcc.Enable;  -- for uart3 pins
     Ahb1en_Tmp.Dma1      := Rcc.Enable;  -- for uart3 dma
     R.Rcc.AHB1ENR        := Ahb1en_Tmp;
     
     -- enable uart3
     Apb1en_Tmp.Uart3     := Rcc.Enable;
     R.Rcc.APB1ENR        := Apb1en_Tmp;
     
     -- set up uart3 pins to gpio.port D pins 8 and 9.
     dModer_Tmp (8 .. 9)   := (others => Gpio.Alt_Func);
     R.GPIOD.MODER         := dModer_Tmp;
     dOspeedr_Tmp (8 .. 9) := (others => Gpio.Speed_50MHz);
     R.GPIOD.Ospeedr       := dOspeedr_Tmp;
     dOtyper_Tmp (8 .. 9)  := (others => Gpio.Push_Pull);
     R.GPIOD.Otyper        := dOtyper_Tmp;
     dPupdr_Tmp (8 .. 9)   := (others => Gpio.Pull_Up);
     R.GPIOD.Pupdr         := dPupdr_Tmp;
     dAfrh_Tmp (8 .. 9)    := (others => Gpio.Af7);
     R.GPIOD.Afrh          := dAfrh_Tmp;
     
     -- init the usart and its dma:
     Sermon.Init_Usart3;
  end Init_Pins;
  
  
end Init;
