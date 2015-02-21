pragma Ada_2005;
with System.Storage_Elements; use System.Storage_Elements;
with Ada.Text_IO; use Ada.Text_IO;

procedure Endianness_Demo_GPL2012 is

   -------------------------
   -- Common declarations --
   -------------------------

   subtype Yr_Type is Natural range 0 .. 127;
   subtype Mo_Type is Natural range 1 .. 12;
   subtype Da_Type is Natural range 1 .. 31;

   type Date is record 
      Years_Since_1980 : Yr_Type;
      Month            : Mo_Type;
      Day_Of_Month     : Da_Type;
   end record;

   for Date use record
      Years_Since_1980 at 0 range 0  ..  6;
      Month            at 0 range 7  .. 10;
      Day_Of_Month     at 0 range 11 .. 15;
   end record;

   ------------------------------------------------------------
   -- Derived types with different representation attributes --
   ------------------------------------------------------------

   --  Bit order only

   type Date_LE_Bits is new Date;
   for Date_LE_Bits'Bit_Order use System.Low_Order_First;

   type Date_BE_Bits is new Date;
   for Date_BE_Bits'Bit_Order use System.High_Order_First;

   --  Bit order and scalar storage order (note: if the latter is specified,
   --  it must be consistent with the former).

   type Date_LE is new Date;
   for Date_LE'Bit_Order use System.Low_Order_First;
   for Date_LE'Scalar_Storage_Order use System.Low_Order_First;

   type Date_BE is new Date;
   for Date_BE'Bit_Order use System.High_Order_First;
   for Date_BE'Scalar_Storage_Order use System.High_Order_First;

   ----------------------------
   -- Show bits at address A --
   ----------------------------

   procedure Show (A : System.Address) is
      Arr : Storage_Array (1 .. 2);
      for Arr'Address use A;
      pragma Import (Ada, Arr);
   begin
      for J in Arr'Range loop
         Put (Arr (J)'Img);
      end loop;
      New_Line;
   end Show;

   D_N  : Date    := (32, 12, 12);
   --  Native storage (no attribute specified)

   D_LE_Bits : Date_LE_Bits := (32, 12, 12);
   D_BE_Bits : Date_BE_Bits := (32, 12, 12);

   D_LE : Date_LE;
   D_BE : Date_BE;

begin
   Put_Line ("Default bit order: " & System.Default_Bit_Order'Img);

   Put ("N      :"); Show (D_N 'Address);

   Put ("LE_Bits:"); Show (D_LE_Bits'Address);
   Put ("BE_Bits:"); Show (D_BE_Bits'Address);

   --  Note: in GNAT GPL 2012, intialization of a non-default-endianness
   --  record from an aggregate of whole-record assignment is not done
   --  correctly, so perform per-component assignments here. This has
   --  been fixed in GNAT Pro 7.1 and the fix will also be in GNAT GPL 2013.

   D_LE.Years_Since_1980 := 32;
   D_LE.Month            := 12;
   D_LE.Day_Of_Month     := 12;

   D_BE.Years_Since_1980 := 32;
   D_BE.Month            := 12;
   D_BE.Day_Of_Month     := 12;

   Put ("LE:     "); Show (D_LE'Address);
   Put ("BE:     "); Show (D_BE'Address);
end Endianness_Demo_GPL2012;
