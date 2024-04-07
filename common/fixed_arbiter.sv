`timescale 1ns / 1ps



module fixed_arbiter#(

    parameter NUM_REQS     = 8,
    parameter LOCK_ENABLE  = 0,
    parameter LOG_NUM_REQS = $clog2(NUM_REQS)

)(

    input  wire                       clk,
    input  wire                       reset,
    input  wire [NUM_REQS-1 : 0]      requests,           
    input  wire                       enable,
    output wire [LOG_NUM_REQS-1 : 0]  grant_index,
    output wire [NUM_REQS-1 : 0]      grant_onehot,   
    output wire                       grant_valid 

);

    
    if(NUM_REQS == 1)
    begin
    
        assign grant_index  = 0;
        assign grant_onehot = requests;
        assign grant_valid  = requests[0];
    
    end
    else begin
    
        priority_encoder #(
        
            .N (NUM_REQS)
            
        ) select (
        
            .data_in   (requests),
            .index     (grant_index),
            .onehot    (grant_onehot),
            .valid_out (grant_valid)
            
        );
    
    end

endmodule