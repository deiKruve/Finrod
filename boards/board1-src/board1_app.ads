------------------------------------------------------------------------------
--                                                                          --
--                           Gmac Plc COMPONENTS                            --
--                                                                          --
--                           B O A R D 1 _ A P P                            --
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
--               Gmac Plc is maintained by J de Kruijf Engineers            --
--                     (email: jan.de.kruyf@hotmail.com)                    --
--                                                                          --
------------------------------------------------------------------------------
--
-- this is a first try at an application for an STM32 board, controlled by 
-- the Finrod fieldbus structure and mini polling os

package Board1_App is
   
   procedure Init;
   -- initializes the application,
   -- it is normally only used internally. 
   -- it is called via an uplink, that is initialized in the application body,
   -- from the finrod library
   
end Board1_App;
