------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                           F I N R O D . L O G                            --
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
-- the error and log handling package
--
-- it looks as if every major state machine needs its own error handling and that
-- for ease of programming they are all collected here, although conceptially
-- they belong in the individual packages.
--
-- BUT:
-- An individual Fsm that resides in the job-stack must have a way of deal with 
--  unhandled errors. So:
-- The obvious thing is to report the error here, and then jump out and return the 
-- error status to the higher layer -- or in this case parent fsm, wich might 
-- perhaps also be periodically executed on the job-stack.
--
--  Or if we are clever: when an fsm, with an unhandled error, knows who the 
--  parent is, it can put the parent back on the stack and then erase itself.
--  So the state of the parent must then be preserved on calling a sibling.
--
-- So let us here sharply distinguish between the "Job-Stack" which is a 
--  collection of pointers to subroutines that need to be executed in some order, 
--  and "An Executing Subroutine" which is a piece of code in the rom. Which has 
--  a place on the stack etc.
--
-- This implies that a "Job on the Stack" will only get executed after the 
-- execution thread has returned to  "Thread.Scan"
----------
--
-- To wit: 
--  ("reset" here means resetting and initing a lowerlevel fsm)
--
--  before "reset" the parent already has removed itself in most cases. 
--  "Reset" initializes the child fsm and puts the child fsm on the jobstack.
--  An unrecoverable error occurs:
--   The error is reported to Finrod.Error for later action.
--   Fsm returns to "reset".
--   "Reset" puts the parent back on the jobstack, the child is removed.
--   "Reset" returns to the parent Fsm, which carries on execution until there 
--   is a return to "scan".
--    "Scan" then finds the next job to execute, this will normally be this 
--     very same parent fsm, where the error is now further looked at.
-- 
--  
-- This Whole Scene Implies That any fsm grand children MUST BE REMOVED at 
-- the time of the "unrecoverable decision".
-- Otherwise there WILL be some wild software execution.
--


package Finrod.Log is
   
   type Error_Type is (No_Error,
		       Init_Error_Initialize,
		       Init_Error_Reset_Phy,
		       Init_Error_Reset_App,
		       Init_Error_Reset_Comms,
		       Init_Error_Reset_Config,
		       Eth_Error_No_Buffers,
		       Eth_Error_Buffers,
		       Eth_Error_Xmit);
   -- the error type indicates the action to be taken.
   
   subtype Init_Error_Type is 
     Error_Type range No_Error .. Init_Error_Reset_Config;
   --  Init_Error_Initialize   : complete warm reset of the board.
   --  Init_Error_Reset_Phy    : pins and uart are assumed still ok.
   --  Init_Error_Reset_App    :  also phy is assumed ok.
   --  Init_Error_Reset_Comms  :  also application is assumed ok.
   --  Init_Error_Reset_Config :  also comms (ethernet oid) are assumed ok.
   --                                  only the configuration is reset.
   
   procedure log_Error (T : Error_Type; S : String);
   -- errors in the init section are reported with
   -- the Init_Error_Type and a descriptive string
   -- by the various init packages.
   
   procedure Log (S : String);
   -- logs some event described by the string.
   
   function Check_Error return Error_Type;
   -- returns the last error for the caller to act upon.
   -- check error could trigger any printing of the descriptive string to 
   -- the terminal.
   -- WHO wipes the error after action????????????
   
   procedure Null_Last_Error with inline;
   -- null the last error.
   -- it is left in the log though
   
   procedure Print_Log;
   -- prints the last 'Log_index_type range' (32 at the moment) log entries
   -- if there are any.
   
end Finrod.Log;
