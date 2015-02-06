
with System;
with Ada.Unchecked_Conversion;
with Ada.Interrupts.Names;
with STM32F4.O7xx.Registers;
with STM32F4.o7xx.Dma;
with STM32F4.o7xx.Usart;
--with 
--with STM32F4.Gpio;

package body Sermon is
   package Stm  renames STM32F4;
   package R    renames STM32F4.O7xx.Registers;
   package Uart renames STM32F4.o7xx.Usart;
   package Dma  renames STM32F4.o7xx.Dma;
   
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
   USART3_Div_Mantissa  : constant Stm.Bits_12 := 
     Stm.Bits_12 (Long_Float'Truncation (USART3_D));
   USART3_Div_Fraction  : constant Stm.Bits_4  := 
     Stm.Bits_4 (Long_Float'Rounding 
		((USART3_D - Long_Float (USART3_Div_Mantissa)) * 16.0));
   
   -- to hold raw DMA USART data
   type Word_Buffer_Type is array (1 .. Buf_Size) of Stm.Word;
   DMA_Data     : Word_Buffer_Type           := (others => 0);
   
   S3_Cr_Tmp : Dma.CR_Register;
   Uart_Data_Tobe_Send : aliased String (1 .. 68);
   
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
   
   function Get_DMA_Word (Index : Positive) return Stm.Word 
   is
      
   begin
      if Index <= Buf_Size then
         return DMA_Data (Index);
      else
         return DMA_Data (1); -- only if bad index is passed in
      end if;
   end Get_DMA_Word;
   
   
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
      S3_Cr_Tmp.En       := Dma.Off;
      R.Dma1.S3.Cr       := S3_Cr_Tmp; -- disable dma
      
      if K > 63 then K := 63;
      elsif K = 0 then return;
      end if;
      for J in 1 .. K loop
	Uart_Data_Tobe_Send (j) := S(S'First - 1 + K);
      end loop;
      Uart_Data_Tobe_Send (K + 1) := Ascii.Lf;
      for J in K + 2 .. 64 loop
	 Uart_Data_Tobe_Send (j) :=  Character'Val(0);
      end loop;
      
      while R.Dma1.S3.Cr.En /= Dma.Off loop -- wait for done
	 null;
      end loop;
      S3_NDTR_Tmp.Ndt := 64;
      R.Dma1.S3.NDTR  := S3_NDTR_Tmp; -- try fixed records, 
					 -- but perhaps this 
			    -- might be changed at evey transmission
      S3_Cr_Tmp.En    := Dma.Enable;
      R.Dma1.S3.Cr    := S3_Cr_Tmp; -- enable dma
   end Send_String;
   
   
   --------------------------------
   -- receiver interrupt handler --
   --------------------------------
   
   protected Serial_Recd_Data is
      pragma Interrupt_Priority;
      
      R_String : String (1 .. 68);
      
      function Get_String return String;
      
      function Get_Complete return Boolean;
      
   private
      --R_String : String (1 .. 68);
      Complete : Boolean := False;
      
      procedure Interrupt_Handler;
      pragma Attach_Handler
         (Interrupt_Handler,
          Ada.Interrupts.Names.Sys_Tick_Interrupt);--
	    --DMA1_Stream1_Interrupt);
   end Serial_Recd_Data;
   
   
   protected body Serial_Recd_Data is
      
      function Get_String return String
      is
      begin
	 Complete := False;
	 return R_String;
      end Get_String;
      
      function Get_Complete return Boolean
      is
      begin
	 return Complete;
      end Get_Complete;
      
      procedure Interrupt_Handler is
      begin
	 null;
      end Interrupt_Handler;
      
   end Serial_Recd_Data;
   
   
   ---------------------
   -- Init Usart3 DMA --
   -- for the xmitter --
   ---------------------
   
   procedure Init_Usart3_Dma3
   is
      use type Stm.Bits_1;
      S3_Cr_Tmp : Dma.CR_Register             := To_Cr_Bits (0);
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
      while R.Dma1.S3.Cr.En /= Dma.Off loop -- wait for done
	 null;
      end loop;
      R.Dma1.LIFCR    := LIFCR_Tmp; -- reset all pending interrupts
      R.Dma1.HIFCR    := HIFCR_Tmp;
      
      R.Dma1.S3.Par   := Par_Tmp;   -- peripheral data address
      R.Dma1.S3.M0ar  := M0ar_Tmp;  --  string address
      
      --R.Dma1.S3.NDTR.Ndt := 0; --64; -- try fixed records, but perhaps this 
			    -- might be changed at evey transmission
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
	To_Bits_32 (Serial_Recd_Data.R_String'Address);-----------
   begin
      -- configure stream 1 for reception
      S1_Cr_Tmp       := To_Cr_Bits (0);
      R.Dma1.S1.Cr    := S1_Cr_Tmp; -- disable stream1 and zero control bits
      while R.Dma1.S1.Cr.En /= Dma.Off loop -- wait for done
	 null;
      end loop;
      R.Dma1.LIFCR    := LIFCR_Tmp; -- reset all pending interrupts
      R.Dma1.HIFCR    := HIFCR_Tmp;
      
      R.Dma1.S1.Par   := Par_Tmp;   -- peripheral data address
      R.Dma1.S1.M0ar  := M0ar_Tmp;  --  string address
      
      R.Dma1.S1.NDTR.Ndt := 64; --64; -- try fixed records
      S1_Cr_Tmp.CHSEL    := Dma.Sel_Ch1;
      S1_Cr_Tmp.MBURST   := Dma.Single;
      S1_Cr_Tmp.PBURST   := Dma.Single;
      S1_Cr_Tmp.Pl       := Dma.high; -- high priority for reception
      S1_Cr_Tmp.MSIZE    := Dma.Byte;
      S1_Cr_Tmp.Psize    := Dma.Byte; -- controls NDTR number i.e 64 bytes
      S1_Cr_Tmp.Minc     := Dma.Post_Inc;
      S1_Cr_Tmp.Pinc     := Dma.Off;
      S1_Cr_Tmp.Dir      := Dma.Periph_To_Mem;
      S1_Cr_Tmp.PFCTRL   := Dma.Dma_Contrld;
      R.Dma1.S1.Cr       := S1_Cr_Tmp; -- Write all this
      S1_Cr_Tmp.En    := Dma.Enable;
      R.Dma1.S1.Cr    := S1_Cr_Tmp; -- enable dma
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
      Cr3_Tmp.HDSEL := Uart.On; -- half duplex
      Init_Usart3_Dma1;
      R.Usart3.Cr3  := Cr3_Tmp;
      -- check error interrupt story
      
      Brr_Tmp.DIV_Mantissa := USART3_Div_Mantissa; -- baudrate register
      Brr_Tmp.DIV_Fraction := USART3_Div_Fraction; -- at 115200
      R.Usart3.Brr         := Brr_Tmp;
      
      Init_Usart3_Dma3; -- for the xmitter side
      Init_Usart3_Dma1; -- for the receiver side
      
      Sr_Tmp.Tc   := Uart.Off; -- clear transmitter complete in the uart
      R.Usart3.Sr  := Sr_Tmp;
      
      Cr1_Tmp.Te   := Uart.Enable; -- xmitter enable
      Cr1_Tmp.Re   := Uart.Enable; -- receiver enable.
      R.Usart3.Cr1 := Cr1_Tmp;
      
	
   end Init_USART3;
         
   
   
   
   
end Sermon;

   
   
