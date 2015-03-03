
with System;
with Ada.Unchecked_Conversion;
with STM32F4.O7xx.Registers;
with STM32F4.O7xx.Syscfg;
with Stm32f4.O7xx.Eth;

package body Ethmon is
   
   package Stm  renames STM32F4;
   package R    renames STM32F4.O7xx.Registers;
   package Scfg renames STM32F4.O7xx.Syscfg;
   package Eth  renames Stm32f4.O7xx.Eth;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   
   ---------------
   -- utilities --
   ---------------
   
   function To_Bits_32 is new
     Ada.Unchecked_Conversion (Source => System.Address,
			       Target => Stm.Bits_32);
   
   
   -----------------------
   -- polling functions --
   -----------------------
   
   
   --------------------------------
   -- initialize the ethenet mac --
   --------------------------------
   procedure Init_Eth
   is
      Scfg_Pmc_Tmp : Scfg.PMC_Register := R.Syscfg.Pmc;
   begin
      -- set mode RMII
      Scfg_Pmc_Tmp.MII_RMII_SEL := Scfg.RMII;
      R.Syscfg.Pmc              := Scfg_Pmc_Tmp;
      
      
      null;
   end Init_Eth;

   
end Ethmon;
