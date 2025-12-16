//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//--------------------------------------------------------------------------------------------
// Description: ipbb_rrarb
// 
// - Provide a basic round robin arbitration.
// 
//--------------------------------------------------------------------------------------------

//`default_nettype none
module ipbb_rrarb 
  #(parameter N=2
             ,PRIORITY_RR_EN = 0
             ,N_WIDTH = (N<2) ? 1 : $clog2(N)) 
   (
    input var logic             clk,
    input var logic             reset,

    input var logic [N-1:0]     req,
    input var logic             en,

    output logic [N_WIDTH -1:0] gnt_id,
    output logic                gnt_id_vld,
    output logic [N_WIDTH -1:0] nxt_gnt_id,
    output logic                nxt_gnt_id_vld
);

   localparam inputs = N;

   logic [N-1:0] cur_gnt, gnt, nxt_gnt;

   assign gnt = en ? nxt_grant (cur_gnt, req) : '0;
   assign nxt_gnt = nxt_grant (cur_gnt, req) ;

   always_comb begin
      gnt_id_vld     = |gnt;
      nxt_gnt_id_vld = |nxt_gnt;      
   end
   
   always @ (posedge clk) begin
      if ( reset ) 
	cur_gnt <= '0;
      else if ( en )
	cur_gnt <= nxt_gnt;
   end

   generate
      if (N == 2) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 default:     nxt_gnt_id = '0;
	       endcase // case (1)
	    end	 
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 2)

      else if (N == 3) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 default:     nxt_gnt_id = '0;
	       endcase 
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)	 
      end // if (N == 3)
            
      else if (N == 4) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 default:     nxt_gnt_id = '0;
	       endcase
	    end
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 4)
      
      
      else if (N == 5) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 default:     nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 5)

      else if (N == 6) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
	 
      end // if (N == 6)
      
      else if (N == 7) begin	 
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 default: nxt_gnt_id = '0;
	       endcase 
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 7)

      else if (N == 8) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 8)

      else if (N == 9) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 9)

      else if (N == 10) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 default: gnt_id = '0;
	       endcase // case (1)

	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 10)
      
      else if (N == 11) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 11)

      else if (N == 12) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 12)
      
      else if (N == 13) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 13)

      else if (N == 14) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 14)

      else if (N == 15) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 default: nxt_gnt_id = '0;
	       endcase 
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 15)

      else if (N == 16) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 16)

      else if (N == 17) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 17)

      else if (N == 18) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 18)

      else if (N == 19) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 19)

      else if (N == 20) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 20)

      else if (N == 21) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 21)

      else if (N == 22) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 22)

      else if (N == 23) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 23)

      else if (N == 24) begin
	  if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 24)

      else if (N == 25) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 req[24]: gnt_id = 'd24;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 gnt[24]:  gnt_id = 'd24;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 nxt_gnt[24]:  nxt_gnt_id = 'd24;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 25)

      else if (N == 26) begin
	  if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 req[24]: gnt_id = 'd24;
		 req[25]: gnt_id = 'd25;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 gnt[24]:  gnt_id = 'd24;
		 gnt[25]:  gnt_id = 'd25;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 nxt_gnt[24]:  nxt_gnt_id = 'd24;
		 nxt_gnt[25]:  nxt_gnt_id = 'd25;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 26)

      else if (N == 27) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 req[24]: gnt_id = 'd24;
		 req[25]: gnt_id = 'd25;
		 req[26]: gnt_id = 'd26;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 gnt[24]:  gnt_id = 'd24;
		 gnt[25]:  gnt_id = 'd25;
		 gnt[26]:  gnt_id = 'd26;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 nxt_gnt[24]:  nxt_gnt_id = 'd24;
		 nxt_gnt[25]:  nxt_gnt_id = 'd25;
		 nxt_gnt[26]:  nxt_gnt_id = 'd26;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 27)

      else if (N == 28) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 req[24]: gnt_id = 'd24;
		 req[25]: gnt_id = 'd25;
		 req[26]: gnt_id = 'd26;
		 req[27]: gnt_id = 'd27;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 gnt[24]:  gnt_id = 'd24;
		 gnt[25]:  gnt_id = 'd25;
		 gnt[26]:  gnt_id = 'd26;
		 gnt[27]:  gnt_id = 'd27;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 nxt_gnt[24]:  nxt_gnt_id = 'd24;
		 nxt_gnt[25]:  nxt_gnt_id = 'd25;
		 nxt_gnt[26]:  nxt_gnt_id = 'd26;
		 nxt_gnt[27]:  nxt_gnt_id = 'd27;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 28)

      else if (N == 29) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 req[24]: gnt_id = 'd24;
		 req[25]: gnt_id = 'd25;
		 req[26]: gnt_id = 'd26;
		 req[27]: gnt_id = 'd27;
		 req[28]: gnt_id = 'd28;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 gnt[24]:  gnt_id = 'd24;
		 gnt[25]:  gnt_id = 'd25;
		 gnt[26]:  gnt_id = 'd26;
		 gnt[27]:  gnt_id = 'd27;
		 gnt[28]:  gnt_id = 'd28;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 nxt_gnt[24]:  nxt_gnt_id = 'd24;
		 nxt_gnt[25]:  nxt_gnt_id = 'd25;
		 nxt_gnt[26]:  nxt_gnt_id = 'd26;
		 nxt_gnt[27]:  nxt_gnt_id = 'd27;
	      nxt_gnt[28]:  nxt_gnt_id = 'd28;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 29)

      else if (N == 30) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 req[24]: gnt_id = 'd24;
		 req[25]: gnt_id = 'd25;
		 req[26]: gnt_id = 'd26;
		 req[27]: gnt_id = 'd27;
		 req[28]: gnt_id = 'd28;
		 req[29]: gnt_id = 'd29;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 gnt[24]:  gnt_id = 'd24;
		 gnt[25]:  gnt_id = 'd25;
		 gnt[26]:  gnt_id = 'd26;
		 gnt[27]:  gnt_id = 'd27;
		 gnt[28]:  gnt_id = 'd28;
		 gnt[29]:  gnt_id = 'd29;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 nxt_gnt[24]:  nxt_gnt_id = 'd24;
		 nxt_gnt[25]:  nxt_gnt_id = 'd25;
		 nxt_gnt[26]:  nxt_gnt_id = 'd26;
		 nxt_gnt[27]:  nxt_gnt_id = 'd27;
		 nxt_gnt[28]:  nxt_gnt_id = 'd28;
		 nxt_gnt[29]:  nxt_gnt_id = 'd29;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 30)

      else if (N == 31) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 req[24]: gnt_id = 'd24;
		 req[25]: gnt_id = 'd25;
		 req[26]: gnt_id = 'd26;
		 req[27]: gnt_id = 'd27;
		 req[28]: gnt_id = 'd28;
		 req[29]: gnt_id = 'd29;
		 req[30]: gnt_id = 'd30;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 gnt[24]:  gnt_id = 'd24;
		 gnt[25]:  gnt_id = 'd25;
		 gnt[26]:  gnt_id = 'd26;
		 gnt[27]:  gnt_id = 'd27;
		 gnt[28]:  gnt_id = 'd28;
		 gnt[29]:  gnt_id = 'd29;
		 gnt[30]:  gnt_id = 'd30;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 nxt_gnt[24]:  nxt_gnt_id = 'd24;
		 nxt_gnt[25]:  nxt_gnt_id = 'd25;
		 nxt_gnt[26]:  nxt_gnt_id = 'd26;
		 nxt_gnt[27]:  nxt_gnt_id = 'd27;
		 nxt_gnt[28]:  nxt_gnt_id = 'd28;
		 nxt_gnt[29]:  nxt_gnt_id = 'd29;
		 nxt_gnt[30]:  nxt_gnt_id = 'd30;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 31)
      
      else if (N == 32) begin
	 if (PRIORITY_RR_EN == 1) begin
	    always_comb begin
	       case (1)
		 req[0]: gnt_id = 'h0;
		 req[1]: gnt_id = 'h1;
		 req[2]: gnt_id = 'h2;
		 req[3]: gnt_id = 'h3;
		 req[4]: gnt_id = 'h4;
		 req[5]: gnt_id = 'h5;
		 req[6]: gnt_id = 'h6;
		 req[7]: gnt_id = 'h7;
		 req[8]: gnt_id = 'h8;
		 req[9]: gnt_id = 'h9;
		 req[10]: gnt_id = 'd10;
		 req[11]: gnt_id = 'd11;
		 req[12]: gnt_id = 'd12;
		 req[13]: gnt_id = 'd13;
		 req[14]: gnt_id = 'd14;
		 req[15]: gnt_id = 'd15;
		 req[16]: gnt_id = 'd16;
		 req[17]: gnt_id = 'd17;
		 req[18]: gnt_id = 'd18;
		 req[19]: gnt_id = 'd19;
		 req[20]: gnt_id = 'd20;
		 req[21]: gnt_id = 'd21;
		 req[22]: gnt_id = 'd22;
		 req[23]: gnt_id = 'd23;
		 req[24]: gnt_id = 'd24;
		 req[25]: gnt_id = 'd25;
		 req[26]: gnt_id = 'd26;
		 req[27]: gnt_id = 'd27;
		 req[28]: gnt_id = 'd28;
		 req[29]: gnt_id = 'd29;
		 req[30]: gnt_id = 'd30;
		 req[31]: gnt_id = 'd31;
		 default: gnt_id = 'h0;
	       endcase
	       nxt_gnt_id = gnt_id;
	    end
	 end // if (PRIORITY_RR_EN == 1)
	 
	 else begin
	    always_comb begin
	       case (1)
		 gnt[0]:  gnt_id = '0;
		 gnt[1]:  gnt_id = 'd1;
		 gnt[2]:  gnt_id = 'd2;
		 gnt[3]:  gnt_id = 'd3;
		 gnt[4]:  gnt_id = 'd4;
		 gnt[5]:  gnt_id = 'd5;
		 gnt[6]:  gnt_id = 'd6;
		 gnt[7]:  gnt_id = 'd7;
		 gnt[8]:  gnt_id = 'd8;
		 gnt[9]:  gnt_id = 'd9;
		 gnt[10]:  gnt_id = 'd10;
		 gnt[11]:  gnt_id = 'd11;
		 gnt[12]:  gnt_id = 'd12;
		 gnt[13]:  gnt_id = 'd13;
		 gnt[14]:  gnt_id = 'd14;
		 gnt[15]:  gnt_id = 'd15;
		 gnt[16]:  gnt_id = 'd16;
		 gnt[17]:  gnt_id = 'd17;
		 gnt[18]:  gnt_id = 'd18;
		 gnt[19]:  gnt_id = 'd19;
		 gnt[20]:  gnt_id = 'd20;
		 gnt[21]:  gnt_id = 'd21;
		 gnt[22]:  gnt_id = 'd22;
		 gnt[23]:  gnt_id = 'd23;
		 gnt[24]:  gnt_id = 'd24;
		 gnt[25]:  gnt_id = 'd25;
		 gnt[26]:  gnt_id = 'd26;
		 gnt[27]:  gnt_id = 'd27;
		 gnt[28]:  gnt_id = 'd28;
		 gnt[29]:  gnt_id = 'd29;
		 gnt[30]:  gnt_id = 'd30;
		 gnt[31]:  gnt_id = 'd31;
		 default: gnt_id = '0;
	       endcase // case (1)
	       
	       case (1)
		 nxt_gnt[0]:  nxt_gnt_id = '0;
		 nxt_gnt[1]:  nxt_gnt_id = 'd1;
		 nxt_gnt[2]:  nxt_gnt_id = 'd2;
		 nxt_gnt[3]:  nxt_gnt_id = 'd3;
		 nxt_gnt[4]:  nxt_gnt_id = 'd4;
		 nxt_gnt[5]:  nxt_gnt_id = 'd5;
		 nxt_gnt[6]:  nxt_gnt_id = 'd6;
		 nxt_gnt[7]:  nxt_gnt_id = 'd7;
		 nxt_gnt[8]:  nxt_gnt_id = 'd8;
		 nxt_gnt[9]:  nxt_gnt_id = 'd9;
		 nxt_gnt[10]:  nxt_gnt_id = 'd10;
		 nxt_gnt[11]:  nxt_gnt_id = 'd11;
		 nxt_gnt[12]:  nxt_gnt_id = 'd12;
		 nxt_gnt[13]:  nxt_gnt_id = 'd13;
		 nxt_gnt[14]:  nxt_gnt_id = 'd14;
		 nxt_gnt[15]:  nxt_gnt_id = 'd15;
		 nxt_gnt[16]:  nxt_gnt_id = 'd16;
		 nxt_gnt[17]:  nxt_gnt_id = 'd17;
		 nxt_gnt[18]:  nxt_gnt_id = 'd18;
		 nxt_gnt[19]:  nxt_gnt_id = 'd19;
		 nxt_gnt[20]:  nxt_gnt_id = 'd20;
		 nxt_gnt[21]:  nxt_gnt_id = 'd21;
		 nxt_gnt[22]:  nxt_gnt_id = 'd22;
		 nxt_gnt[23]:  nxt_gnt_id = 'd23;
		 nxt_gnt[24]:  nxt_gnt_id = 'd24;
		 nxt_gnt[25]:  nxt_gnt_id = 'd25;
		 nxt_gnt[26]:  nxt_gnt_id = 'd26;
		 nxt_gnt[27]:  nxt_gnt_id = 'd27;
		 nxt_gnt[28]:  nxt_gnt_id = 'd28;
		 nxt_gnt[29]:  nxt_gnt_id = 'd29;
		 nxt_gnt[30]:  nxt_gnt_id = 'd30;
		 nxt_gnt[31]:  nxt_gnt_id = 'd31;
		 default: nxt_gnt_id = '0;
	       endcase
	    end // always_comb
	 end // else: !if(PRIORITY_RR_EN == 1)
      end // if (N == 32)
      
      else begin
	 always_comb begin
	    gnt_id = '0;
	    nxt_gnt_id = '0;
	 end
      end // else: !if(N == 16)
   endgenerate
   
      
   function [inputs-1:0] nxt_grant;
      input [inputs-1:0] cur_grant;
      input [inputs-1:0] cur_req;
      
      reg [inputs-1:0] 	 msk_req;
      reg [inputs-1:0] 	 tmp_grant;
      
      begin
	 msk_req = cur_req & ~((cur_grant - 1) | cur_grant);
	 tmp_grant = msk_req & (~msk_req + 1);
	 
	 if (msk_req != 0)
	   nxt_grant = tmp_grant;
	 else
	   nxt_grant = cur_req & (~cur_req + 1);
      end
   endfunction
   
endmodule

