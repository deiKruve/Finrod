------------------------------------------------------------------------------
--                                                                          --
--                            FINROD COMPONENTS                             --
--                                                                          --
--                   F I N R O D . N E T . A R P T A B L E                  --
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
-- the system address table
--

package body Finrod.Net.Arptable is
   
   --------------------------------
   -- constants,                 --
   -- definitions and local vars --
   --------------------------------
   
   type Arp_Entry_Type;
   type Arp_Entry_P_Type is access all Arp_Entry_Type;
   type Arp_Entry_Type is 
      record
	 Next : Arp_Entry_P_Type;
	 Mac  : Stm.Bits_48;
	 Ip   : Stm.Bits_32;
      end record;
   
   Arp_List : Arp_Entry_P_Type := null;
   -- This is Just The Root Pointer, once the first item is added
   -- it will be a null terminated list.
   
   Stash_List : Arp_Entry_P_Type := null;
   -- this is a temp list for entries to be entered when convenient;
   
   ----------------------
   -- public interface --
   ----------------------
   
   -- stash an address pair.
   procedure Stash (Sha : Stm.Bits_48; 
		    Spa : Stm.Bits_32)
   is
      Arp_Entry : constant Arp_Entry_P_Type := new Arp_Entry_Type;
   begin
      Arp_Entry.Mac  := Sha;
      Arp_Entry.Ip   := Spa;
      Arp_Entry.Next := Stash_List;
      Stash_List     := Arp_Entry;
   end Stash;
   
   
   -- process any stashed address pairs.
   procedure Process_Stash
   is
      Stash_Entry : Arp_Entry_P_Type := Stash_List;
   begin
      while Stash_Entry /= null loop
	 if not Exists (Stash_Entry.Mac) then
	    declare
	       Arp_Entry : constant Arp_Entry_P_Type := new Arp_Entry_Type;
	    begin
	       Arp_Entry.Mac  := Stash_Entry.Mac;
	       Arp_Entry.Ip   := Stash_Entry.Ip;
	       Arp_Entry.Next := Arp_List;
	       Arp_List       := Arp_Entry;
	    end;
	 end if;
	 Stash_Entry := Stash_Entry.Next;
      end loop;
   end Process_Stash;
   
   
   -- enter an address pair in the table
   procedure Enter (Sha : Stm.Bits_48; 
		    Spa : Stm.Bits_32)
   is
      --Arp_Entry : Arp_Entry_P_Type := new Arp_Entry_Type;
   begin
      if not Exists (Sha) then
	 declare
	    Arp_Entry : constant Arp_Entry_P_Type := new Arp_Entry_Type;
	 begin
	    Arp_Entry.Mac  := Sha;
	    Arp_Entry.Ip   := Spa;
	    Arp_Entry.Next := Arp_List;
	    Arp_List       := Arp_Entry;
	 end;
      end if;
   end Enter;
   
   
   -- see if a mac address exists in the system
   function Exists (Sha : Stm.Bits_48) return Boolean
   is
      use type Stm.Bits_48;
      Arp_Entry : Arp_Entry_P_Type := Arp_list;
   begin
      while Arp_Entry /= null loop
	 if Arp_Entry.Mac = Sha then return True;
	 end if;
	 Arp_Entry := Arp_Entry.Next;
      end loop;
      return False;
   end Exists;
   
   
   -- find an ip address for a given mac address
   function Find (Sha : Stm.Bits_48) return Stm.Bits_32
   is
      use type Stm.Bits_48;
      Arp_Entry : Arp_Entry_P_Type := Arp_list;
   begin
      while Arp_Entry /= null loop
	 if Arp_Entry.Mac = Sha then return Arp_Entry.Ip;
	 end if;
	 Arp_Entry := Arp_Entry.Next;
      end loop;
      return 0;
   end Find;
   
   
   -- find a mac address for a given ip address
   function Find (Spa : Stm.Bits_32) return Stm.Bits_48
   is
      use type Stm.Bits_32;
      Arp_Entry : Arp_Entry_P_Type := Arp_list;
   begin
      while Arp_Entry /= null loop
	 if Arp_Entry.Ip = Spa then return Arp_Entry.Mac;
	 end if;
	 Arp_Entry := Arp_Entry.Next;
      end loop;
      return 0;
   end Find;
   
end Finrod.Net.Arptable;
