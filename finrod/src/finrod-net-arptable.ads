------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                   F I N R O D . N E T . A R P T A B L E                  --
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
-- the system address table
--

package Finrod.Net.Arptable is
      
   procedure Stash (Sha : Stm.Bits_48; 
		    Spa : Stm.Bits_32);
   -- stash an address pair.
   
   procedure Process_Stash;
   -- process any stashed address pairs.
   
   procedure Enter (Sha : Stm.Bits_48; 
		    Spa : Stm.Bits_32);
   -- enter an address pair in the table
   
   function Exists (Sha : Stm.Bits_48) return Boolean;
   -- see if a mac address exists in the system
   
   function Find (Sha : Stm.Bits_48) return Stm.Bits_32;
   -- find an ip address for a given mac address
   
   function Find (Spa : Stm.Bits_32) return Stm.Bits_48;
   -- find a mac address for a given ip address
   
end Finrod.Net.Arptable;
