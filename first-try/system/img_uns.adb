------------------------------------------------------------------------------
--                                                                          --
--                         GNAT RUN-TIME COMPONENTS                         --
--                                                                          --
--                       S Y S T E M . I M G _ U N S                        --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--          Copyright (C) 1992-2009, Free Software Foundation, Inc.         --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

pragma Warnings (Off, "*may call Last_Chance_Handler");
pragma Warnings (Off, "*(No_Exception_Propagation) in effect");

with System.Unsigned_Types; use System.Unsigned_Types;

package body Img_Uns is

   --------------------
   -- Image_Unsigned --
   --------------------

   procedure Image
     (V : System.Unsigned_Types.Unsigned;
      S : in out String;
      P : out Natural)
   is
      pragma Assert (S'First = 1);
      pragma Assert (S'Last > 1);
   begin
      S (1) := ' ';
      P := 1;
      Set_Image (V, S, P);
      pragma Assert (P < S'Last);
   end Image;
   
   function Image (V : System.Unsigned_Types.Unsigned) return String
   is
      Ss : String (1 .. 64);
      Pp : Natural;
   begin
      Image (V, Ss, Pp); 
      return Ss (1 .. Pp);
   end Image;
   
   ------------------------
   -- Set_Image_Unsigned --
   ------------------------

   procedure Set_Image
     (V : Unsigned;
      S : in out String;
      P : in out Natural)
   is
      procedure Set_Digits (T : Unsigned);
      --  Set decimal digits of value of T

      ----------------
      -- Set_Digits --
      ----------------

      procedure Set_Digits (T : Unsigned) is
      begin
         if T >= 10 then
            Set_Digits (T / 10);
            P := P + 1;
            pragma assert (p < s'last);
            S (P) := Character'Val (48 + (T rem 10));

         else
            P := P + 1;
            pragma assert (p < s'last);
            S (P) := Character'Val (48 + T);
         end if;
      end Set_Digits;

   --  Start of processing for Set_Image_Unsigned

   begin
      Set_Digits (V);
   end Set_Image;

end Img_Uns;
