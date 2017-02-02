// megafunction wizard: %LPM_MUX%VBB%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: LPM_MUX 

// ============================================================
// File Name: mux_8to1_32stream.v
// Megafunction Name(s):
// 			LPM_MUX
//
// Simulation Library Files(s):
// 			lpm
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 14.1.0 Build 186 12/03/2014 SJ Full Version
// ************************************************************

//Copyright (C) 1991-2014 Altera Corporation. All rights reserved.
//Your use of Altera Corporation's design tools, logic functions 
//and other software and tools, and its AMPP partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Altera Program License 
//Subscription Agreement, the Altera Quartus II License Agreement,
//the Altera MegaCore Function License Agreement, or other 
//applicable license agreement, including, without limitation, 
//that your use is for the sole purpose of programming logic 
//devices manufactured by Altera and sold by Altera or its 
//authorized distributors.  Please refer to the applicable 
//agreement for further details.

module mux_8to1_32stream (
	clock,
	data0x,
	data1x,
	data2x,
	data3x,
	data4x,
	data5x,
	data6x,
	data7x,
	sel,
	result);

	input	  clock;
	input	[32:0]  data0x;
	input	[32:0]  data1x;
	input	[32:0]  data2x;
	input	[32:0]  data3x;
	input	[32:0]  data4x;
	input	[32:0]  data5x;
	input	[32:0]  data6x;
	input	[32:0]  data7x;
	input	[2:0]  sel;
	output	[32:0]  result;

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: new_diagram STRING "1"
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all
// Retrieval info: CONSTANT: LPM_PIPELINE NUMERIC "1"
// Retrieval info: CONSTANT: LPM_SIZE NUMERIC "8"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MUX"
// Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "33"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "3"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL "clock"
// Retrieval info: USED_PORT: data0x 0 0 33 0 INPUT NODEFVAL "data0x[32..0]"
// Retrieval info: USED_PORT: data1x 0 0 33 0 INPUT NODEFVAL "data1x[32..0]"
// Retrieval info: USED_PORT: data2x 0 0 33 0 INPUT NODEFVAL "data2x[32..0]"
// Retrieval info: USED_PORT: data3x 0 0 33 0 INPUT NODEFVAL "data3x[32..0]"
// Retrieval info: USED_PORT: data4x 0 0 33 0 INPUT NODEFVAL "data4x[32..0]"
// Retrieval info: USED_PORT: data5x 0 0 33 0 INPUT NODEFVAL "data5x[32..0]"
// Retrieval info: USED_PORT: data6x 0 0 33 0 INPUT NODEFVAL "data6x[32..0]"
// Retrieval info: USED_PORT: data7x 0 0 33 0 INPUT NODEFVAL "data7x[32..0]"
// Retrieval info: USED_PORT: result 0 0 33 0 OUTPUT NODEFVAL "result[32..0]"
// Retrieval info: USED_PORT: sel 0 0 3 0 INPUT NODEFVAL "sel[2..0]"
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: @data 0 0 33 0 data0x 0 0 33 0
// Retrieval info: CONNECT: @data 0 0 33 33 data1x 0 0 33 0
// Retrieval info: CONNECT: @data 0 0 33 66 data2x 0 0 33 0
// Retrieval info: CONNECT: @data 0 0 33 99 data3x 0 0 33 0
// Retrieval info: CONNECT: @data 0 0 33 132 data4x 0 0 33 0
// Retrieval info: CONNECT: @data 0 0 33 165 data5x 0 0 33 0
// Retrieval info: CONNECT: @data 0 0 33 198 data6x 0 0 33 0
// Retrieval info: CONNECT: @data 0 0 33 231 data7x 0 0 33 0
// Retrieval info: CONNECT: @sel 0 0 3 0 sel 0 0 3 0
// Retrieval info: CONNECT: result 0 0 33 0 @result 0 0 33 0
// Retrieval info: GEN_FILE: TYPE_NORMAL mux_8to1_32stream.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL mux_8to1_32stream.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL mux_8to1_32stream.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL mux_8to1_32stream.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL mux_8to1_32stream_inst.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL mux_8to1_32stream_bb.v TRUE
// Retrieval info: LIB_FILE: lpm
