`timescale 1ns / 1ps

`include "./random_scenario.sv"

module fifo_tb #(
  parameter int    DWIDTH    = 8,
  parameter int    AWIDTH    = 4,
  parameter string SHOWAHEAD = "ON"
);

localparam int FIFO_DEPTH = 2**AWIDTH;

bit clk_i  = 0;
bit srst_i = 0;

logic                  wrreq_i;
logic [DWIDTH - 1 : 0] data_i;
logic                  rdreq_i;

logic [DWIDTH - 1 : 0] alt_fifo_q_o;

logic                  alt_fifo_empty_o; 
logic                  alt_fifo_full_o;
logic [AWIDTH - 1 : 0] alt_fifo_usedw_o;

logic                  custom_fifo_rdreq_i;
logic [DWIDTH - 1 : 0] custom_fifo_q_o;

logic                  custom_fifo_empty_o; 
logic                  custom_fifo_full_o;
logic [AWIDTH - 1 : 0] custom_fifo_usedw_o;

logic [AWIDTH : 0] ref_usedw;

altera_scfifo #(
  .SHOWAHEAD ( SHOWAHEAD        )
) altera_scfifo (
  .clock     ( clk_i            ),
  .sclr      ( srst_i           ),

  .wrreq     ( wrreq_i          ),
  .data      ( data_i           ),

  .rdreq     ( rdreq_i          ),
  .q         ( alt_fifo_q_o     ),

  .empty     ( alt_fifo_empty_o ),
  .full      ( alt_fifo_full_o  ),
  .usedw     ( alt_fifo_usedw_o )
);

fifo #(
  .DWIDTH    ( DWIDTH    ),
  .AWIDTH    ( AWIDTH    ),
  .SHOWAHEAD ( SHOWAHEAD )
) custom_fifo (
  .clk_i     ( clk_i               ),
  .srst_i    ( srst_i              ),

  .wrreq_i   ( wrreq_i             ),
  .data_i    ( data_i              ),

  .rdreq_i   ( rdreq_i             ),
  .q_o       ( custom_fifo_q_o     ),

  .empty_o   ( custom_fifo_empty_o ), 
  .full_o    ( custom_fifo_full_o  ),
  .usedw_o   ( custom_fifo_usedw_o )
);

task automatic model ();
  ref_usedw  = 0;
  forever
    begin
      @( posedge clk_i );
      ref_usedw <= ref_usedw + wrreq_i - rdreq_i;
    end
endtask

task automatic write_only ();
  @( posedge clk_i );
  wrreq_i <= ( ref_usedw < ( FIFO_DEPTH - 1 ) ) || ( ( ref_usedw == ( FIFO_DEPTH - 1 ) ) && !wrreq_i );
  rdreq_i <= 1'b0;
  data_i  <= $urandom();
endtask

task automatic read_only ();
  @( posedge clk_i );
  wrreq_i <= 1'b0;
  rdreq_i <= ( ref_usedw > 1 ) || ( ( ref_usedw == 1 ) && !rdreq_i );
endtask

task automatic read_write ();
  @( posedge clk_i );
  wrreq_i <= ( ref_usedw < ( FIFO_DEPTH - 1 ) ) || ( ( ref_usedw == ( FIFO_DEPTH - 1 ) ) && !wrreq_i );
  rdreq_i <= ( ref_usedw > 1                  ) || ( ( ref_usedw == 1                  ) && !rdreq_i );
  data_i  <= $urandom();
endtask

task automatic idle ();
  @( posedge clk_i );
  wrreq_i <= 1'b0;
  rdreq_i <= 1'b0;
endtask

task automatic run_tasks_scenario ( input bit [1:0] tasks_scenario[$] );
  bit [1:0] current_task;
  while( tasks_scenario.size() !== 0 )
    begin
      current_task = tasks_scenario.pop_front();
      case( current_task )
        2'd0 : idle();
        2'd1 : write_only();
        2'd2 : read_only();
        2'd3 : read_write();
      endcase
    end
  idle();
endtask

task automatic control_signals_check ();
  forever
    begin
      @( posedge clk_i );
      if( alt_fifo_empty_o != custom_fifo_empty_o )
        begin
          $display( "%0t : Unexpected empty flag behavior", $time );
          $stop();
        end

      if( alt_fifo_full_o != custom_fifo_full_o )
        begin
          $display( "%0t : Unexpected full flag behavior", $time );
          $stop();
        end
      
      if( alt_fifo_usedw_o != custom_fifo_usedw_o )
        begin
          $display( "%0t : Used words mismatch", $time );
          $display( "Expected : %0d", alt_fifo_usedw_o );
          $display( "Observed : %0d", custom_fifo_usedw_o );
          $stop();
        end
    end
endtask

task automatic data_check ();
  forever
    begin
      @( posedge clk_i );
      if( SHOWAHEAD == "OFF" )
        if( alt_fifo_q_o != custom_fifo_q_o )
          begin
            $display( "%0t : Data word mismatch", $time );
            $display( "Expected : %h", alt_fifo_q_o );
            $display( "Observed : %h", custom_fifo_q_o );
            $stop();
          end
      else if( SHOWAHEAD == "ON" )
        if( rdreq_i && ( alt_fifo_q_o != custom_fifo_q_o ) )
          begin
            $display( "%0t : Data word mismatch", $time );
            $display( "Expected : %h", alt_fifo_q_o );
            $display( "Observed : %h", custom_fifo_q_o );
            $stop();
          end
    end
endtask

always #5 clk_i = !clk_i;

random_scenario scenario;

initial
  begin
    $timeformat( -9, 0, " ns", 20 );
    wrreq_i = 1'b0;
    data_i  = '0;
    rdreq_i = 1'b0;

    @( posedge clk_i );
    srst_i = 1'b1;
    @( posedge clk_i );
    srst_i = 1'b0;

    repeat(5) @( posedge clk_i );

    fork
      control_signals_check ();
      data_check ();
      model ();
    join_none;

    scenario = new();
    scenario.set_probability(0, 100, 0, 0);
    scenario.get_tasks_scenario( 20 );
    run_tasks_scenario( scenario.tasks_scenario );

    scenario = new();
    scenario.set_probability(0, 0, 100, 0);
    scenario.get_tasks_scenario( 20 );
    run_tasks_scenario( scenario.tasks_scenario );
 
    scenario = new(); 
    scenario.set_probability(30, 30, 30, 30);
    scenario.get_tasks_scenario( 100 );
    run_tasks_scenario( scenario.tasks_scenario );

    scenario = new();
    scenario.set_probability(0, 0, 100, 0);
    scenario.get_tasks_scenario( 20 );
    scenario.set_probability(0, 100, 0, 0);
    scenario.get_tasks_scenario( 1 );
    scenario.set_probability(0, 0, 100, 0);
    scenario.get_tasks_scenario( 2 );
    run_tasks_scenario( scenario.tasks_scenario );

    repeat(5) @( posedge clk_i );

    $display( "Test successfully passed" );
    $stop();
  end

endmodule