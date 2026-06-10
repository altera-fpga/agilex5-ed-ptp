//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


package components_pkg;
   function automatic int get_width(int value);
      return (value >= 2) ? $clog2(value) : 1;
   endfunction
endpackage