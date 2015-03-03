--
--  Copyright (C) 2006-2013, AdaCore
--

with Ada.Unchecked_Conversion;

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

package body Memory_Copy is

   subtype mem is char_array (size_t);
   type memptr is access all mem;
   function to_memptr is new Ada.Unchecked_Conversion (Address, memptr);

   ------------
   -- memcpy --
   ------------

   procedure memcpy (Dest : Address; Src : Address; N : size_t) is
      dest_p : constant memptr := to_memptr (Dest);
      src_p  : constant memptr := to_memptr (Src);
   begin
      if N > 0 then
         for J in 0 .. N - 1 loop
            dest_p (J) := src_p (J);
         end loop;
      end if;
   end memcpy;

end Memory_Copy;
