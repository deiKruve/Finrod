with System;

package Environment_Stack is

   --------------
   --  STACKS  --
   --------------

   Stack_Area_Size : constant Integer := 10 * 1024; --  bytes

   type Stack_Element is new Natural;
   for Stack_Element'Size use 64;
   --  The elements in the stack must be 64 bits wide to allow double
   --  word data movements

   subtype Range_Of_Stack is Natural range
     1 .. (Stack_Area_Size / (Stack_Element'Size / 8) + 1);

   type Stack_Space is array (Range_Of_Stack) of Stack_Element;
   --  The total space for stacks is equal to the Stack_Area_Size defined
   --  in Kernel.Parameters (in bytes), rounded to the upper 8 bytes bound.

   Stack : Stack_Space;
   for Stack'Alignment use Standard'Maximum_Alignment;

   Environment_Stack : constant System.Address :=
     Stack (Range_Of_Stack'Last)'Address;
   pragma Export (Asm, Environment_Stack, "environment_stack");
   --  Environment_Stack points to the top of the stack reserved for the
   --  environment task. This constant is used by "ada_crt0.S" to set the
   --  stack pointer during initialization.
end Environment_Stack;
