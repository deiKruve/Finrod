--
with System.BB.Parameters;

package System.BB.Interrupts is
   pragma Preelaborate;

   Max_Interrupt : constant := System.BB.Parameters.Number_Of_Interrupt_ID;
   --  Number of interrupts

   subtype Interrupt_ID is Natural range 0 .. Max_Interrupt;
   --  Interrupt identifier

   No_Interrupt : constant Interrupt_ID := 0;
   --  Special value indicating no interrupt

end System.BB.Interrupts;
