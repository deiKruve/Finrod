
with STM32F4; --.O7xx.Registers;

package Sermon is
   
   Message_Length : constant Positive := 64;
   -- dma buffersize for uart 3.
   type Uart_Data_Type is private;
   type Uart_Data_Access_Type is access Uart_Data_Type;
   Serial_Recd_Data_A : Uart_Data_Access_Type;
   -- access to dma buffer
   
   --procedure Clear_DMA_Data;

   --function Get_DMA_Word (Index : Positive) return STM32F4.Word;
   
   procedure Init_USART3;
   -- initializes uart3
   
   
   -----------------------
   -- polling functions --
   -----------------------
   
   function Receiver_Is_Full return Boolean;
   -- is the receiver full?
   
   function Transmitter_Is_Empty return Boolean;
   -- is the transmitter done?
   
   function Uart_Error return Boolean;
   -- did a uart error occur?
   
   function Dma1_Error return Boolean;
   -- did a dma error occur?
   
   
   procedure Send_String (S : String);
   -- sends a string record of 64 bytes out on uart3 
   -- string must be < 64 characters, a lf will be added
   -- unused positions will be character'val (0);
   
private
   type Uart_Data_Type is new String (1 .. Message_Length);
   Serial_Recd_Data : Uart_Data_Type;
end Sermon;
