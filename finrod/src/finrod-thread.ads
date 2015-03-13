------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                         F I N R O D . T H R E A D                        --
--                                                                          --
--                                 S p e c                                  --
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
-- a job must remove itself from the queue before exit.
-- so as long as a job is not removed it will be scanned, together 
-- with any other.
--
-- this implies then that a statemachine stays on the jobstack until it is 
-- made obselescent. but that is hardly right or isit?
--  Perhaps it is because in a specific state we repeat 
-- scanning for a fixed set of events in order to advance the state.

-- it would imply that a previous machine is thrown on the stack incase of 
-- a gross error . . 
-- and the next one is, after this one terminates
--
-- so concretely:
-- in the cyclic state machine:
-- we repeatedly test for Soc, 
-- when soc is detected we add 'copy input and output' on top 
-- of the queue. This is then executed after the statemachine scan, 
-- and the switch to the next state (wait for preq).
-- if there are any consequences they will be added on top before 
-- 'copy input and output' is removed. 
-- after the removal the wait for preq is executed and perhaps at 
-- this point some job might be put on the stack that will be executed 
-- alternately with wait for preq.
-- In case of gross error the next statemachine is added on top 
-- and the present one is deleted . Dont know about any queued jobs, 
-- presumably they were started before the mixup so presumable 
-- they could be allowed to finish.
--

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

package Finrod.Thread is
   
   
   type Job_Proc_P_Type is not null access procedure;
   
   type Job_Entry_Type is private;
   type Job_Entry_P_Type is access all Job_Entry_Type;
   
   procedure Insert_Job (Ds : Job_Proc_P_Type);
   -- add some routine on the stack
   -- for executing after the present load is completed
   
   procedure Delete_Job (Ds : Job_Proc_P_Type);   
   -- delete a job (like in the case of a routine with a loop)
   
   procedure Scan;
   -- start executing the job stack forever, unless there is no job
   -- but this is not legal, since then the whole system hangs.
   
   Job_List : Job_Entry_P_Type := null; 
   -- This is Just The Root Pointer, once the first item is added
   -- it will be a null terminated list.
   
private
   
   type Job_Entry_Type is 
      record
	 Next : Job_Entry_P_Type;
	 Job : Job_Proc_P_Type;
      end record;
   
end Finrod.Thread;
