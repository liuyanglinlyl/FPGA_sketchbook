# udpsdr_hf0.sdc
#
# Project: Medium Wave (500KHz - 1700KHz) Receiver, SDR Demonstration
# Copyright 2012, Zephyr Engineering, Inc., All Rights Reserved
#
# Description: Timing constraints file. Defines clocks and constrains
# all I/O.
#
# Written by: Steve Kalandros
#
# Revision 0.1 - July 20, 2012 S.K. Initial release
# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# Timing Parameters
# -------------------------------------------------------------------------------------------------
# Define input clock parameters.
set CLK_50_PERIOD 20.000
set CLK_10_PERIOD 100.000
set CLK_DUTY_CYCLE 50.0

# Define ADC clock parameters
set ADC_CLK_RATIO 5

# Define clock skew as positive when the BeRadio clock is delayed with respect to the FPGA clock.
# In this case there is an extra buffer in the path to the FPGA clock input compared to the ADC 
# clock input, so the extra delay makes the minimum skew more negative.
set CLK_SKEW_MAX 0.0
set CLK_SKEW_MIN -4.0

# Define trace delay between FPGA and ADC or DAC.
set TRACE_DLY_MAX 1.0
set TRACE_DLY_MIN 0.0

# Define ADC output pin timing characteristics.
set ADC_TCO_MAX 5.4
set ADC_TCO_MIN 1.4

# Define DAC input pin timing characteristics.
set DAC_TSU 10.0
set DAC_TH   0.0

# Define path timing differences on SPI bus
set SPI_SKEW_MAX  1.0
set SPI_SKEW_MIN -1.0

# Define JTAG parameters
set JTAG_TDI_DLY 20.0
set JTAG_TMS_DLY 20.0
set JTAG_TDO_DLY 20.0
# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# Clock Constraints
# -------------------------------------------------------------------------------------------------
# Define 50 MHz input clock from BeMicro on-board oscillator (defaults to 50% duty cycle).
create_clock -name clk50 -period $CLK_50_PERIOD [get_ports {CLK_FPGA_50M}]

# Define 10 MHz output clock generated by PLL going to the BeRadio.
create_generated_clock -name adc_clk_in \
        -source sysclk_pll_inst|altpll_component|auto_generated|pll1|inclk[0] \
        -divide_by $ADC_CLK_RATIO -multiply_by 1 -duty_cycle $CLK_DUTY_CYCLE \
        { sysclk_pll_inst|altpll_component|auto_generated|pll1|clk[0] }

# Define virtual ADC clock. The clock buffers on the BeRadio invert the clock but instead of
# adding a 180-degree phase shift, we treat the ADC outputs as being launched on the falling
# edge of the clock.
create_clock -name adc_clk -period $CLK_10_PERIOD

# Define 10 MHz input clock coming from the BeRadio; this clock may be sourced by either
# the FPGA PLL output (adc_clk_in) or an on-board oscillator.
create_clock -name adc_clk_out -period $CLK_10_PERIOD [get_ports {P19}]

# Define SPI bus SCLK going to the DAC as a generated clock.
create_generated_clock -name dac_sclk \
        -source [get_pins {spi_if_inst|sclk|clk}] \
        -divide_by 2 [get_pins {spi_if_inst|sclk|q}]

create_generated_clock -name P26 \
        -source [get_pins {spi_if_inst|sclk|q}] \
        [get_ports {P26}]

# Define asynchronous clock groups to set false paths between groups. We consider the first
# group as asynchronous to the second even though they may be related, since adc_clk and
# adc_clk_out may be generated from adc_clk_in; however, no FPGA logic is run off the first
# group and the second group may be generated from an oscillator on the BeRadio, so it is
# easier to treat them as completely independent.
set_clock_groups -asynchronous \
        -group [get_clocks {clk50 adc_clk_in}] \
        -group [get_clocks {adc_clk adc_clk_out dac_sclk P26}] \
        -group [get_clocks altera_reserved_tck]

# Automatically calculate clock uncertainty due to jitter and other effects.
derive_clock_uncertainty
# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# I/O Constraints
# -------------------------------------------------------------------------------------------------
# Constrain input pins coming from ADC outputs. The ADC clock is inverted with respect to
# the FPGA clock, so we treat the ADC outputs as being generated on the falling edge of the
# virtual ADC clock.
set_input_delay -clock adc_clk -max [expr $CLK_SKEW_MAX + $ADC_TCO_MAX + $TRACE_DLY_MAX] \
        -clock_fall [get_ports {P4 P5 P6 P7 P8 P9 P10 P11 P12 P13 P14 P15 P16}]
set_input_delay -clock adc_clk -min [expr $CLK_SKEW_MIN + $ADC_TCO_MIN + $TRACE_DLY_MIN] \
        -clock_fall [get_ports {P4 P5 P6 P7 P8 P9 P10 P11 P12 P13 P14 P15 P16}]

# Constrain output pins going to DAC.
set_output_delay -clock P26 -max [expr $SPI_SKEW_MAX + $DAC_TSU] [get_ports {P25}]
set_output_delay -clock P26 -min [expr $SPI_SKEW_MIN - $DAC_TH]  [get_ports {P25}]

# Shift SPI clock hold time. The SPI clock is half the ADC clock rate. SPI data are launched
# on the falling edge of the SPI clock and latched on the rising edge. The setup time is
# correctly evaluated from the ADC clock rising edge immediately preceding the SPI clock
# rising edge by default; however the hold time is evaluated from the ADC clock rising edge
# to the concurrent SPI clock rising edge, whereas it should be evaluated from the FOLLOWING
# ADC clock rising edge. Thus, we use a multicycle hold constraint to force it to use the
# correct starting edge.
set_multicycle_path -from adc_clk_out -to P26 -start -hold  1

# Constrain JTAG input pins.
set_input_delay -clock altera_reserved_tck -clock_fall $JTAG_TDI_DLY [get_ports altera_reserved_tdi]
set_input_delay -clock altera_reserved_tck -clock_fall $JTAG_TMS_DLY [get_ports altera_reserved_tms]

# Constrain JTAG output pins.
set_output_delay -clock altera_reserved_tck -clock_fall $JTAG_TDO_DLY [get_ports altera_reserved_tdo]

# Don't need to analyze output clocks.
set_false_path -from [get_pins -hierarchical {*}] -to [get_ports {P22}]
set_false_path -from [get_pins -hierarchical {*}] -to [get_ports {P26}]

# Don't need to analyze asynchronous outputs.
set_false_path -from [get_ports              {*}] -to [get_ports {F_LED*}]
set_false_path -from [get_pins -hierarchical {*}] -to [get_ports {F_LED*}]
set_false_path -from [get_pins -hierarchical {*}] -to [get_ports {P24}]
set_false_path -from [get_pins -hierarchical {*}] -to [get_ports {P27}]

# Don't need to analyze asynchronous input pins.
set_false_path -from [get_ports {CPU_RST_N}]    -to [get_pins -hierarchical {*}]
set_false_path -from [get_ports {PBSW_N}]       -to [get_pins -hierarchical {*}]
set_false_path -from [get_ports {RECONFIG_SW?}] -to [get_pins -hierarchical {*}]
# -------------------------------------------------------------------------------------------------

