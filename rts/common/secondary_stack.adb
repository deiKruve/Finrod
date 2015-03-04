--  Avoid the warning for using an internal unit.
pragma Warnings (Off);
with System.Secondary_Stack;
pragma Warnings (On);

with System.Storage_Elements;

package body Secondary_Stack is

   package SSS renames System.Secondary_Stack;
   package SSE renames System.Storage_Elements;

   Default_Size : constant := 10 * 1_024;

   Chunk : array (1 .. Default_Size) of
      SSE.Storage_Element;

   Uninitialized : Boolean := True;

   function Get_Sec_Stack return System.Address is
   begin
      if Uninitialized then
         Uninitialized := False;
         SSS.SS_Init (Chunk'Address, Default_Size);
      end if;
      return Chunk'Address;
   end Get_Sec_Stack;

end Secondary_Stack;
