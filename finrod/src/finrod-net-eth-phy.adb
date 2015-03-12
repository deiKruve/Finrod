------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                    F I N R O D . N E T . E T H . P H Y                   --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                     Copyright (C) 2015, Jan de Kruyf                     --
--                                                                          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.                                               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
--                Finrod  is maintained by J de Kruijf Engineers            --
--                     (email: jan.de.kruyf@hotmail.com)                    --
--                                                                          --
------------------------------------------------------------------------------
--
-- this is the finrod ethernet PHY interface
-- 

with STM32F4.Gpio;
with STM32F4.o7xx.Eth;
with STM32F4.o7xx.Registers;

with Finrod.Board;
with Finrod.Timer;
with Finrod.Thread;

package body Finrod.Net.Eth.PHY is
   
   package Stm  renames  STM32F4;
   package Gpio renames  STM32F4.Gpio;
   package Eth  renames  STM32F4.o7xx.Eth;
   package R    renames  STM32F4.o7xx.Registers;
   package Thr  renames  Finrod.Thread;
   
   ------------------------------
   -- some types and constants --
   ------------------------------
   
   Phy_Addr   : Stm.Bits_5;
   Phy_Mspeed : Stm.Bits_3;
   
   
   -- poll the phy interrupt in GPIOA
   function Phy_Interrupted return Boolean
   is
      use type Stm.Bits_16;
      Gpioai_Tmp : constant Stm.Bits_16 := R.GPIOa.Idr;
   begin
      if (Gpioai_Tmp and Stm.Bits_16 (2**Gpio.Dr3)) = 0 then
	 return True;
      else return False;
      end if;
   end Phy_Interrupted;
	 
   
   -- poll the phy for availability
   function Phy_Available return Boolean
   is
      use type Stm.Bits_1;
      MACMIIAR_Tmp : constant Eth.MACMIIAR_Register := R.Eth_Mac.MACMIIAR;
   begin
      if MACMIIAR_Tmp.Mb = Eth.Clear then
	 return True;
      else
	 return False;
      end if;
   end Phy_Available;

   
   -- PHY wite routine
   procedure Phy_Write (pAddr : Stm.Bits_5; 
			MReg  : Stm.Bits_5; 
			Clk   : Stm.Bits_3; 
			Data  : Stm.Bits_16)
   is
      use type Stm.Bits_1;
      MACMIIAR_Tmp : Eth.MACMIIAR_Register := R.Eth_Mac.MACMIIAR;
      MACMIIDR_Tmp : Eth.MACMIIDR_Register := R.Eth_Mac.MACMIIDR;
   begin
      MACMIIDR_Tmp.MD    := Data;
      R.Eth_Mac.MACMIIDR := MACMIIDR_Tmp;
      
      MACMIIAR_Tmp.Pa    := Paddr;
      MACMIIAR_Tmp.Mr    := Mreg;
      MACMIIAR_Tmp.Cr    := Clk;
      MACMIIAR_Tmp.Mw    := Eth.Write;
      MACMIIAR_Tmp.Mb    := Eth.Busy;
      R.Eth_Mac.MACMIIAR := MACMIIAR_Tmp;
   end Phy_Write;
   
   
   -- PHY preparation for read routine
   -- sets the phy up for reading some internal data
   --   pAddr - the board address of the phy
   --   MReg  - the register number in the Phy
   --   Clk   - the clock to use
   procedure Phy_Read_Prep (pAddr : Stm.Bits_5; 
		      MReg  : Stm.Bits_5; 
		      Clk   : Stm.Bits_3)
   is
      MACMIIAR_Tmp : Eth.MACMIIAR_Register := R.Eth_Mac.MACMIIAR;
   begin
      MACMIIAR_Tmp.Pa    := Paddr;
      MACMIIAR_Tmp.Mr    := Mreg;
      MACMIIAR_Tmp.Cr    := Clk;
      MACMIIAR_Tmp.Mw    := Eth.Read;
      MACMIIAR_Tmp.Mb    := Eth.Busy;
      R.Eth_Mac.MACMIIAR := MACMIIAR_Tmp;
   end Phy_Read_Prep;
   
   
   --------------------------------
   --  PHY finite state machine  --
   --------------------------------
   

   Fsm_State : State_Selector_Type := Phy_Idle;
   
   
   procedure Fsm
   is
   begin
      case Fsm_State is
	 when Phy_Idle        =>
	    null;
	 when Phy_Reset   =>
	    if Phy_Available then
	       -- reset to the phy
	       Phy_Write (PAddr => Phy_Addr,
			  MReg  => 0,
			  Clk   => Phy_Mspeed,
			  Data  => 16#8_000#); -- reset
	       Timer.Start_Timer1 (0, 500_000_000);
	       Fsm_State := Phy_Wait1;
	    end if;
	 when Phy_Wait1    =>
	    if Phy_Available and Timer.Done1 then
	       Fsm_State := Phy_Init1;
	    end if;
	 when Phy_Init1    =>
	    Phy_Write (PAddr => Phy_Addr,
		       MReg  => 0,
		       Clk   => Phy_Mspeed,
		       Data  => 2#0010_0000_1000_0000#); -- 100M
							 -- enable COL test
	    Fsm_State := Phy_Init2;
	 when Phy_Init2    =>
	    -- set interrupt sources mask
	    if Phy_Available then
	       Phy_Write (PAddr => Phy_Addr,
			  MReg  => 30,
			  Clk   => Phy_Mspeed,
			  Data  => 2#0000_0000_0011_0000#); -- Remote Fault Detected
							    -- Link Down 
	       Fsm_State := Phy_wait2;
	    end if;
	 when Phy_Ask_Error =>
	    if Phy_Available then
	       Phy_Read_Prep (pAddr => Phy_Addr,
			      MReg  => 29,
			      Clk   => Phy_Mspeed);
	       Fsm_State := Phy_wait2;
	    end if;
	 when Phy_Wait2     =>
	    if Phy_Available then
	       Thr.Delete_Job (Fsm'Access);
	       Fsm_State := Phy_Ready;
	    end if;
	 when Phy_Ready     =>
	    null;
      end case;
   end Fsm;
   
   
   -- when the initialization is done 'State' will return 'Phy_Ready'.
   function State return State_Selector_Type
   is (Fsm_State);
   
   
   -- starts the PHY initialization procedure from a soft reset.
   -- it will put the PHY's fsm on the job stack for executing 1 pass
   -- every scan period.
   -- once finished the fsm will disappear from the jobstack and 
   -- the state selector will be at ready.
   procedure Reset 
   is
   begin
      Fsm_State := Phy_Reset;
      Thr.Insert_Job (Fsm'Access);
   end Reset;
   
   
   -- asks the PHY to reveal its status.
   -- After 'State' returns 'Phy_Ready' the error can be gotten with 
   -- 'Which_Error'
   procedure Ask_Error
   is
   begin
      Fsm_State := Phy_Ask_Error;
      Thr.Insert_Job (Fsm'Access);
   end Ask_Error;
   
   
   -- will return the Error_Type;
   function Which_Error return Error_Type
   is 
      use type Stm.Bits_16;
      Md : constant Stm.Bits_16 := R.Eth_Mac.MACMIIDR.Md;
   begin
      If (MD and 2#0000_0000_0010_0000#) /= 0  then
	 return Remote_Fault_Detected;
      elsif (MD and 2#0000_0000_0001_0000#) /= 0 then
	 return Link_Down;
      else return No_Error;
      end if;
   end Which_Error;
      
begin
   Phy_Addr    := Board.Get_PHY_Address;
   Phy_Mspeed  := Board.Get_PHY_Mspeed;
end Finrod.Net.Eth.PHY;
