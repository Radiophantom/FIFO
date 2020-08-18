`timescale 1ns / 1ps

module fifo_tb #(
  parameter int    DWIDTH    = 8,
  parameter int    AWIDTH    = 4,
  parameter string SHOWAHEAD = "OFF"
);

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

event check_done;

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

task automatic single_write();
  wait( !alt_fifo_full_o );
  wait( check_done.triggered );
  wrreq_i = 1'b1;
  data_i  = $random;
  @( posedge clk_i );
  wait( check_done.triggered );
  wrreq_i = 1'b0;
endtask : single_write

task automatic single_read();
  wait( !alt_fifo_empty_o );
  wait( check_done.triggered );
  rdreq_i = 1'b1;
  @( posedge clk_i );
  wait( check_done.triggered );
  rdreq_i = 1'b0;
endtask : single_read

task automatic write_full_fifo( input bit pause_write );
  fork : write_loop
    wait( alt_fifo_full_o );
    while( 1 )
      begin
        wait( check_done.triggered );
        if( pause_write )
          wrreq_i = $urandom_range( 1 );
        else
          wrreq_i = 1'b1;
        data_i  = $random;
        @( posedge clk_i );
      end
  join_any
  disable write_loop;
  wait( check_done.triggered );
  wrreq_i = 1'b0;
endtask : write_full_fifo

task automatic read_full_fifo( input bit pause_read );
  fork : read_loop
    wait( alt_fifo_empty_o );
    while( 1 )
      begin
        wait( check_done.triggered );
        if( pause_read )
          rdreq_i = $urandom_range( 1 );
        else
          rdreq_i = 1'b1;
        @( posedge clk_i );
      end
  join_any
  disable read_loop;
  wait( check_done.triggered );
  rdreq_i = 1'b0;
endtask : read_full_fifo

task automatic full_bound_test();
  write_full_fifo( 0 );
  single_read();
  fork
    single_write();
    single_read();
  join
  single_write();
endtask : full_bound_test

task automatic empty_bound_test();
  read_full_fifo( 0 );
  single_write();
  fork
    single_read();
    single_write();
  join
  single_read();
endtask : empty_bound_test

task automatic control_signals_check();
  forever
    begin
      @( posedge clk_i );
      if( alt_fifo_empty_o !== custom_fifo_empty_o )
        begin
          $display( "%0t : Unexpected empty flag behavior", $time );
          $display( "Expected : %b", alt_fifo_empty_o );
          $display( "Observed : %b", custom_fifo_empty_o );
          $stop();
        end
      if( alt_fifo_full_o !== custom_fifo_full_o )
        begin
          $display( "%0t : Unexpected full flag behavior", $time );
          $display( "Expected : %b", alt_fifo_full_o );
          $display( "Observed : %b", custom_fifo_full_o );
          $stop();
        end
      if( alt_fifo_usedw_o !== custom_fifo_usedw_o )
        begin
          $display( "%0t : Used words mismatch", $time );
          $display( "Expected : %0d", alt_fifo_usedw_o );
          $display( "Observed : %0d", custom_fifo_usedw_o );
          $stop();
        end
    end
endtask : control_signals_check

task automatic data_check();
  forever
    if( SHOWAHEAD == "OFF" )
      begin
        @( posedge clk_i );
        if( rdreq_i )
          do
            begin
              -> check_done;
              @( posedge clk_i );
              if( alt_fifo_q_o !== custom_fifo_q_o )
                begin
                  $display( "%0t : Data word mismatch", $time );
                  $display( "Expected : %h", alt_fifo_q_o );
                  $display( "Observed : %h", custom_fifo_q_o );
                  $stop();
                end
            end
          while( rdreq_i );
        -> check_done;
      end
    else if( SHOWAHEAD == "ON" )
      begin
        @( posedge clk_i );
        if( rdreq_i )
          if( alt_fifo_q_o !== custom_fifo_q_o )
            begin
              $display( "%0t : Data word mismatch", $time );
              $display( "Expected : %h", alt_fifo_q_o );
              $display( "Observed : %h", custom_fifo_q_o );
              $stop();
            end
        -> check_done;
      end
endtask : data_check

always #5 clk_i = !clk_i;

initial
  begin
    wrreq_i = 1'b0;
    data_i  = '0;
    rdreq_i = 1'b0;

    @( posedge clk_i );
    srst_i = 1'b1;
    @( posedge clk_i );
    srst_i = 1'b0;

    fork
      control_signals_check();
      data_check();
    join_none;

    // full and empty flags test
    write_full_fifo( 0 );
    read_full_fifo( 0 );
    repeat(5) @( posedge clk_i );
    
    write_full_fifo( 1 );
    read_full_fifo( 1 );
    repeat(5) @( posedge clk_i );

    // full and empty bound condition test
    full_bound_test();
    repeat(5) @( posedge clk_i );

    empty_bound_test();
    repeat(5) @( posedge clk_i );

    $display( "Test successfully passed" );
    $stop();
  end

endmodule : fifo_tb