onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fifo_tb/clk_i
add wave -noupdate /fifo_tb/srst_i
add wave -noupdate /fifo_tb/wrreq_i
add wave -noupdate /fifo_tb/data_i
add wave -noupdate /fifo_tb/rdreq_i
add wave -noupdate -divider {Altera SCFIFO}
add wave -noupdate /fifo_tb/alt_fifo_q_o
add wave -noupdate /fifo_tb/alt_fifo_empty_o
add wave -noupdate /fifo_tb/alt_fifo_full_o
add wave -noupdate -radix unsigned /fifo_tb/alt_fifo_usedw_o
add wave -noupdate -divider {Custom SCFIFO}
add wave -noupdate /fifo_tb/custom_fifo_q_o
add wave -noupdate /fifo_tb/custom_fifo_empty_o
add wave -noupdate /fifo_tb/custom_fifo_full_o
add wave -noupdate -radix unsigned /fifo_tb/custom_fifo_usedw_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {586090 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue right
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1611750 ps}
