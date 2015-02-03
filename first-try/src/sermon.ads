
with STM32F4.O7xx.Registers;

package Sermon is
   
   Buf_Size      : constant Integer  := 40;
   -- dma buffersize for uart 3.
   
   procedure Clear_DMA_Data;

   function Get_DMA_Word (Index : Positive) return STM32F4.Word;
   
   
end Sermon;
