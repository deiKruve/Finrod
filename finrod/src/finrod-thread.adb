------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                         F I N R O D . T H R E A D                        --
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
-- the jobber structure of finrod
--

-- with Ada.Unchecked_Deallocation;

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

with System;
with Ada.Unchecked_Conversion;

with Finrod.Timer;

package body Finrod.Thread is
   package Timer renames Finrod.Timer;
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   type Job_Entry_Type;
   type Job_Entry_P_Type is access all Job_Entry_Type;
   type Job_Entry_Type is 
      record
	 Next : Job_Entry_P_Type;
	 Job : System.Address; --  Job_Proc_P_Type;
      end record;
   
  
   -- This is Just The Root Pointer, once the first item is added
   -- it will be a null terminated list.
   Job_List : Job_Entry_P_Type := null; 
   Free_List : Job_Entry_P_Type := null; 
   
   
   ----------------------
   -- public interface --
   ----------------------
   Job_Entry : Job_Entry_P_Type;
   -- add some routine on the stack
   -- for executing after the present load is completed
   procedure Insert_Job (Ds : Job_Proc_P_Type)
   is
      --Job_Entry : Job_Entry_P_Type;
   begin
      -- check for reusable structs
      if Free_List /= null then
	 Job_Entry := Free_List;
	 Free_List := Free_List.Next;
      else
	 Job_Entry := new Job_Entry_Type;
      end if;
      
      -- link it into the job chain
      Job_Entry.Job  := Ds.all'Address;
      Job_Entry.Next := Job_List;
      Job_List       := Job_Entry;
   end Insert_Job;
   
   
   -- delete a job (like in the case of a routine with a loop)
   procedure Delete_Job (Ds : Job_Proc_P_Type)
   is 
      use type System.Address;
      Job_Entry : Job_Entry_P_Type := Job_List;
      Prev_Job  : Job_Entry_P_Type;
   begin
      while Job_Entry /= null and then Job_Entry.Job /= Ds.all'Address loop
	 Prev_Job  := Job_Entry;
	 Job_Entry := Job_Entry.Next;
      end loop;
      if Job_Entry /= null then
	 -- take it out of the job chain
	 Prev_Job.Next := Job_Entry.Next;
	 -- and link it into the free chain
	 --Job_Entry.Job := null; snotallowed! so it MUST be overwritten
	 Job_Entry.Next := Free_List;
	 Free_List := Job_Entry;
      else
	 null;-----------------------------------error------------------
	 -- either dont know this job or last job in the queue
      end if;
   end Delete_Job;
   
   
   -- start executing the job stack
   procedure Scan
   is
      function Toac is new 
	Ada.Unchecked_Conversion (Source => System.Address,
				  Target => Job_Proc_P_Type);
      Job_Entry : Job_Entry_P_Type;
   begin
      -- maybe we only do one scan at a time so if
      -- the stack contains fsm's they execute only once per scan
      --loop
	 Timer.Start_Timer;---------------------------for testing
	 Job_Entry    := Job_List;
	 while Job_Entry /= null loop
	    Toac (Job_Entry.Job).all;
	    Job_Entry := Job_Entry.Next;
	 end loop;
	 Timer.Stop_Timer;-----------------------------for testing
      --end loop; -- this hangs when no job;
   end Scan;
   
   
end Finrod.Thread;
