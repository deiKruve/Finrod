
with STM32F4; --.O7xx.Registers;

package Sermon is
   
   Buf_Size      : constant Integer  := 40;
   -- dma buffersize for uart 3.
   
   procedure Clear_DMA_Data;

   function Get_DMA_Word (Index : Positive) return STM32F4.Word;
   
   procedure Init_USART3;
   -- initializes uart3
   
   procedure Send_String (S : String);
   -- sends a string record of 64 bytes out on uart3 
   -- string must be < 64 characters, a lf will be added
   -- unused positions will be character'val (0);
   
   
end Sermon;
