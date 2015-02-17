
with STM32F4;

package Finrod.Sermon is
   
   ------------------------------------------
   -- Incoming Message Interface structure --
   -- rebase it after processing a message --
   -- or after an error                    --
   -- (but this should not be needed)      --
   ------------------------------------------
   
   Message_Length : constant Positive := 64;
   -- incoming message size for uart 3.

   type Uart_Data_Type is new String (1 .. Message_Length);
   subtype Srd_Index_Type is Integer range 1 .. Message_Length;
   type Uart_Data_Access_Type is access all Uart_Data_Type;
   
   Serial_Recd_Data_A : Uart_Data_Access_Type;
   -- incoming message buffer access
   
   Srd_Index            : Srd_Index_Type := 1; 
   -- Last Written Char + 1.
   
   Srd_Terminator_Index : Srd_Index_Type := 1; 
   -- Last terminator Char + 1.
   
   Srd_Terminator       : constant Character := ASCII.CR;
   -- terminating character of a incoming message
   
   
   -----------------
   -- error flags --
   -----------------
   
   Receiver_Error : Boolean := False;
   -- set to true by client or locally on invalid Serial_Recd_Data
   -- reset internally on reception of the next Srd_Terminator
   -- so any info before the next terminator will be lost.
   
   
   ---------------------------
   -- initialize the sermon --
   ---------------------------
   
   procedure Init_USART1;
   -- initializes uart1 and its dma structure
   -- both for sending and receiving.
   -- Baudrate 115200.
   -- 8 databits, no parity, 2 stopbits, full duplex
   
   
   -----------------------
   -- polling functions --
   -----------------------
   
   function Receiver_Is_Full return Boolean with Inline;
   -- is the receiver full?
   
   function Transmitter_Is_Empty return Boolean with Inline;
   -- is the transmitter done?
   
   function Uart_Error return Boolean with Inline;
   -- did a uart error occur?
   -- no internal action is taken
   
   function Dma2_Error return Boolean with Inline;
   -- did a dma error occur?
   -- no internal action is taken
   
   
   procedure Send_String (S : String);
   -- sends a string record < 64 bytes out on uart3 
   -- string must be < 64 characters, a lf will be added
   -- at the end.
   
private
   Serial_Recd_Data : aliased Uart_Data_Type;
end Finrod.Sermon;
