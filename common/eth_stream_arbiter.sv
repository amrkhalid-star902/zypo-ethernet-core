`timescale 1ns / 1ps



module eth_stream_arbiter#(

    parameter NUM_REQS       = 4,
    parameter ARB_TYPE       = "P",
    parameter ARB_BLOCK      = 0,
    parameter REVERSE        = 0,
    parameter ARB_BLOCK_ACK  = 1,
    parameter INDEXW         = $clog2(NUM_REQS)

)(

    input  logic clk,
    input  logic reset,
    
    input  logic [NUM_REQS-1 : 0]  valid_req,
    input  logic [NUM_REQS-1 : 0]  acknowledge,
    
    output logic [NUM_REQS-1 : 0]  grant,
    output logic                   valid,
    output logic [INDEXW-1 : 0]    grant_index

);


    logic [NUM_REQS-1 : 0] grant_r, grant_n;
    logic [INDEXW-1 : 0]   index_r, index_n;
    logic valid_r, valid_n;
    
    assign grant        = grant_r;
    assign valid        = valid_r;
    assign grant_index  = index_r;
    
    logic req_valid;
    logic [INDEXW-1 : 0]   req_index;
    logic [NUM_REQS-1 : 0] req_mask;
    
    
    priority_encoder #(
    
        .N (NUM_REQS),
        .REVERSE(REVERSE)
        
    ) priority_encoder_1 (
    
        .data_in   (valid_req),
        .index     (req_index),
        .onehot    (req_mask),
        .valid_out (req_valid)
        
    );
    
    logic [NUM_REQS-1 : 0] mask_r, mask_n;
    
    logic req_valid_masked;
    logic [INDEXW-1 : 0]   req_index_masked;
    logic [NUM_REQS-1 : 0] req_mask_masked;
    
    priority_encoder #(
    
        .N (NUM_REQS),
        .REVERSE(REVERSE)
        
    ) priority_encoder_2 (
    
        .data_in   (mask_r & valid_req),
        .index     (req_index_masked),
        .onehot    (req_mask_masked),
        .valid_out (req_valid_masked)
        
    );
    
    
    always_comb begin
    
        grant_n = 0;
        valid_n = 0;
        index_n = 0;
        mask_n  = mask_r;
        
        if(ARB_BLOCK && !ARB_BLOCK_ACK && grant_r & valid_req) begin
            
            //a valid request is still asserted
            valid_n = valid_r;
            grant_n = grant_r;
            index_n = index_r;
        
        end else if(ARB_BLOCK && ARB_BLOCK_ACK && valid && !(grant_r & acknowledge)) begin
        
            //a valid request which is not acknowledged
            valid_n = valid_r;
            grant_n = grant_r;
            index_n = index_r;
        
        end else if(req_valid) begin
        
            if(ARB_TYPE == "R") begin
            
                if(req_valid_masked) begin
                
                    valid_n = 1'b1;
                    grant_n = req_mask_masked;
                    index_n = req_index_masked;
                    
                    if(!REVERSE) begin
                    
                        mask_n = {NUM_REQS{1'b1}} << (req_index_masked + 1);
                    
                    end
                    else begin
                        
                        mask_n = {NUM_REQS{1'b1}} >> (NUM_REQS - req_index_masked);
                    
                    end
                
                end else begin
                
                    valid_n = 1'b1;
                    grant_n = req_mask;
                    index_n = req_index;
                    
                    if(!REVERSE) begin
                    
                        mask_n = {NUM_REQS{1'b1}} << (req_index + 1);
                    
                    end
                    else begin
                        
                        mask_n = {NUM_REQS{1'b1}} >> (NUM_REQS - req_index);
                    
                    end
                
                end
            
            end else begin
            
                valid_n = 1'b1;
                grant_n = req_mask;
                index_n = req_index;
            
            end
        
        end
    
    end
    
    
    always@(posedge clk) begin
    
        grant_r  <= grant_n;
        valid_r  <= valid_n; 
        index_r  <= index_n;
        mask_r   <= mask_n;
        
        if(reset) begin
            
            grant_r  <= 0;
            valid_r  <= 0; 
            index_r  <= 0;
            mask_r   <= 0;
        
        end
    
    end

endmodule
