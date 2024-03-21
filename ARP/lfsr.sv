`timescale 1ns / 1ps

/*
*   Linear Feedback Shift Register (LFSR) for hashing and CRC
*/

module lfsr#(

    parameter POLY_EQU          = 32'h5c618b7,
    parameter LSFRW             = 32,
    parameter LSFR_Config       = "F",
    parameter LSFR_FEED_FORWARD = 0,
    parameter REVERSE           = 1,
    parameter DATAW             = 32

)(

    input  logic [DATAW-1 : 0] data_in,
    input  logic [LSFRW-1 : 0] state_in,
    output logic [DATAW-1 : 0] data_out,
    output logic [LSFRW-1 : 0] state_out

);

    localparam MASKW = LSFRW + DATAW;
    
    //Generate the xor-mask according to the polynominal data and the the initial input state to the module
    function [MASKW-1 : 0] generate_mask(input [31:0] index);
    
        logic [LSFRW-1 : 0] lfsr_mask_state [LSFRW-1 : 0];
        logic [DATAW-1 : 0] lfsr_mask_data  [LSFRW-1 : 0];
        logic [LSFRW-1 : 0] out_mask_state  [DATAW-1 : 0];
        logic [DATAW-1 : 0] out_mask_data   [DATAW-1 : 0];
        
        logic [LSFRW-1 : 0] state_val;
        logic [DATAW-1 : 0] data_val, data_mask;
        
        integer i,j;
        
        
        begin
            
            //Mask Initialization
            for(i = 0; i < LSFRW; i++) begin
            
                lfsr_mask_state[i]    = 0;
                lfsr_mask_state[i][i] = 1'b1;
                lfsr_mask_data[i]     = 0;  
            
            end//end for
            
            //Data and State Initialization
            for(i = 0; i < DATAW; i++) begin
            
                out_mask_state[i] = 0;
                if(i < LSFRW) begin
                
                    out_mask_state[i][i] = 1'b1;
                
                end//end if
                
                out_mask_data[i] = 0;  
            
            end//end for
            
            //Fibonacci LFSR configuration
            if(LSFR_Config == "F") begin
            
                for(data_mask = {1'b1, {DATAW-1{1'b0}}}; data_mask != 0; data_mask >>= 1) begin
                
                    //Fetch the state and data in the last level and xor them
                    state_val = lfsr_mask_state[LSFRW-1];
                    data_val  = lfsr_mask_data[LSFRW-1];
                    data_val  = data_val ^ data_mask;
                    
                    //Xor the tabs determined by the Polynominal equation
                    for(j = 1; j < LSFRW; j++) begin
                    
                        //Determine tab posistion
                        if((POLY_EQU >> j) & 1) begin
                        
                            state_val = lfsr_mask_state[j-1] ^ state_val;
                            data_val  = lfsr_mask_data[j-1]  ^ data_val;
                        
                        end//end if
                    
                    end//end for
                    
                    //Shift the mask levels
                    for(j = LSFRW-1; j > 0; j--) begin
                    
                        lfsr_mask_state[j] = lfsr_mask_state[j-1];
                        lfsr_mask_data[j]  = lfsr_mask_data[j-1];
                    
                    end//end for
                    
                    for(j = DATAW-1; j > 0; j--) begin
                    
                        out_mask_state[j] = out_mask_state[j-1];
                        out_mask_data[j]  = out_mask_data[j-1];
                    
                    end//end for
                    
                    out_mask_state[0] = state_val;
                    out_mask_data[0]  = data_val;
                    
                    //Generate feedforward instead of feedback
                    if(LSFR_FEED_FORWARD) begin
                    
                        state_val = {LSFRW{1'b0}};
                        data_val  = data_mask;
                    
                    end//end if
                    
                    lfsr_mask_state[0] = state_val;
                    lfsr_mask_data[0]  = data_val;
                
                end//end for
            
            end//end if
            else if(LSFR_Config == "G") begin
            
                for(data_mask = {1'b1, {DATAW-1{1'b0}}}; data_mask != 0; data_mask >>= 1) begin
                
                    //Fetch the state and data in the last level and xor them
                    state_val = lfsr_mask_state[LSFRW-1];
                    data_val  = lfsr_mask_data[LSFRW-1];
                    data_val  = data_val ^ data_mask;
                    
                    
                    //Shift the mask levels
                    for(j = LSFRW-1; j > 0; j--) begin
                    
                        lfsr_mask_state[j] = lfsr_mask_state[j-1];
                        lfsr_mask_data[j]  = lfsr_mask_data[j-1];
                    
                    end//end for
                    
                    for(j = DATAW-1; j > 0; j--) begin
                    
                        out_mask_state[j] = out_mask_state[j-1];
                        out_mask_data[j]  = out_mask_data[j-1];
                    
                    end//end for
                    
                    out_mask_state[0] = state_val;
                    out_mask_data[0]  = data_val;
                    
                    //Generate feedforward instead of feedback
                    if(LSFR_FEED_FORWARD) begin
                    
                        state_val = {LSFRW{1'b0}};
                        data_val  = data_mask;
                    
                    end//end if
                    
                    lfsr_mask_state[0] = state_val;
                    lfsr_mask_data[0]  = data_val;
                    
                   //Xor the tabs determined by the Polynominal equation
                     for(j = 1; j < LSFRW; j++) begin
                     
                         //Determine tab posistion
                         if((POLY_EQU >> j) & 1) begin
                         
                             lfsr_mask_state[j] = lfsr_mask_state[j-1] ^ state_val;
                             lfsr_mask_data[j]  = lfsr_mask_data[j-1]  ^ data_val;
                         
                         end//end if
                     
                     end//end for
                
                end//end for
            
            end//else if end
            
            if(REVERSE) begin
            
                if(index < LSFRW) begin
                
                    state_val = 0;
                    for(i = 0; i < LSFRW; i++) begin
                    
                        state_val[i] = lfsr_mask_state[LSFRW-index-1][LSFRW-i-1];
                    
                    end//end for
                    
                    data_val = 0;
                    for(i = 0; i < DATAW; i++) begin
                    
                        data_val[i] = lfsr_mask_data[LSFRW-index-1][DATAW-i-1];
                    
                    end//end for
                
                end//end if
                else begin
                
                    state_val = 0;
                    for(i = 0; i < LSFRW; i++) begin
                    
                        state_val[i] = out_mask_state[DATAW-(index-LSFRW)-1][LSFRW-i-1];
                    
                    end//end for
                    
                    data_val = 0;
                    for(i = 0; i < DATAW; i++) begin
                    
                        data_val[i] = out_mask_data[DATAW-(index-LSFRW)-1][DATAW-i-1];
                    
                    end//end for    
                
                end//else end
            
            end//end if
            else begin
            
                if(index < LSFRW) begin
                
                    state_val = lfsr_mask_state[index];
                    data_val  = lfsr_mask_data[index];
                
                end//end if
                else begin
                    
                    state_val = out_mask_state[index-LSFRW];
                    data_val  = out_mask_data[index-LSFRW];
                
                end//end else
            
            end//end else
            
            generate_mask = {data_val, state_val};
            
        end
    
    endfunction
    
    genvar k;
    
    generate
    
        for(k = 0; k < LSFRW; k++) begin
        
            logic [MASKW-1 : 0] mask = generate_mask(k);
            logic state_reg;
            
            assign state_out[k] = state_reg;
            
            integer i;
            
            always_comb  begin
            
                state_reg = 1'b0;
                for(i = 0; i < LSFRW; i++) begin
                
                    if(mask[i])
                        state_reg = state_reg ^ state_in[i];
                
                end
                for(i = 0; i < DATAW; i++) begin
                
                    if(mask[i+LSFRW])
                        state_reg = state_reg ^ data_in[i];
                
                end
            
            end
        
        end//For loop
        
        for(k = 0; k < DATAW; k++) begin
        
            logic [MASKW-1 : 0] mask = generate_mask(k+LSFRW);
            logic data_reg;
            
            assign data_out[k] = data_reg;
            
            integer i;
            
            always_comb  begin
            
                data_reg = 1'b0;
                for(i = 0; i < LSFRW; i++) begin
                
                    if(mask[i])
                        data_reg = data_reg ^ state_in[i];
                
                end
                for(i = 0; i < DATAW; i++) begin
                
                    if(mask[i+LSFRW])
                        data_reg = data_reg ^ data_in[i];
                
                end
            
            end
        
        end//For loop
    
    
    endgenerate

endmodule
