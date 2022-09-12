// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 32
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,
    
     input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,
    
    //inout [`MPRJ_IO_PADS-10:0] analog_io,

    
     output [2:0] irq

);
    wire clkin;
    wire rst;

 
    wire [`MPRJ_IO_PADS-1:0] io_in;
    wire [`MPRJ_IO_PADS-1:0] io_out;
    wire [`MPRJ_IO_PADS-1:0] io_oeb;


    wire [3:0]hrm,hrl,minm,minl,secm,secl;
 
    
   // assign clkin=wb_clk_i;
    assign io_oeb=0;
    
    assign {clkin,rst}=io_in[`MPRJ_IO_PADS-2:0];
    assign io_out[13:9]=hrm;
    assign io_out[17:14]=hrl;
    assign io_out[21:18]=minm;
    assign io_out[25:22]=minl;
    assign io_out[29:26]=secm;
    assign io_out[33:30]=secl;

   iiitb_rtc uut(clkin,rst,hrm,hrl,minm,minl,secm,secl);

endmodule


module iiitb_rtc (
input clkin,rst,
output [3:0]hrm,hrl,minm,minl,secm,secl);
wire [3:0]hrms,hrls,minms,minls,secms,secls;
wire hrclr;
assign hrclr = ((secl==4'd9) && (secm==4'd5) && (minl==4'd9) && (minm==4'd5) && (hrl==4'd3) && (hrm==4'd2));
//clock_div cd(clk,rst,clk);
  counter #(9) c1(.clk(clkin),.rst(rst),.clr(1'b0),.en(1'b1),.count(secl));
  counter #(5) c2(.clk(clkin),.rst(rst),.clr(1'b0),.en(secl==4'd9),.count(secm));
  counter #(9) c3(.clk(clkin),.rst(rst),.clr(1'b0),.en((secl==4'd9) && (secm==4'd5)),.count(minl));
  counter #(5) c4(.clk(clkin),.rst(rst),.clr(1'b0),.en((secl==4'd9) && (secm==4'd5) && (minl==4'd9)),.count(minm));
  counter #(9) c5(.clk(clkin),.rst(rst),.clr(hrclr),.en((secl==4'd9) && (secm==4'd5) && (minl==4'd9) && (minm==4'd5)),.count(hrl));
  counter #(2) c6(.clk(clkin),.rst(rst),.clr(hrclr),.en((secl==4'd9) && (secm==4'd5) && (minl==4'd9) && (minm==4'd5) && (hrl==4'd9)),.count(hrm));
endmodule

module counter #(parameter max_value=15) (
input clk,rst,clr,en,
output reg [3:0] count);
initial
count=4'b0;
always @(posedge clk)
begin
if(rst==0) count <=4'd0;
else if(clr==1) count<=4'd0;
else
begin
if(en==1)
if(count==max_value) count<=4'd0;
else count<=count+1;
else count<=count;
end
end
endmodule
`default_nettype wire
