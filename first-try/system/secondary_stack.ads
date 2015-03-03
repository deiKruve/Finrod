with System;

package Secondary_Stack is

   function Get_Sec_Stack return System.Address;
   pragma Export (C, Get_Sec_Stack, "__gnat_get_secondary_stack");

end Secondary_Stack;
