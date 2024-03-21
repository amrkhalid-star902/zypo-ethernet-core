`timescale 1ns / 1ps

interface lfsr_if#(parameter DATAW = 32, parameter LSFRW = 32);

    logic [DATAW-1 : 0] data_in;
    logic [LSFRW-1 : 0] state_in;
    logic [DATAW-1 : 0] data_out;
    logic [LSFRW-1 : 0] state_out;
    logic clk;
    
    modport master(
    
        output data_in,
        output state_in,
        output clk,
        input  data_out,
        input  state_out
    
    );

endinterface

class transaction #(parameter DATAW = 32, parameter LSFRW = 32);
    
    rand bit [DATAW-1 : 0] a;
    rand bit [LSFRW-1 : 0] b;  
    
    function transaction copy();
    
        copy = new();
        copy.a = this.a;
        copy.b = this.b;
    
    endfunction

endclass

class driver;

    transaction trans;
    virtual lfsr_if lif;
    
    function new();
        
        this.trans = new();
    
    endfunction
    
    task run();
    
        forever begin
            
            trans.randomize();
            @(posedge lif.clk); 
            lif.data_in  <= trans.a;
            lif.state_in <= trans.b;
            $display("[DRV] : dataIn = %0h, stateIn = %0h", lif.data_in, lif.state_in);
            $display("[OUT] : dataOut = %0h, stateOut = %0h", lif.data_out, lif.state_out);
            
        
        end
    
    endtask


endclass

task end_tasks();

    #100;
    $finish();

endtask

module lfsr_tb();

    lfsr_if lif();
    driver drv;
    bit clk;
    
    
    lfsr #(.POLY_EQU(32'h4c11db7)) hash (
    
        .data_in(lif.data_in),
        .state_in(lif.state_in),
        .data_out(lif.data_out),
        .state_out(lif.state_out)
    
    );
    
    initial lif.clk = 0;
    
    always #5 lif.clk <= ~lif.clk;
    
    initial begin
    
        drv     = new();
        drv.lif = lif;
    
    end
    
    initial begin
    
        fork
            
            drv.run();
            end_tasks();
        
        join
    
    end

endmodule
