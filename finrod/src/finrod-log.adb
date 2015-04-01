------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                           F I N R O D . L O G                            --
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
-- the error and log handling package

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

--with STM32F4;
with Finrod.Timer;
with Finrod.Sermon;
with Finrod.Thread;

package body Finrod.Log is
   
   --package Stm  renames STM32F4;
   package Tim  renames Finrod.Timer;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   type Log_Record_Type is record
      Time_Stamp : Tim.Time_Type;
      Species    : Error_Type;
      S          : String (1 .. 40);
      Slast      : Positive; --  an indicator for the end of the string
   end record;
   
   type Log_Index_Type is mod 2**5;  -- = 32
   type Log_Type is array (Log_Index_Type) of aliased Log_Record_Type;
   
   Log_Index    : Log_Index_Type;
   Logger       : Log_Type;
   Last_Error   : access Log_Record_Type := null;
   
   ------------------------
   --  public interface  --
   ------------------------
   
   -- errors in the init section are reported with
   -- the Init_Error_Type and a descriptive string
   -- by the various init packages.
   procedure log_Error (T : Error_Type; S : String)
   is
      Si : constant Positive := S'Last;
   begin
      Logger (Log_Index).Time_Stamp        := Tim.Read_Time;
      Logger (Log_Index).Species           := T;
      Logger (Log_Index).S (S'First .. Si) := S;
      logger (Log_Index).S (Si + 1)        := ASCII.NUL;
      logger (Log_Index).Slast             := Si;
      Last_Error := logger (Log_Index)'Access;
      Log_Index  := Log_Index + 1; -- this should roll over by itself, its a mod.
   end Log_Error;
   
   
   -- logs some event described by the string.
   procedure Log (S : String)
   is
      Si : constant Positive := S'Last;
   begin
      Logger (Log_Index).Time_Stamp        := Tim.Read_Time;
      Logger (Log_Index).Species           := No_Error;
      Logger (Log_Index).S (S'First .. Si) := S;
      logger (Log_Index).S (Si + 1)        := ASCII.NUL;
      logger (Log_Index).Slast             := Si;
      Log_Index  := Log_Index + 1;
   end Log;
   
   
   -- returns the last error for the caller to act upon.
   -- THIS CANT BE -- the last error pointer is set back to null
   -- check error could trigger any printing of the descriptive string to 
   -- the terminal.
   function Check_Error return Error_Type
   is
   begin
      if Last_Error /= null then
	 Sermon.Send_String 
	   (Tim.Image (Last_Error.Time_Stamp) & 
	      Last_Error.S (Last_Error.S'First .. Last_Error.Slast));
	 return Last_Error.Species;
      else
	 return No_Error;
      end if;
   end Check_Error;
   
   
   -- null the last error.
   -- it is left in the log though
   procedure Null_Last_Error
   is
   begin
      Last_Error := null;
   end Null_Last_Error;
   
   ------------------------------------
   -- prints the last 'Log_index_type range' (32 at the moment) log entries
   -- if there are any.
   --  procedure Print_Logold
   --  is
   --     Index : Log_Index_Type := Log_Index + 1;
   --  begin
   --     while Index /= Log_Index loop
   --  	if Logger (Index).S (Logger (Index).S'First) /= ASCII.NUL then
   --  	   Sermon.Send_String 
   --  	   (Timer.Image (Logger (Index).Time_Stamp) & 
   --  	      Logger (Index).S (Logger (Index).S'First .. Logger (Index).Slast));
   --  	end if;
   --  	Index := Index + 1;
   --     end loop;
   --  end Print_Logold;
   
   ----------------------------
   
   R_Indx : Log_Index_Type;
   
   -- must be inserted on the job stack, 
   -- it is a low priotity job!, just like spy is
   procedure Try_Print_A_Record
   is
   begin
      if Sermon.Transmitter_Is_Empty then
	 if R_Indx /= Log_Index and 
	   Logger (R_Indx).S (Logger (R_Indx).S'First) /= ASCII.NUL then
	    Sermon.Send_String 
	      (Timer.Image (Logger (R_Indx).Time_Stamp) & 
		 Logger (R_Indx).S 
		 (Logger (R_Indx).S'First .. Logger (R_Indx).Slast));
	    R_Indx := R_Indx + 1; --  It Will Roll Over But Thats ok
	 else
	    -- remove yourself
	    Thread.Delete_Job (Try_Print_A_Record'Access);
	 end if;
      end if;
   end Try_Print_A_Record;
   
   
   -- prints the last 'Log_index_type range' (32 at the moment) log entries
   -- if there are any.
   procedure Print_Log
   is
   begin
      R_Indx := Log_Index + 1;
      -- insert Try_Print_A_Record (must be more precise later)
      Thread.Insert_Job (Try_Print_A_Record'Access);
   end Print_Log;
   
   
   
begin
   for I in Logger'First .. Logger'Last loop
      Logger (I).Species := No_Error;
      Logger (I).S (Logger (I).S'First) := ASCII.NUL;
   end loop;
   Log_Index := Logger'First;
end Finrod.Log;
