
with System;
with Ada.Unchecked_Conversion;

with STM32F4.O7xx.Registers;
with STM32F4.o7xx.Usart;
with STM32F4.Gpio;

package body Sermon is
   package Arm  renames STM32F4;
   package R    renames STM32F4.O7xx.Registers;
   package Uart renames STM32F4.o7xx.Usart;
   
   pragma Warnings (Off, "*may call Last_Chance_Handler");
   pragma Warnings (Off, "*(No_Exception_Propagation) in effect");
   pragma Warnings (Off,
                    "*types for unchecked conversion have different sizes");
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   -- APB1_Clock (which USART 2,3,4,5,7,8 are on) is 42 MHz
   APB1_Clock           : constant Long_Float := 42_000_000.0;
   USART3_Baudrate      : constant Long_Float := 115200.0;
   
   -- calculate baudrate contants for over_8 = 0
   USART3_D             : constant Long_Float := 
     APB1_Clock / (16.0 * USART3_Baudrate);
   USART3_Div_Mantissa  : constant Arm.Bits_12 := 
     Arm.Bits_12 (Long_Float'Truncation (USART3_D));
   USART3_Div_Fraction  : constant Arm.Bits_4  := 
     Arm.Bits_4 (Long_Float'Rounding 
		((USART3_D - Long_Float (USART3_Div_Mantissa)) * 16.0));
   
   -- to hold raw DMA USART data
   type Word_Buffer_Type is array (1 .. Buf_Size) of Arm.Word;
   DMA_Data     : Word_Buffer_Type           := (others => 0);

   
   
   ---------------
   -- utilities --
   ---------------
   
   function Word_To_Char is
      new Ada.Unchecked_Conversion 
     (Source => Arm.Word, Target => Character);

   function Char_To_Word is
      new Ada.Unchecked_Conversion 
     (Source => Character, Target => Arm.Word);

   function Addr_To_Word is
      new Ada.Unchecked_Conversion 
     (Source => System.Address, Target => Arm.Word);
   
   
   ---------------------
   -- Clear_DMA_Data  --
   ---------------------
   
   procedure Clear_DMA_Data is
   begin
      DMA_Data := (others => 0);
   end Clear_DMA_Data;
   
   
   ------------------
   -- Get_DMA_Word --
   ------------------
   
   function Get_DMA_Word (Index : Positive) return Arm.Word 
   is
   begin
      if Index <= Buf_Size then
         return DMA_Data (Index);
      else
         return DMA_Data (1); -- only if bad index is passed in
      end if;
   end Get_DMA_Word;
   
   
   -----------------
   -- Init_USART3 --
   -----------------
   
   
   procedure Init_USART3 
   is
      Brr_Tmp : Uart.BRR_Register;
      Cr1_Tmp : Uart.Cr1_Register := R.Usart3.Cr1; -- hopefully all 0
   begin
      Brr_Tmp.DIV_Mantissa := USART3_Div_Mantissa; -- baudrate register
      Brr_Tmp.DIV_Fraction := USART3_Div_Fraction;
      R.Usart3.Brr         := Brr_Tmp;
      
      Cr1_Tmp.Ue   := Uart.Enable; -- uart enable
      Cr1_Tmp.Te   := Uart.Enable; -- xmitter enable
      Cr1_Tmp.Re   := Uart.Enable; -- receiver enable.
      -- and 1 Start bit, 8 Data bits, n Stop bit, no parity
      -- no interrupts
      R.Usart3.Cr1 := Cr1_Tmp;
      
	
   end Init_USART3;
   
   
      -----------------
      -- test        --
      -----------------
      procedure Test
      is
	 use type STM32F4.Word;
	 type Bits_32x1 is array (0 .. 31) of STM32F4.Bits_1 with Pack, Size => 32;
	 Arr : Bits_32x1 := (others => 0);
	 function To_Bits is new 
	   Ada.Unchecked_Conversion (Source => STM32F4.Word,
				     Target => Bits_32x1);
	 function To_Word is new
	   Ada.Unchecked_Conversion (Source => Bits_32x1,
				     Target => STM32F4.Word);
      begin
	 Arr (1 .. 2) := (1,0);--(1 => 1, 2 => 0);
	 
	  Arr := To_Bits(To_Word (Arr) or 8);
	 null;
      end Test;
      
   
   
   
   
end Sermon;

   
   
