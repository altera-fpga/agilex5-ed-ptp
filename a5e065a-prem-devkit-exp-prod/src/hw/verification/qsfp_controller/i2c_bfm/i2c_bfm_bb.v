module i2c_bfm (
		input  wire        clk,           //         clock.clk
		output wire [31:0] address,       // avalon_master.address
		output wire        read,          //              .read
		input  wire [31:0] readdata,      //              .readdata
		input  wire        readdatavalid, //              .readdatavalid
		input  wire        waitrequest,   //              .waitrequest
		output wire        write,         //              .write
		output wire [3:0]  byteenable,    //              .byteenable
		output wire [31:0] writedata,     //              .writedata
		input  wire        rst_n,         //         reset.reset_n
		input  wire        i2c_data_in,   //   conduit_end.conduit_data_in
		input  wire        i2c_clk_in,    //              .conduit_clk_in
		output wire        i2c_data_oe,   //              .conduit_data_oe
		output wire        i2c_clk_oe     //              .conduit_clk_oe
	);
endmodule

