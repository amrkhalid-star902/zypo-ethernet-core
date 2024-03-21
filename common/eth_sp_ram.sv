`timescale 1ns / 1ps

//Single Port RAM

module eth_sp_ram#(
    
    parameter DATAW     = 8,
    parameter SIZE      = 4,
    parameter BYTEENW   = 1,
    parameter OUT_REG   = 0,
    parameter ADDRW     = $clog2(SIZE),
    parameter INIT_ENABLE = 0,  
    parameter INIT_FILE   = "",  
    parameter [DATAW-1:0] INIT_VALUE = 0
    
)(
    
    input  logic                 clk,
    input  logic [BYTEENW-1 : 0] wren,
    input  logic [ADDRW-1 : 0]   addr,
    input  logic [DATAW-1 : 0]   wdata,
    output logic [DATAW-1 : 0]   rdata

);


    integer k;
    `define RAM_INITIALIZATION                          \
    if (INIT_ENABLE) begin                              \
        if (INIT_FILE != "") begin                      \
            initial $readmemh(INIT_FILE, ram);          \
        end else begin                                  \
            initial                                     \
                for (k = 0; k < SIZE; k = k + 1)        \
                    ram[k] = INIT_VALUE;                \
        end                                             \
    end
    
    if(OUT_REG)
    begin
    
        logic [DATAW-1:0] rdata_r;
        if(BYTEENW > 1)
        begin
        
            logic [BYTEENW-1:0][7:0] ram [SIZE-1:0];
            `RAM_INITIALIZATION
            always@(posedge clk) 
            begin : RAM_operations
                //Writing data to memory entry
                //The writing process is done through two loops
                //where the outer loop is used to iterate over 
                //the bytes through mempry entry , while the inner
                //loop is used to assign bits within the byte
                //Nested for loop is used instead of using bounding
                //expression like [((i+1)*8)-1 : i*8] as the bounding 
                //expression requires that that boundaries must be constanr
                for(integer i = 0 ; i < BYTEENW; i++)
                begin
                    
                    if(wren[i])
                        ram[addr][i] <= wdata[i*8 +: 8];
                    
                end//for end
                
                
                rdata_r <= ram[addr];
            
            end//always end  
            
        end//BYTEENW end
        else begin
        
            logic [DATAW-1:0] ram [SIZE-1:0];
            `RAM_INITIALIZATION
            integer i;
            always @(posedge clk) 
            begin
                
                if(wren)
                    ram[addr] <= wdata;
                rdata_r <= ram[addr];
            
            end
        
        end
        
        assign rdata = rdata_r;
    
    end
    else begin
    
        if(BYTEENW > 1)
        begin
        
            logic [BYTEENW-1:0][7:0] ram [SIZE-1:0]; 
            `RAM_INITIALIZATION
            always@(posedge clk)
            begin : RAM_Operations1
                //Writing data to memory entry
                //The writing process is done through two loops
                //where the outer loop is used to iterate over 
                //the bytes through mempry entry , while the inner
                //loop is used to assign bits within the byte
                //Nested for loop is used instead of using bounding
                //expression like [((i+1)*8)-1 : i*8] as the bounding 
                //expression requires that that boundaries must be constanr
                
                for(integer i = 0 ; i < BYTEENW; i++)
                begin
                
                    if(wren[i])
                        ram[addr][i] <= wdata[i*8 +: 8];
                    
                end//for end
            
            end//always end  
            
            assign rdata  = ram[addr];
            
        end//BYTEENW end
        else begin
        
            logic [DATAW-1:0] ram [SIZE-1:0];
            `RAM_INITIALIZATION
            integer i;
            always @(posedge clk) 
            begin 
                
                if(wren)
                    ram[addr] <= wdata;
                                
            end
            
            assign rdata  = ram[addr];
        
        end
        
    end
    
endmodule
