`timescale 1ns/1ns

// This is the top level module which instantiates the fos_control demo
// which will interface with linux and allow the user to experiment with
// tuning the control loop's parameters.



module DC2390_multi_application (

    input clk,                              //input OSC_50_B3B, // Original name...
    input adc_clk,
    input [3:0] KEY ,								// Keys are normally high, low when pressed
    output [3:0] LED,                        // HIGH to turn ON

    // ///////// DDR3 /////////
    output [14:0] fpga_memory_mem_a,          // fpga_memory.mem_a
    output [2:0] fpga_memory_mem_ba,          //            .mem_ba
    output fpga_memory_mem_ck,                //            .mem_ck
    output fpga_memory_mem_ck_n,              //            .mem_ck_n
    output fpga_memory_mem_cke,               //            .mem_cke
    output fpga_memory_mem_cs_n,              //            .mem_cs_n
    output [3:0] fpga_memory_mem_dm,          //            .mem_dm
    output fpga_memory_mem_ras_n,             //            .mem_ras_n
    output fpga_memory_mem_cas_n,             //            .mem_cas_n
    output fpga_memory_mem_we_n,              //            .mem_we_n
    output fpga_memory_mem_reset_n,           //            .mem_reset_n
    inout [31:0] fpga_memory_mem_dq,          //            .mem_dq
    inout [3:0] fpga_memory_mem_dqs,          //            .mem_dqs
    inout [3:0] fpga_memory_mem_dqs_n,        //            .mem_dqs_n
    output fpga_memory_mem_odt,               //            .mem_odt
    input oct_rzqin,                          //         oct.rzqin

    // ///////// HPS /////////
    output [14:0] hps_memory_mem_a,
    output [2:0]  hps_memory_mem_ba,
    output        hps_memory_mem_ck,
    output        hps_memory_mem_ck_n,
    output        hps_memory_mem_cke,
    output        hps_memory_mem_cs_n,
    output        hps_memory_mem_ras_n,
    output        hps_memory_mem_cas_n,
    output        hps_memory_mem_we_n,
    output        hps_memory_mem_reset_n,
    inout  [31:0] hps_memory_mem_dq,
    inout  [4:0]  hps_memory_mem_dqs,
    inout  [4:0]  hps_memory_mem_dqs_n,
    output        hps_memory_mem_odt,
    output [4:0]  hps_memory_mem_dm,
    input         hps_memory_oct_rzqin,

    ////// DACs ////////////
    output              [15:0]  DAC_A,
    output              [15:0]  DAC_B,

    /////// ADCs //////////

    // LTC2500 ADCs
    output pre_u1,
    output mclk_u1,
    output sync_u1,
    input busy_u1,
    input drdyl_u1,
    output rdl_u1,
    output sclk_u1,
    input sdo_u1,
    output rdl_filt_u1,
    output sclk_filt_u1,
    input sdo_filt_u1,
    output sdi_filt_u1,

    output pre_u2,
    output mclk_u2,
    output sync_u2,
    input busy_u2,
    input drdyl_u2,
    output rdl_u2,
    output sclk_u2,
    input sdo_u2,
    output rdl_filt_u2,
    output sclk_filt_u2,
    input sdo_filt_u2,
    output sdi_filt_u2,

    // SPI port for LTC6954
    output ltc6954_sync,
    output ltc6954_cs,
    output ltc6954_sck,
    output ltc6954_sdi,
    input ltc6954_sdo,

    output gpo0, // HSMC LVDS RX_p15 (FPGA pin F13)
    output gpo1  // HSMC LVDS RX_p14 (FPGA pin H14)
   );

parameter FPGA_TYPE = 16'hABCD; // FPGA project type identification. Accessible from register map.
parameter FPGA_REV = 16'h1237;  // FPGA revision (also accessible from register.)

    wire reset;
    wire [31:0] mem_ctrl_addr;
    wire mem_ctrl_go;
    wire [31:0] mem_ctrl_data;
    wire mem_ctrl_ready;

// Wires to/from Qsys blob
    wire [31:0] std_ctrl_wire;
    wire [15:0] pid_kp, pid_ki, pid_kd;
    wire [31:0] pulse_low, pulse_high;
    wire [19:0] pulse_val;
    wire [15:0] fos_tau, fos_gain;
//    wire [23:0] fos_clocks_per_sample;
    wire [23:0] system_clocks_per_sample;
    wire [29:0] num_samples;
    wire [31:0] tuning_word;
    wire [31:0] stop_address;
    wire [31:0] datapath_control;


    wire start;
    wire data_ready;
    wire mem_adcA_nadcB;
    wire [19:0]adcA_data;
    wire [19:0]adcB_data;

    wire [3:0] LEDwire;

    wire [13:0] n; // For LTC2378-24, number of samples to average
    wire [19:0] control_sys_output;
    wire adcA_done, adc_B_done;
    reg adc_go; // Trigger to ADC controller

    assign LED[3:0] = LEDwire[3:0];
    assign fos_clocks_per_sample = 24'd4; // Hard coded, used to be controllable by register.
    assign reset = !KEY[0];
    wire [1:0] dac_a_select, dac_b_select, lut_addr_select;

    //assign LEDwire[3] = data_ready;
	 assign LEDwire[3] = start;
	 assign LEDwire[2] = ~delayed_trig;
	 
	 wire en_trig, delayed_trig, lut_run_once, lut_write_enable;

    wire [15:0] lut_output; // Output of DAC lookup table
    wire [15:0] lut_addr_counter; // Coutnter for sequencing through LUT memory
    wire [15:0] lut_addr; // Input to lookup table address

	 wire [15:0] lut_wraddress;
    wire [15:0] lut_wrdata;
	 
    wire [15:0] nco_sin_out;
    wire [15:0] nco_cos_out;


    wire [15:0]dac_a_data_signed;
    wire [15:0]dac_b_data_signed;
    reg [15:0]dac_a_data_straight;
    reg [15:0]dac_b_data_straight;

    assign DAC_A = dac_a_data_straight;
    assign DAC_B = dac_b_data_straight;


	 
     // DAC data signals and control
    always @ (posedge adc_clk) begin
        //dac_data= pid_output [15:0] ^ 16'h8000;
        //dac_data= sys_in [15:0] ^ 16'h8000;
        dac_a_data_straight <= {~dac_a_data_signed[15], dac_a_data_signed[14:0]};
        dac_b_data_straight <= {~dac_b_data_signed[15], dac_b_data_signed[14:0]};
    end


mux_4to1_16 mux_4to1_16_DAC_A_inst (
	.clock ( adc_clk ),
	.data0x ( nco_sin_out ),
	.data1x ( pid_output ),
	.data2x ( 16'h4000 ),
	.data3x ( 16'hC000 ),
	.sel ( dac_a_select ),
	.result ( dac_a_data_signed )
	);
    
mux_4to1_16 mux_4to1_16_DAC_B_inst (
	.clock ( adc_clk ),
	.data0x ( nco_cos_out ),
	.data1x ( lut_output ),
	.data2x ( 16'hC000 ),
	.data3x ( 16'h4000 ),
	.sel ( dac_b_select ),
	.result ( dac_b_data_signed )
	);
//wire lut_count_carry;
//wire lut_count_enable;
//assign  lut_count_enable = ~lut_count_carry | ~lut_run_once | start_pulse;



    //create single trigger pulse from force_trig's posedge
    reg old_trig;
	 wire trig_pulse;
    assign trig_pulse = force_trig & ~old_trig;
    always @ (posedge adc_clk) begin
        old_trig <= force_trig;
    end


// Counter to sequence through LUT. Consider regenerating with a reset.
upcount_mem_addr  upcount_mem_addr_lut_addr_inst (
    .clock ( adc_clk ), // Run once on start pulse, override with lut_run_once = 0 (default)
    .cnt_en ( ~lut_count_carry | ~lut_run_once | trig_pulse ),
    .sclr ( 1'b0 ),
	 .cout ( lut_count_carry ),
    .q ( lut_addr_counter )
    );


// lookup table address mux
mux_4to1_16 mux_4to1_16_lut_addr_inst (
	.clock ( adc_clk ),
	.data0x ( lut_addr_counter ), // This is for pattern, pulse generation
	.data1x ( dac_a_data_signed ), // This is for distortion correction
	.data2x ( 16'h4000 ),
	.data3x ( 16'hC000 ),
	.sel ( lut_addr_select ),
	.result ( lut_addr )
	);
// Lookup table (16x16)
ram_lut	ram_lut_inst (
	.data ( lut_wrdata ),
	.rdaddress ( lut_addr ),
	.rdclock ( adc_clk ),
	.wraddress ( lut_wraddress ),
	.wrclock ( clk ),
	.wren ( lut_write_enable ), // High to enable writing
	.q ( lut_output )
	);



    //step generator
    wire [19:0] setpoint;
    pulse_gen #(.OUTPUT_WIDTH(20)) step (
        .clk(adc_clk),
        .reset(reset),
        .trig(trig_pulse),
        .low_period(pulse_low),
        .high_period(pulse_high),
        .value(pulse_val),
        .out(setpoint)
    );

    // NCO set up with data width of 18 to try to trick it into overkill ;)
	nco_iq_14_1 nco_iq_14_1_inst (
		.clk       (adc_clk),       // clk.clk
		.reset_n   (1'b1),   // rst.reset_n
		.clken     (1'b1),     //  in.clken
		.phi_inc_i (tuning_word), //    .phi_inc_i
		.fsin_o    ({nco_sin_out[15:0], 2'bzz}),    // Snag 16 MS bits...
		.fcos_o    ({nco_cos_out[15:0], 2'bzz}),    //
		.out_valid (1'bz)  //    .out_valid
	);

    //PID controller
//    wire [19:0] feedback;
    wire [15:0] pid_output;
    wire pid_done;
    wire adc_done;
    pid #(
        .INPUT_WIDTH(20),
        .OUTPUT_WIDTH(16),
        .PID_PARAM_WIDTH(16),
        .PID_PARAM_FP_PRECISION(8), //fixed point decimal places (must be <= PID_PARAM_WIDTH-1)
        .MAX_OVF_SUM(4) //overflow bits for err_sum
    ) ctrl (
        .clk(adc_clk),
        .reset(reset),
        //PID settings
        .kp(pid_kp), //signed binary fixed point
        .ki(pid_ki), //signed binary fixed point
        .kd(pid_kd), //signed binary fixed point
        .setpoint(setpoint), //signed integer
        //PID signals
        .feedback(adcA_data), //signed integer
        .sig_out(pid_output), //signed integer
        .trig(adcA_done), //triggers new calculation (1 clock pulse)
        .done(pid_done) //signals new valid data on output (1 clock pulse)
    );

LTC2500_controller LTC2500_u1(
    .clk(adc_clk),
    . reset(reset),
    // client <-> controller
    . go(adc_go), //initiate conversion (single clock pulse)
    . sync_request(1'b0), // Used to force a hard sync, for multiple devices.
    .cfg_word(12'b0), // Filter configuration
    .n(16'd8), // Number of samples to average minus 1 **** Variable SINC mode only
    .pre_in(1'b0), //
    .done(adcA_done), //signal end of conversion and valid output data (single clock pulse)
    .data(adcA_data), //converted data
    .done_filt(),
    .data_filt(),
    .error(),
    // controller <-> adc
    .pre(pre_u1),
    .mclk(mclk_u1),
    .sync(sync_u1),
    .busy(busy_u1),
    .drdyl(drdyl_u1),
    .rdl(rdl_u1),
    .sclk(sclk_u1), // For the time being, let's grab data on both inputs
    .sdo(sdo_u1),   // (need to update model with both ports)
    .rdl_filt(rdl_filt_u1),
    .sclk_filt(sclk_filt_u1),
    .sdo_filt(sdo_filt_u1),
    .sdi_filt(sdi_filt_u1)
    );

LTC2500_controller LTC2500_u2(
    .clk(adc_clk),
    . reset(reset),
    // client <-> controller
    . go(adc_go), //initiate conversion (single clock pulse)
    . sync_request(1'b0), // Used to force a hard sync, for multiple devices.
    .cfg_word(12'b0), // Filter configuration
    .n(16'd8), // Number of samples to average minus 1 **** Variable SINC mode only
    .pre_in(1'b0), //
    .done(adcB_done), //signal end of conversion and valid output data (single clock pulse)
    .data(adcB_data), //converted data
    .done_filt(),
    .data_filt(),
    .error(),
    // controller <-> adc
    .pre(pre_u2),
    .mclk(mclk_u2),
    .sync(sync_u2),
    .busy(busy_u2),
    .drdyl(drdyl_u2),
    .rdl(rdl_u2),
    .sclk(sclk_u2), // For the time being, let's grab data on both inputs
    .sdo(sdo_u2),   // (need to update model with both ports)
    .rdl_filt(rdl_filt_u2),
    .sclk_filt(sclk_filt_u2),
    .sdo_filt(sdo_filt_u2),
    .sdi_filt(sdi_filt_u2)
    );



    //create single clock pulse from start's posedge
    reg old_start;
	 wire start_pulse;
    assign start_pulse = start & ~old_start;
    always @ (posedge adc_clk) begin
        old_start <= start;
    end

    //generate inhibit signal to run only once
    reg inhibit;
//    assign data_ready = inhibit; // IMPORTANT!! Commented out, connected signal to Noe's controller
    reg [29:0] num_calculated;
//    assign sample_num = num_calculated;
     assign mem_ctrl_addr[31:2] = num_calculated;
    always @ (posedge adc_clk) begin
        if (reset) begin
            inhibit <= 1'b1;
            num_calculated <= 30'd0;
        end else begin
            if (start_pulse) begin
                inhibit <= 1'b0;
                num_calculated <= 30'd0;
            end else if (num_calculated == num_samples) begin
                inhibit <= 1'b1;
                num_calculated <= num_calculated;
            end else if (inhibit) begin
                inhibit <= 1'b1;
                num_calculated <= num_calculated;
            end else if (adcA_done) begin
                inhibit <= 1'b0;
                num_calculated <= num_calculated + 30'd1;
            end else begin
                inhibit <= 1'b0;
                num_calculated <= num_calculated;
            end
        end
    end

    //trigger the step pulse
//    assign pulse_trig = start_pulse;




// Sample rate generator, move to separate module...
     reg[23:0] counter;
    always @ (posedge adc_clk or posedge reset) begin
        if (reset) begin
            counter <= system_clocks_per_sample;
            adc_go <= 1'b0;
        end else begin
              if (counter == 24'b0) begin
                counter <= system_clocks_per_sample;
                    adc_go <= 1'b1;
              end else begin
                  counter <= counter - 24'b1;
                adc_go <= 1'b0;
              end
        end
     end



wire [15:0] countup;
wire [15:0] countdown;

updown_count16  updown_count16_inst1 (
    .clock ( adc_clk ),
    .cnt_en ( adc_go ),
    .updown ( 0 ), // Zero for down
    .q ( countdown )
    );

updown_count16  updown_count16_inst2 (
    .clock ( adc_clk ),
    .cnt_en ( adc_go ),
    .updown ( 1 ), // One for up
    .q ( countup )
    );


// This mutliplexer is right in front of the clock-crossing FIFO.
// Data inputs consist of the 32 bit data concatenated with the Valid
// signal. KEEP VALID AT THE LSB SIDE SO IT IS CONSIDERED FIRST!!!
wire [2:0] fifo_data_select; // Multiplexer control signal
wire mem_ctrl_go_muxout;

mux_8to1_32stream   mux_8to1_32stream_inst (
    .clock ( adc_clk ),
    .data0x ( {adcA_data[19:0], 12'b0, adcA_done} ), // Holy smokes!!! Get things into 32 bit land
    .data1x ( {adcB_data[19:0], 12'b0, adcB_done} ), // ASAP!!!
    .data2x ( {countup[15:0], countdown[15:0], adc_go} ), // Super simple test pattern
    .data3x ( {32'hDEADBEEF, adc_go} ),
	 .data4x ( {32'h44444444, adc_go} ), // Future expansion!!
	 .data5x ( {32'h55555555, adc_go} ),
	 .data6x ( {32'h66666666, adc_go} ),
	 .data7x ( {32'h77777777, adc_go} ),
    .sel ( fifo_data_select ),
    .result ( {mem_ctrl_data, mem_ctrl_go_muxout} )
    );

assign mem_ctrl_go = mem_ctrl_go_muxout & delayed_trig;


reg adc_fifo_valid;
wire adc_fifo_rdreq;
wire adc_fifo_wrreq;
wire adc_fifo_ready;
wire adc_fifo_empty;
wire adc_fifo_full;

wire [31:0] adc_fifo_data;

    assign adc_fifo_rdreq = (!adc_fifo_empty & adc_fifo_ready) ? 1'b1 : 1'b0;
    assign adc_fifo_wrreq = mem_ctrl_go & (!adc_fifo_full); // Faucet triggering!

        always @(posedge clk)
        begin
            if(adc_fifo_rdreq)
                adc_fifo_valid <= 1'b1;
            else
                adc_fifo_valid <= 1'b0;
        end

 // Note: show ahead mode
 ADC_fifo adc_fifo
 (
  .aclr(reset),
  .data({mem_ctrl_data}),
  .rdclk(clk),
  .rdreq(adc_fifo_rdreq),
  .wrclk(adc_clk),
  .wrreq(adc_fifo_wrreq),
  .q(adc_fifo_data),
  .rdempty(adc_fifo_empty),
  .wrfull(adc_fifo_full) // If this ever asserts, something went wrong!
 );

// Synchronize trigger pulse
wire force_trig_nosync;
reg force_trig, ft1, ft2;
always @(posedge adc_clk) begin
 ft1<= force_trig_nosync;
 ft2<= ft1;
 force_trig <= ft2;
end


trigger_block trigger_block_inst
(
    .clk(adc_clk),
    .reset_n(~reset),

    .data_valid(mem_ctrl_go),
    .trig_in(~KEY[1]),
    .force_trig(force_trig), // Pushbutton trigger
 
    .pre_trig_counter(32'd128),
    .pre_trig_counter_value(),
    .post_trig_counter(num_samples),

    .en_trig(start),
    .delayed_trig(delayed_trig)
);

//wire ltc6954_sync_wire , gpo1_wire, gpo0_wire;
//assign ltc6954_sync = ltc6954_sync_wire;
//assign gpo0 = gpo0_wire;
//assign gpo1 = gpo1_wire;


// initialize qsys generated system
//assign std_ctrl_wire = {26'b0, lut_write_enable, ltc6954_sync , gpo1, gpo0, en_trig, start };
//assign datapath_control = {16'b0, lut_run_once, 1'b0, lut_addr_select[1:0], 2'b0, dac_a_select[1:0], 2'b0, dac_b_select[1:0],  1'b0, fifo_data_select[2:0]};


     LTQsys_blob2 LTQsys_blob2_inst (
        .clk_clk(clk),                           //                      clk.clk
        .reset_reset_n(!reset),                     //                    reset.reset_n
        .hps_memory_mem_a(hps_memory_mem_a),                  //  hps_memory.mem_a
        .hps_memory_mem_ba(hps_memory_mem_ba),                 //            .mem_ba
        .hps_memory_mem_ck(hps_memory_mem_ck),                 //            .mem_ck
        .hps_memory_mem_ck_n(hps_memory_mem_ck_n),               //            .mem_ck_n
        .hps_memory_mem_cke(hps_memory_mem_cke),                //            .mem_cke
        .hps_memory_mem_cs_n(hps_memory_mem_cs_n),               //            .mem_cs_n
        .hps_memory_mem_ras_n(hps_memory_mem_ras_n),              //            .mem_ras_n
        .hps_memory_mem_cas_n(hps_memory_mem_cas_n),              //            .mem_cas_n
        .hps_memory_mem_we_n(hps_memory_mem_we_n),               //            .mem_we_n
        .hps_memory_mem_reset_n(hps_memory_mem_reset_n),            //            .mem_reset_n
        .hps_memory_mem_dq(hps_memory_mem_dq),                 //            .mem_dq
        .hps_memory_mem_dqs(hps_memory_mem_dqs),                //            .mem_dqs
        .hps_memory_mem_dqs_n(hps_memory_mem_dqs_n),              //            .mem_dqs_n
        .hps_memory_mem_odt(hps_memory_mem_odt),                //            .mem_odt
        .hps_memory_mem_dm(hps_memory_mem_dm),                 //            .mem_dm
        .hps_memory_oct_rzqin(hps_memory_oct_rzqin),              //            .oct_rzqin
        .fpga_memory_mem_a(fpga_memory_mem_a),                 // fpga_memory.mem_a
        .fpga_memory_mem_ba(fpga_memory_mem_ba),                //            .mem_ba
        .fpga_memory_mem_ck(fpga_memory_mem_ck),                //            .mem_ck
        .fpga_memory_mem_ck_n(fpga_memory_mem_ck_n),              //            .mem_ck_n
        .fpga_memory_mem_cke(fpga_memory_mem_cke),               //            .mem_cke
        .fpga_memory_mem_cs_n(fpga_memory_mem_cs_n),              //            .mem_cs_n
        .fpga_memory_mem_dm(fpga_memory_mem_dm),                //            .mem_dm
        .fpga_memory_mem_ras_n(fpga_memory_mem_ras_n),             //            .mem_ras_n
        .fpga_memory_mem_cas_n(fpga_memory_mem_cas_n),             //            .mem_cas_n
        .fpga_memory_mem_we_n(fpga_memory_mem_we_n),              //            .mem_we_n
        .fpga_memory_mem_reset_n(fpga_memory_mem_reset_n),           //            .mem_reset_n
        .fpga_memory_mem_dq(fpga_memory_mem_dq),                //            .mem_dq
        .fpga_memory_mem_dqs(fpga_memory_mem_dqs),               //            .mem_dqs
        .fpga_memory_mem_dqs_n(fpga_memory_mem_dqs_n),             //            .mem_dqs_n
        .fpga_memory_mem_odt(fpga_memory_mem_odt),               //            .mem_odt
        .oct_rzqin(oct_rzqin),                         //         oct.rzqin
        .mem_pll_pll_locked(pll_locked),                //            .pll_locked
// User registers  .output_std_ctrl_export
        .rev_type_id_export                ({FPGA_REV, FPGA_TYPE}),                //              rev_type_id.export
//        .output_std_ctrl_export            ({26'b0, lut_write_enable, ltc6954_sync_wire , gpo1_wire, gpo0_wire, en_trig, start }),            //          output_std_ctrl.export
        .output_std_ctrl_export            ({26'b0, lut_write_enable, ltc6954_sync , gpo1, gpo0, force_trig_nosync, start }),            //          output_std_ctrl.export
        .input_std_stat_export             ({31'b0, delayed_trig}),             //           input_std_stat.export
        .output_0x40_export                ({2'b0, n, cfg, 4'b0, LEDwire[1:0]}),                //              output_0x40.export
        .output_0x50_export                (num_samples),                //              output_0x50.export
        .output_0x60_export                ({16'b0, pid_kp}),                //              output_0x60.export
        .output_0x70_export                (pid_ki),                //              output_0x70.export
        .output_0x80_export                (pid_kd),                //              output_0x80.export
        .output_0x90_export                (pulse_low),                //              output_0x90.export
        .output_0xa0_export                (pulse_high),                //              output_0xa0.export
        .output_0xb0_export                (pulse_val),                //              output_0xb0.export
        .output_0xc0_export                (system_clocks_per_sample),                //              output_0xc0.export
        .output_0xd0_export                ({16'b0, lut_run_once, 1'b0, lut_addr_select[1:0], 2'b0, dac_a_select[1:0], 2'b0, dac_b_select[1:0],  1'b0, fifo_data_select[2:0]}), // First Order System model parameters
        .output_0xe0_export                ({lut_wraddress, lut_wrdata}),
        .output_0xf0_export                (tuning_word),  // DAC sinewave tuning word
        .input_0x100_export                ({2'b0, stop_address[29:0]}), // After capture, this is where to start reading
        // A simple pipe to write data into memory.
        // Tying off after including Noe's controlller!
        .mem_master_1_conduit_end_1_1_addr     (32'b0),//(mem_ctrl_addr),     // mem_master_1_conduit_end.addr
        .mem_master_1_conduit_end_1_1_go       (1'b0),//(mem_ctrl_go),       //                         .go
        .mem_master_1_conduit_end_1_1_ready    (),//(mem_ctrl_ready),    //                         .ready
        .mem_master_1_conduit_end_1_1_data     (32'b0),//({mem_ctrl_data, 12'b0}),      //                         .data, LEFT justified!!

        // SPI port for configuring various things
        .spi_0_external_MISO               (ltc6954_sdo),               //           spi_0_external.MISO
        .spi_0_external_MOSI               (ltc6954_sdi),               //                         .MOSI
        .spi_0_external_SCLK               (ltc6954_sck),               //                         .SCLK
        .spi_0_external_SS_n               ({7'bz, ltc6954_cs}),                //                         .SS_n
        .tie_me_off_data                    (8'bz),                    //                   tie_me_off.data
        .tie_me_off_valid                   (1'bz),                   //                             .valid
        .tie_me_off_ready                   (1'b0),                   //                             .ready
        .ltscope_data_input_data            (adc_fifo_data),            //           ltscope_data_input.data
        .ltscope_data_input_valid           (adc_fifo_valid),           //                             .valid
        .ltscope_data_input_ready           (adc_fifo_ready),           //                             .ready
        .ltscope_controller_ring_buff_go    (start),    //           ltscope_controller.ring_buff_go
        .ltscope_controller_ring_buff_addr  (stop_address),  //                             .ring_buff_addr
        .ltscope_controller_read_go         (1'b0),         //                             .read_go
        .ltscope_controller_read_start_addr (32'b0), //                             .read_start_addr
        .ltscope_controller_read_length     (32'b0),     //                             .read_length
        .ltscope_controller_read_done       (1'bz)        //                             .read_done
          );

endmodule

//     assign DAC_A = dac_data; //16'h5555; // UNSIGNED!!
//     assign DAC_B = nco_sin_out ^ 16'h8000;

//   assign DAC_CLK_A = ~adc_clk; //50M, for now...
//   assign DAC_CLK_B = ~adc_clk;

//    assign clk = OSC_50_B3B;

//wire [31:0] start_wire;
//wire [31:0] data_ready_wire;
//assign start = start_wire[0];
//assign data_ready_wire = {31'b0, data_ready};

// wire pulse_trig;
// wire [31:0] low_period = 32'd200;
// wire [31:0] high_period = 32'd3000;
// wire [19:0] value = 20'd10000;

    // nco i_nco (
    // .out_valid(),
    // .fsin_o(nco_sin_out),
    // .phi_inc_i(tuning_word),
    // .reset_n(1'b1),
    // .clken(1'b1),
    // .clk(adc_clk)
    // );


/*     //controller for DAC
    wire dac_clk;
    dac_controller dac_ctrl (
        .clk(adc_clk),
        .reset(reset),
        .data_in(pid_output),
        .data_out(sys_in),
        .dac_clk(dac_clk)
    ); */

//This logic replaced with mux in front of FIFO!!
//assign mem_ctrl_data = (mem_adcA_nadcB) ? feedback  : adcB_data;
//assign mem_ctrl_go   = (mem_adcA_nadcB) ? adcA_done : adcB_done;
     //assign mem_ctrl_go = adc_done;
