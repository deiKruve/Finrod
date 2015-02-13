
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
   APB2_Clock           : constant Long_Float := 84_000_000.0;
   pragma Unreferenced (APB2_Clock);
   -- APB2_Clock (usart1) on 84 MHz
   USART1_Baudrate      : constant Long_Float := 115200.0;
   
   -- calculate baudrate contants for over_8 = 0
   USART1_D             : constant Long_Float := 
     APB1_Clock / (16.0 * USART1_Baudrate);
   USART1_Div_Mantissa  : constant Stm.Bits_12 := 
     Stm.Bits_12 (Long_Float'Truncation (USART1_D));
   USART1_Div_Fraction  : constant Stm.Bits_4  := 
     Stm.Bits_4 (Long_Float'Rounding 
		((USART1_D - Long_Float (USART1_Div_Mantissa)) * 16.0));
   pragma Unreferenced (USART1_Div_Fraction);
   
   -- this register must be global 
   S7_Cr_Tmp : Dma.CR_Register;
   
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
      Ndtr_Tmp  : constant Dma.Ndtr_Register  := R.Dma2.S2.NDTR;
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
	       Srd_Terminator_Index := Srd_Index; 
	       -- this now gives od 00 at the end----------------------
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
      Sr_Tmp  : constant Uart.Sr_Register  := R.Usart1.Sr;
   begin
      if  Sr_Tmp.Txe = Uart.Dr_Mt then
	 return True;
      else
	 return False;
      end if;
   end Transmitter_Is_Empty;
   
   
   function Uart_Error return Boolean
   is
      use type Stm.Bits_1;
      Sr_Tmp  : constant Uart.Sr_Register  := R.Usart1.Sr;
   begin
      if  (Sr_Tmp.Ore or Sr_Tmp.Fe or Sr_Tmp.Nf) = Uart.Tripped then 
	 return True;
      else 
	 return False;
      end if;
   end Uart_Error;
   
   
   function Dma2_Error return Boolean     -- for the xmitter --
   is                                                 -- and receiver
      use type Stm.Bits_1;
      LISR_Tmp : constant Dma.LISR_Register := R.Dma2.LISR;
      HISR_Tmp : constant Dma.Hisr_Register := R.Dma2.HISR;
   begin
      if (LISR_Tmp.TEIF2 or LISR_Tmp.DMEIF2) = Uart.Tripped then 
	 return True;   -- dma2 stream3 errors
      elsif (HISR_Tmp.TEIF7 or HISR_Tmp.DMEIF7) = Uart.Tripped then
	 return True;   -- dma2 stream7 errors
      else
	 return False;
      end if;
   end Dma2_Error;
   
   
   
   ----------------------------
   -- send a string          --
   -- not more than 64 chars --
   ----------------------------
   
   procedure Send_String (S : String)
   is
      use type Stm.Bits_1;
      HIFCR_Tmp   : Dma.HIFCR_Register := To_HIFCR_Bits (0);
      S7_NDTR_Tmp : Dma.NDTR_Register;
      K           : Natural := S'Length;
   begin
      -- disable dma
      S7_Cr_Tmp.En       := Dma.Off;
      R.Dma2.S7.Cr       := S7_Cr_Tmp; 
      
      -- copy string and terminate it
      Uart_Data_Tobe_Send (1 .. K) := S;
      K := K + 1;
      Uart_Data_Tobe_Send (K) := Ascii.Cr;
      K := K + 1;
      Uart_Data_Tobe_Send (K) := Ascii.Lf;
      
      -- set length to be transmitted
      S7_NDTR_Tmp.Ndt := Stm32f4.Bits_16 (K);
      
      -- wait for done disabling dma
      declare
         S7_Cr_Tmp : Dma.CR_Register := R.Dma2.S7.Cr;
      begin
         while S7_Cr_Tmp.En /= Dma.Off loop 
            S7_Cr_Tmp := R.Dma2.S7.Cr;
         end loop;
      end;
      
      -- reset any pending interrupts
      HIFCR_Tmp.CFEIF7 := dma.Clearit; 
      -- dont know why there should be a fifo error
      HIFCR_Tmp.CHTIF7 := dma.Clearit; -- half done
      HIFCR_Tmp.CTCIF7 := dma.Clearit; -- full done
      R.Dma2.HIFCR     := HIFCR_Tmp;
      
      -- set the length to be transmitted
      R.Dma2.S7.NDTR  := S7_NDTR_Tmp;
      
      -- enable dma
      S7_Cr_Tmp.En    := Dma.Enable;
      R.Dma2.S7.Cr    := S7_Cr_Tmp; 
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
   -- Init Usart1 DMA --
   -- for the xmitter --
   ---------------------
   
   procedure Init_Usart1_Dma7
   is
      use type Stm.Bits_1;
      LIFCR_Tmp : constant Dma.LIFCR_Register := To_LIFCR_Bits (0);
      HIFCR_Tmp : constant Dma.HIFCR_Register := To_HIFCR_Bits (0);
      Par_Tmp   : constant Dma.PAR_Register   := 
	To_Bits_32 (R.Usart1.Dr'address);
      M0ar_Tmp  : constant Dma.M0ar_Register  :=
	To_Bits_32 (Uart_Data_Tobe_Send'Address);
   begin
      -- configure stream 7 for transmission.
      -- disable stream7 and zero control bits
      S7_Cr_Tmp       := To_Cr_Bits (0); -- S7_Cr_Tmp is global
      R.Dma2.S7.Cr    := S7_Cr_Tmp; 
      
      -- wait for done
      declare 
	 S7_Cr_Tmp : Dma.CR_Register := R.Dma2.S7.Cr;
      begin
	 while S7_Cr_Tmp.En /= Dma.Off loop
	    S7_Cr_Tmp := R.Dma2.S7.Cr;
	 end loop;
      end;
      
      -- reset all pending interrupts
      R.Dma2.LIFCR    := LIFCR_Tmp; 
      R.Dma2.HIFCR    := HIFCR_Tmp;
      
      -- source and destination address
      R.Dma2.S7.Par   := Par_Tmp;   -- peripheral data address
      R.Dma2.S7.M0ar  := M0ar_Tmp;  --  string address
      
      -- control register variabelen
      S7_Cr_Tmp.CHSEL    := Dma.Sel_Ch4;
      S7_Cr_Tmp.MBURST   := Dma.Single;
      S7_Cr_Tmp.PBURST   := Dma.Single;
      S7_Cr_Tmp.Pl       := Dma.Low; -- low priority for transmission
      S7_Cr_Tmp.MSIZE    := Dma.Byte; -- 8 bits at a time
      S7_Cr_Tmp.Psize    := Dma.Byte; 
      S7_Cr_Tmp.Minc     := Dma.Post_Inc; -- memory post inc
      S7_Cr_Tmp.Pinc     := Dma.Off;
      S7_Cr_Tmp.Dir      := Dma.Mem_To_Periph;
      S7_Cr_Tmp.PFCTRL   := Dma.Dma_Contrld;
      R.Dma2.S7.Cr       := S7_Cr_Tmp; -- Write all this
      
      -- S7_Cr_Tmp is global hence its data stays intact 
      --  for the data send routine where the dma is enabled.
   end Init_Usart1_Dma7;
   
   
   ----------------------
   -- Init Usart1 DMA  --
   -- for the receiver --
   ----------------------
   
   procedure Init_Usart1_Dma2
   is
      use type Stm.Bits_1;
      S2_Cr_Tmp : Dma.CR_Register             := To_Cr_Bits (0);
      LIFCR_Tmp : constant Dma.LIFCR_Register := To_LIFCR_Bits (0);
      HIFCR_Tmp : constant Dma.HIFCR_Register := To_HIFCR_Bits (0);
      Par_Tmp   : constant Dma.PAR_Register   := 
	To_Bits_32 (R.Usart1.Dr'address);
      M0ar_Tmp  : constant Dma.M0ar_Register  := 
	To_Bits_32 (Serial_Recd_Ring_Buffer'Address);
      Ndtr_Tmp  : Dma.Ndtr_Register;
   begin
      -- configure stream 2 for reception
      -- disable stream1 and zero control bits
      R.Dma2.S2.Cr    := S2_Cr_Tmp; 
      
      -- wait for done
      declare 
	 S2_Cr_Tmp : Dma.CR_Register := R.Dma2.S2.Cr;
      begin
	 while S2_Cr_Tmp.En /= Dma.Off loop 
	    S2_Cr_Tmp := R.Dma2.S2.Cr;
	 end loop;
      end;
      
      -- reset all pending interrupts
      R.Dma2.LIFCR       := LIFCR_Tmp; 
      R.Dma2.HIFCR       := HIFCR_Tmp;
      
      -- source and destination address
      R.Dma2.S2.Par      := Par_Tmp;   -- peripheral data address
      R.Dma2.S2.M0ar     := M0ar_Tmp;  --  string address
      
      --  set the receiver ring buffer size
      Ndtr_Tmp.Ndt       := Srr_Buf_Size; 
      R.Dma2.S2.NDTR     := Ndtr_Tmp;     --  write ring size
      
      -- control register variabelen
      S2_Cr_Tmp.CHSEL    := Dma.Sel_Ch4;
      S2_Cr_Tmp.MBURST   := Dma.Single;
      S2_Cr_Tmp.PBURST   := Dma.Single;
      S2_Cr_Tmp.Pl       := Dma.high; -- high priority for reception
      S2_Cr_Tmp.MSIZE    := Dma.Byte; -- 8 bits at a time
      S2_Cr_Tmp.Psize    := Dma.Byte; 
      S2_Cr_Tmp.Minc     := Dma.Post_Inc; -- memory post incement
      S2_Cr_Tmp.Pinc     := Dma.Off;
      S2_Cr_Tmp.Circ     := Dma.Enable; -- circular buffer enable
      S2_Cr_Tmp.Dir      := Dma.Periph_To_Mem;
      S2_Cr_Tmp.PFCTRL   := Dma.Dma_Contrld;
      R.Dma2.S2.Cr       := S2_Cr_Tmp; -- Write stream2 control register
      
      -- enable dma
      S2_Cr_Tmp.En       := Dma.Enable;
      R.Dma2.S2.Cr       := S2_Cr_Tmp; 
   end Init_Usart1_Dma2;
 
   
   -----------------
   -- Init_USART1 --
   -----------------
   
   procedure Init_USART1 
   is
      Brr_Tmp : Uart.BRR_Register := R.Usart1.Brr;
      pragma Unreferenced (Brr_Tmp);
      Cr1_Tmp : Uart.Cr1_Register := R.Usart1.Cr1; -- hopefully all 0
      Cr2_Tmp : Uart.Cr2_Register := R.Usart1.Cr2;
      Cr3_Tmp : Uart.Cr3_Register := R.Usart1.Cr3;
      Sr_Tmp  : Uart.Sr_Register  := R.Usart1.Sr;
   begin
      Cr1_Tmp.Ue   := Uart.Enable; -- uart enable
      Cr1_Tmp.M    := Uart.D8_Bits; -- 8 databits
      R.Usart1.Cr1 := Cr1_Tmp;
      
      Cr2_Tmp.STOP := Uart.S2_Bit; -- 2 stopbits
      R.Usart1.Cr2 := Cr2_Tmp;
      
      Cr3_Tmp.Dmat  := Uart.Enable; -- transmitter DMA
      Cr3_Tmp.Dmar  := Uart.Enable; -- receiver DMA
      Cr3_Tmp.HDSEL := Uart.Off; -- full duplex
      --Init_Usart1_Dma2; -- dont know why this was here
      R.Usart1.Cr3  := Cr3_Tmp;
      
      --Brr_Tmp.DIV_Mantissa := USART1_Div_Mantissa; -- baudrate register
      --Brr_Tmp.DIV_Fraction := USART1_Div_Fraction; -- at 115200
      --R.Usart1.Brr         := Brr_Tmp;
      
      Init_Usart1_Dma7; -- for the xmitter side
      Init_Usart1_Dma2; -- for the receiver side
      
      Sr_Tmp.Tc    := Uart.Off; -- clear transmitter complete in the uart
      R.Usart1.Sr  := Sr_Tmp;
      
      Cr1_Tmp.Te   := Uart.Enable; -- xmitter enable
      Cr1_Tmp.Re   := Uart.Enable; -- receiver enable.
      R.Usart1.Cr1 := Cr1_Tmp;

   end Init_USART1;
   
begin
   Serial_Recd_Data_A := Serial_Recd_Data'Access;
end Sermon;

   
   
