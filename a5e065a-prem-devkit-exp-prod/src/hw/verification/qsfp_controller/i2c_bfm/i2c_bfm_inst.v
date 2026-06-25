	i2c_bfm u0 (
		.clk           (_connected_to_clk_),           //   input,   width = 1,         clock.clk
		.address       (_connected_to_address_),       //  output,  width = 32, avalon_master.address
		.read          (_connected_to_read_),          //  output,   width = 1,              .read
		.readdata      (_connected_to_readdata_),      //   input,  width = 32,              .readdata
		.readdatavalid (_connected_to_readdatavalid_), //   input,   width = 1,              .readdatavalid
		.waitrequest   (_connected_to_waitrequest_),   //   input,   width = 1,              .waitrequest
		.write         (_connected_to_write_),         //  output,   width = 1,              .write
		.byteenable    (_connected_to_byteenable_),    //  output,   width = 4,              .byteenable
		.writedata     (_connected_to_writedata_),     //  output,  width = 32,              .writedata
		.rst_n         (_connected_to_rst_n_),         //   input,   width = 1,         reset.reset_n
		.i2c_data_in   (_connected_to_i2c_data_in_),   //   input,   width = 1,   conduit_end.conduit_data_in
		.i2c_clk_in    (_connected_to_i2c_clk_in_),    //   input,   width = 1,              .conduit_clk_in
		.i2c_data_oe   (_connected_to_i2c_data_oe_),   //  output,   width = 1,              .conduit_data_oe
		.i2c_clk_oe    (_connected_to_i2c_clk_oe_)     //  output,   width = 1,              .conduit_clk_oe
	);

