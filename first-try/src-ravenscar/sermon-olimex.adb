
with System;
with Ada.Unchecked_Conversion;
with STM32F4.O7xx.Registers;
with STM32F4.o7xx.Dma;
with STM32F4.o7xx.Usart;

package body Sermon is
   package Stm  renames STM32F4;
   package R    renames STM32F4.O7xx.Registers;
   package Uart renames STM32F4.o7xx.Usart;
   package Dma  renames STM32F4.o7xx.Dma;
   
   pragma Warnings (Off, "*may call Last_Chance_Handler");
   pragma Warnings (Off, "*(No_Exception_Propagation) in effect");
   --  pragma Warnings (Off,
   --                   "*types for unchecked conversion have different sizes");
   
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
   USART3_Div_Mantissa  : constant Stm.Bits_12 := 
     Stm.Bits_12 (Long_Float'Truncation (USART3_D));
   USART3_Div_Fraction  : constant Stm.Bits_4  := 
     Stm.Bits_4 (Long_Float'Rounding 
		((USART3_D - Long_Float (USART3_Div_Mantissa)) * 16.0));
   
   -- this register must be global 
   S3_Cr_Tmp : Dma.CR_Register;
   
   -- the data to be send is copied into this string
   Uart_Data_Tobe_Send : aliased String (1 .. 68);
   
   -- received data buffer structure --
   Srr_Buf_Size : constant := 256;
   Serial_Recd_Ring_Buffer : String (1 .. Srr_Buf_Size);
   subtype Srr_Buf_P_Type is Integer range 0 .. Srr_Buf_Size;
   Srr_Buf_Lastread  : Srr_Buf_P_Type := 0;
   Srr_Buf_Newest    : Srr_Buf_P_Type := 0;
   

   
   
   ---------------
   -- utilities --
   ---------------
   
   --  function Word_To_Char is
   --     new Ada.Unchecked_Conversion 
   --    (Source => Stm.Word, Target => Character);

   --  function Char_To_Word is
   --     new Ada.Unchecked_Conversion 
   --    (Source => Character, Target => Stm.Word);

   --  function Addr_To_Word is
   --     new Ada.Unchecked_Conversion 
   --    (Source => System.Address, Target => Stm.Word);
   
   function To_CR_Bits is new 
     Ada.Unchecked_Conversion (Source => STM32F4.Word,
			       Target => Dma.CR_Register);
   function To_LIFCR_Bits is new 
     Ada.Unchecked_Conversion (Source => STM32F4.Word,
			       Target => Dma.LIFCR_Register);
   function To_HIFCR_Bits is new 
     Ada.Unchecked_Conversion (Source => STM32F4.Word,
			       Target => Dma.HIFCR_Register);
   function To_Bits_32 is new
     Ada.Unchecked_Conversion (Source => System.Address,
			       Target => Stm.Bits_32);
   
   
   -----------------------
   -- polling functions --
   -----------------------
   
   -- check if a wellformed line has been received          --
   -- we do it by tranferring one char at a time to the     --
   -- output buffer 'Serial_Recd_Data' and at the same time --
   -- test it for end of line (Srd_Terminator)              --
   -- if so return 'true'.                                  --
   -- we do this until we run out of chars.                 --
   -- then we return false                                  --
   -- when the outputbuffer overflows Receiver Error is set --
   -- and false is returned.                                --
   -- 'Receiver Error' should get resolved as the function  --
   -- carries on reading characters from the uart stream    --
   -- one or more commandlines will be lost then            --
   function Receiver_Is_Full return Boolean
   is
      use type stm32f4.Bits_16;
      Ndtr_Tmp  : constant Dma.Ndtr_Register  := R.Dma1.S1.NDTR;
      Srr_Idx   : Srr_Buf_P_Type := Srr_Buf_Lastread mod Srr_Buf_Size + 1;
      -- between 1 and 256
   begin
      Srr_Buf_Newest := Srr_Buf_Size - Srr_Buf_P_Type (Ndtr_Tmp.NDT);
      -- between 0 and 255  
      -- 256 is a fluke but might occur?? its in another buscycle!
      -- 255 is written : 256 - 1 = 255
      -- 256 is written : 256 - 256 = 0
      -- 1 is written   : 256 - 255 = 1
      while (Srr_Buf_Lastread - Srr_Buf_Newest < 0) or
	(Srr_Buf_Lastread - Srr_Buf_Newest > 0) loop
	 if not Receiver_Error then
	    
	    -- copy 1 byte and inc data-out index
	    Serial_Recd_Data (Srd_Index) := 
	      Serial_Recd_Ring_Buffer (Srr_idx);	    
	    Srd_Index        := Srd_Index + 1;
	    
	    -- check for end of line
	    if Serial_Recd_Ring_Buffer (Srr_idx) = Srd_Terminator then
	       return True;
	       
	       -- check for outstring overrun
	    elsif Srd_Index = Message_Length then
	       -- input line too long or mostlikely ERROR
	       -- so we must rebase
	       Receiver_Error := True;
	    end if;
	    
	 else -- there is a Receiver_Error
	    
	    -- check if the end of the faulty line is reached
	    if Serial_Recd_Ring_Buffer (Srr_idx) = Srd_Terminator then
	       -- then rebase Serial_Recd_Data
	       Receiver_Error := False;
	       Srd_Index      := 1;
	    end if;
	 end if;
	 
	 -- finally increase the 'last read' index
	 Srr_Buf_Lastread := Srr_idx;
	 -- between 1 and 256 here but starts at 0 .. 255 at 'begin'
	 Srr_Idx := Srr_Idx mod Srr_Buf_Size + 1;
	 
      end loop;
      return False;
   end Receiver_Is_Full;
   
   
   function Transmitter_Is_Empty return Boolean
   is
      use type Stm.Bits_1;
      Sr_Tmp  : constant Uart.Sr_Register  := R.Usart3.Sr;
   begin
      if  Sr_Tmp.Tc = Uart.Complete then
	 return True;
      else
	 return False;
      end if;
   end Transmitter_Is_Empty;
   
   
   function Uart_Error return Boolean
   is
      use type Stm.Bits_1;
      Sr_Tmp  : constant Uart.Sr_Register  := R.Usart3.Sr;
   begin
      if  (Sr_Tmp.Ore or Sr_Tmp.Fe or Sr_Tmp.Nf) = Uart.Tripped then 
	 return True;
      else 
	 return False;
      end if;
   end Uart_Error;
   
   
   function Dma1_Error return Boolean     -- for the xmitter --
   is                                                 -- and receiver
      use type Stm.Bits_1;
      LISR_Tmp : constant Dma.LISR_Register := R.Dma1.LISR;
   begin
      if (LISR_Tmp.TEIF3 or LISR_Tmp.DMEIF3) = Uart.Tripped then 
	 return True;   -- dma1 stream3 errors
      elsif (LISR_Tmp.TEIF1 or LISR_Tmp.DMEIF1) = Uart.Tripped then
	 return True;   -- dma1 stream1 errors
      else
	 return False;
      end if;
   end Dma1_Error;
   
   
   
   ----------------------------
   -- send a string          --
   -- not more than 64 chars --
   ----------------------------
   
   procedure Send_String (S : String)
   is
      use type Stm.Bits_1;
      S3_NDTR_Tmp : Dma.NDTR_Register;
      K : Natural := S'Length;
   begin
      -- disable dma
      S3_Cr_Tmp.En       := Dma.Off;
      R.Dma1.S3.Cr       := S3_Cr_Tmp; 
      
      -- copy string and terminate it
      Uart_Data_Tobe_Send (1 .. K) := S;
      K := K + 1;
      Uart_Data_Tobe_Send (K) := Ascii.Lf;
      
      -- set length to be transmitted
      S3_NDTR_Tmp.Ndt := Stm32f4.Bits_16 (K);
      
      -- wait for done disabling dma
      declare
         S3_Cr_Tmp : Dma.CR_Register := R.Dma1.S3.Cr;
      begin
         while S3_Cr_Tmp.En /= Dma.Off loop 
            S3_Cr_Tmp := R.Dma1.S3.Cr;
         end loop;
      end;
      
      -- set the length to be transmitted
      R.Dma1.S3.NDTR  := S3_NDTR_Tmp;
      
      -- enable dma
      S3_Cr_Tmp.En    := Dma.Enable;
      R.Dma1.S3.Cr    := S3_Cr_Tmp; 
   end Send_String;
   
   
   --------------------------------
   -- receiver interrupt handler --
   --------------------------------
   
   --  protected Serial_Recd_Data is
   --     pragma Interrupt_Priority;
      
   --     R_String : String (1 .. 68);
      
   --     function Get_String return String;
      
   --     function Get_Complete return Boolean;
      
   --  private
   --     --R_String : String (1 .. 68);
   --     Complete : Boolean := False;
      
   --     procedure Interrupt_Handler;
   --     pragma Attach_Handler
   --        (Interrupt_Handler,
   --         Ada.Interrupts.Names.Sys_Tick_Interrupt);--
   --  	    --DMA1_Stream1_Interrupt);
   --  end Serial_Recd_Data;
   
   
   --  protected body Serial_Recd_Data is
      
   --     function Get_String return String
   --     is
   --     begin
   --  	 Complete := False;
   --  	 return R_String;
   --     end Get_String;
      
   --     function Get_Complete return Boolean
   --     is
   --     begin
   --  	 return Complete;
   --     end Get_Complete;
      
   --     procedure Interrupt_Handler is
   --     begin
   --  	 null;
   --     end Interrupt_Handler;
      
   --  end Serial_Recd_Data;
   
   
   ---------------------
   -- Init Usart3 DMA --
   -- for the xmitter --
   ---------------------
   
   procedure Init_Usart3_Dma3
   is
      use type Stm.Bits_1;
      LIFCR_Tmp : constant Dma.LIFCR_Register := To_LIFCR_Bits (0);
      HIFCR_Tmp : constant Dma.HIFCR_Register := To_HIFCR_Bits (0);
      Par_Tmp   : constant Dma.PAR_Register   := 
	To_Bits_32 (R.Usart3.Dr'address);
      M0ar_Tmp  : constant Dma.M0ar_Register  :=
	To_Bits_32 (Uart_Data_Tobe_Send'Address);
   begin
      -- configure stream 3 for transmission
      S3_Cr_Tmp       := To_Cr_Bits (0);
      R.Dma1.S3.Cr    := S3_Cr_Tmp; -- disable stream1 and zero control bits
      declare 
	 S3_Cr_Tmp : Dma.CR_Register := R.Dma1.S3.Cr;
      begin
	 while S3_Cr_Tmp.En /= Dma.Off loop -- wait for done
	    S3_Cr_Tmp := R.Dma1.S3.Cr;
	 end loop;
      end;
      R.Dma1.LIFCR    := LIFCR_Tmp; -- reset all pending interrupts
      R.Dma1.HIFCR    := HIFCR_Tmp;
      
      R.Dma1.S3.Par   := Par_Tmp;   -- peripheral data address
      R.Dma1.S3.M0ar  := M0ar_Tmp;  --  string address
      
      S3_Cr_Tmp.CHSEL    := Dma.Sel_Ch1;
      S3_Cr_Tmp.MBURST   := Dma.Single;
      S3_Cr_Tmp.PBURST   := Dma.Single;
      S3_Cr_Tmp.Pl       := Dma.Low; -- low priority for transmission
      S3_Cr_Tmp.MSIZE    := Dma.Byte;
      S3_Cr_Tmp.Psize    := Dma.Byte; -- controls NDTR number i.e 64 bytes
      S3_Cr_Tmp.Minc     := Dma.Post_Inc;
      S3_Cr_Tmp.Pinc     := Dma.Off;
      S3_Cr_Tmp.Dir      := Dma.Mem_To_Periph;
      S3_Cr_Tmp.PFCTRL   := Dma.Dma_Contrld;
      R.Dma1.S3.Cr       := S3_Cr_Tmp; -- Write all this
      
      -- S3_Cr_Tmp is global hence its data stays intact 
      -- for the data send routine where the dma is enabled
   end Init_Usart3_Dma3;
   
   
   ----------------------
   -- Init Usart3 DMA  --
   -- for the receiver --
   ----------------------
   
   procedure Init_Usart3_Dma1
   is
      use type Stm.Bits_1;
      S1_Cr_Tmp : Dma.CR_Register             := To_Cr_Bits (0);
      LIFCR_Tmp : constant Dma.LIFCR_Register := To_LIFCR_Bits (0);
      HIFCR_Tmp : constant Dma.HIFCR_Register := To_HIFCR_Bits (0);
      Par_Tmp   : constant Dma.PAR_Register   := 
	To_Bits_32 (R.Usart3.Dr'address);
      M0ar_Tmp  : constant Dma.M0ar_Register  := 
	To_Bits_32 (Serial_Recd_Ring_Buffer'Address);
      Ndtr_Tmp  : Dma.Ndtr_Register;
   begin
      -- configure stream 1 for reception
      --S1_Cr_Tmp       := To_Cr_Bits (0);
      R.Dma1.S1.Cr    := S1_Cr_Tmp; -- disable stream1 and zero control bits
      declare 
	 S1_Cr_Tmp : Dma.CR_Register := R.Dma1.S1.Cr;
      begin
	 while S1_Cr_Tmp.En /= Dma.Off loop -- wait for done
	    S1_Cr_Tmp := R.Dma1.S1.Cr;
	 end loop;
      end;
      R.Dma1.LIFCR       := LIFCR_Tmp; -- reset all pending interrupts
      R.Dma1.HIFCR       := HIFCR_Tmp;
      
      R.Dma1.S1.Par      := Par_Tmp;   -- peripheral data address
      R.Dma1.S1.M0ar     := M0ar_Tmp;  --  string address
      Ndtr_Tmp.Ndt       := Srr_Buf_Size; --  ring size
      R.Dma1.S1.NDTR     := Ndtr_Tmp;     --  write ring size
      
      S1_Cr_Tmp.CHSEL    := Dma.Sel_Ch1;
      S1_Cr_Tmp.MBURST   := Dma.Single;
      S1_Cr_Tmp.PBURST   := Dma.Single;
      S1_Cr_Tmp.Pl       := Dma.high; -- high priority for reception
      S1_Cr_Tmp.MSIZE    := Dma.Byte;
      S1_Cr_Tmp.Psize    := Dma.Byte; -- controls NDTR number i.e 64 bytes
      S1_Cr_Tmp.Minc     := Dma.Post_Inc;
      S1_Cr_Tmp.Pinc     := Dma.Off;
      S1_Cr_Tmp.Circ     := Dma.Enable;
      S1_Cr_Tmp.Dir      := Dma.Periph_To_Mem;
      S1_Cr_Tmp.PFCTRL   := Dma.Dma_Contrld;
      R.Dma1.S1.Cr       := S1_Cr_Tmp; -- Write stream1 control register
      
      S1_Cr_Tmp.En       := Dma.Enable;
      R.Dma1.S1.Cr       := S1_Cr_Tmp; -- enable dma
   end Init_Usart3_Dma1;
 
   
   -----------------
   -- Init_USART3 --
   -----------------
   
   procedure Init_USART3 
   is
      Brr_Tmp : Uart.BRR_Register := R.Usart3.Brr;
      Cr1_Tmp : Uart.Cr1_Register := R.Usart3.Cr1; -- hopefully all 0
      Cr2_Tmp : Uart.Cr2_Register := R.Usart3.Cr2;
      Cr3_Tmp : Uart.Cr3_Register := R.Usart3.Cr3;
      Sr_Tmp  : Uart.Sr_Register  := R.Usart3.Sr;
   begin
      Cr1_Tmp.Ue   := Uart.Enable; -- uart enable
      Cr1_Tmp.M    := Uart.D8_Bits; -- 8 databits
      R.Usart3.Cr1 := Cr1_Tmp;
      
      Cr2_Tmp.STOP := Uart.S2_Bit; -- 2 stopbits
      R.Usart3.Cr2 := Cr2_Tmp;
      
      Cr3_Tmp.Dmat  := Uart.Enable; -- transmitter DMA
      Cr3_Tmp.Dmar  := Uart.Enable; -- receiver DMA
      Cr3_Tmp.HDSEL := Uart.Off; -- full duplex
      --Init_Usart3_Dma1; -- dont know why this was here
      R.Usart3.Cr3  := Cr3_Tmp;
      
      Brr_Tmp.DIV_Mantissa := USART3_Div_Mantissa; -- baudrate register
      Brr_Tmp.DIV_Fraction := USART3_Div_Fraction; -- at 115200
      R.Usart3.Brr         := Brr_Tmp;
      
      Init_Usart3_Dma3; -- for the xmitter side
      Init_Usart3_Dma1; -- for the receiver side
      
      Sr_Tmp.Tc    := Uart.Off; -- clear transmitter complete in the uart
      R.Usart3.Sr  := Sr_Tmp;
      
      Cr1_Tmp.Te   := Uart.Enable; -- xmitter enable
      Cr1_Tmp.Re   := Uart.Enable; -- receiver enable.
      R.Usart3.Cr1 := Cr1_Tmp;

   end Init_USART3;
         
end Sermon;

   
   
