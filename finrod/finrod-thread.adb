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

with Ada.Unchecked_Deallocation;

with Finrod.Timer;

package body Finrod.Thread is
   package Timer renames Finrod.Timer;
   
   procedure Insert_Job (Ds : Job_Proc_P_Type)
   is
      Job_Entry : Job_Entry_P_Type := new Job_Entry_Type;
   begin
      Job_Entry.Job  := Ds;
      Job_Entry.Next := Job_List;
      Job_List       := Job_Entry;
   end Insert_Job;
   
   
   procedure Delete_Job (Ds : Job_Proc_P_Type)
   is
      procedure Free is
	 new Ada.Unchecked_Deallocation(Job_Entry_Type, Job_Entry_P_Type);
      Job      : Job_Entry_P_Type := Job_List;
      Prev_Job : Job_Entry_P_Type;
   begin
      while Job /= null and then Job.Job /= Ds loop
	 Prev_Job := Job;
	 Job      := Job.Next;
      end loop;
      if Job /= null then
	 Prev_Job.Next := Job.Next;
	 Free (Job);
      else
	 null;-----------------------------------error------------------
	 -- either dont know this job or last job in the queue
      end if;
   end Delete_Job;
   
   
   procedure Scan
   is
      Job : Job_Entry_P_Type;
   begin
      loop
	 Timer.Start_Timer;
	 Job := Job_List;
	 while Job /= null loop
	    Job.Job.all;
	    Job := Job.Next;
	 end loop;
	 Timer.Stop_Timer;
      end loop; -- this hangs when no job;
   end Scan;
   
   
end Finrod.Thread;
