------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                            S AM P L E _ A P P                            --
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

with STM32F4;
with Finrod.Board;
with Finrod.Nmt_Init;
with Finrod.App;

package body Sample_App is

   package Stm  renames STM32F4;
   package Board renames Finrod.Board;
   
   procedure Init
   is
   begin
      null;
   end Init;
   
begin
   Finrod.App.Init := Init'Access; -- uplink to the library for initing
				   -- from there
end Sample_App;
