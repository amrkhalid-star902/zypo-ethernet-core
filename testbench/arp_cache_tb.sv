`timescale 1ns / 1ps


interface cache_if();
    
    logic           clk;
    logic           reset;
    logic           query_req_valid;
    logic           query_req_ready;
    logic [31 : 0]  query_req_ip;
    logic           query_rsp_valid;
    logic           query_rsp_ready;
    logic           query_rsp_err;
    logic [47 : 0]  query_rsp_mac;
    logic           write_req_valid;
    logic           write_req_ready;
    logic [31 : 0]  write_req_ip;
    logic [47 : 0]  write_req_mac;
    logic           clear_cache;
    
    modport master(
        
        output clk,
        output reset,
        output query_req_valid,
        output query_req_ip,
        output query_rsp_ready,
        output write_req_valid,
        output write_req_ip,
        output write_req_mac,
        output clear_cache,
        
        input  query_req_ready,
        input  query_rsp_valid,
        input  query_rsp_err,
        input  query_rsp_mac,
        input  write_req_ready
        
    );
    

endinterface


class cache_driver;

    virtual cache_if cif;
    
    task run();
    
        cif.reset       = 1'b0;
        cif.clear_cache = 1'b0;
        @(posedge cif.clk);
        cif.reset       = 1'b1;
        @(posedge cif.clk);
        cif.reset       = 1'b0;
        
        wait(cif.write_req_ready);
        cif.write_req_valid = 1'b1;
        cif.write_req_ip  = 32'hc0a80111;
        cif.write_req_mac = 48'haabbccddee;
        
        @(posedge cif.clk);
        cif.query_req_valid = 1'b1;
        cif.query_req_ip    = 32'hc0a80111;
        cif.query_rsp_ready = 1'b1;
        
        @(posedge cif.clk);
        cif.query_req_valid = 1'b0;
        
        wait(cif.query_rsp_valid);
        assert(cif.query_rsp_mac == 48'haabbccddee) $display("Test Case1 Passed");
        else $error("Test Case1 Failed");
        
        @(posedge cif.clk);
        cif.query_req_valid = 1'b1;
        cif.query_req_ip    = 32'hc0a80112;
        cif.query_rsp_ready = 1'b1;
        
        @(posedge cif.clk);
        cif.query_req_valid = 1'b0;

        wait(cif.query_rsp_valid);
        assert(cif.query_rsp_err == 1'b1) $display("Test Case2 Passed");
        else $error("Test Case2 Failed");
        
        @(posedge cif.clk);
        wait(cif.write_req_ready);
        cif.write_req_valid = 1'b1;
        cif.write_req_ip  = 32'hc0a80112;
        cif.write_req_mac = 48'h111abcdef;
        
        @(posedge cif.clk);
        cif.query_req_valid = 1'b1;
        cif.query_req_ip    = 32'hc0a80112;
        cif.query_rsp_ready = 1'b1;
        
        @(posedge cif.clk);
        cif.query_req_valid = 1'b0;

        wait(cif.query_rsp_valid);
        assert(cif.query_rsp_mac == 48'h111abcdef) $display("Test Case3 Passed");
        else $error("Test Case3 Failed");
        
        //overwrite c0a80112 address
        @(posedge cif.clk);
        wait(cif.write_req_ready);
        cif.write_req_valid = 1'b1;
        cif.write_req_ip  = 32'hc0a80123;
        cif.write_req_mac = 48'hc0a80123;
        
        @(posedge cif.clk);
        cif.query_req_valid = 1'b1;
        cif.query_req_ip    = 32'hc0a80112;
        cif.query_rsp_ready = 1'b1;
        
        @(posedge cif.clk);
        cif.query_req_valid = 1'b0;

        wait(cif.query_rsp_valid);
        //not in cache overwritten
        assert(cif.query_rsp_err == 1'b1) $display("Test Case4 Passed");
        else $error("Test Case4 Failed");
        
        $finish;

    endtask
    
    
    
endclass


module arp_cache_tb();

    cache_if cif();
    cache_driver drv;
    
    initial cif.clk = 0;
    
    initial begin
    
        drv = new();
        drv.cif = cif;
    
    end
    
    always #5 cif.clk <= ~cif.clk;
    
    arb_cache#(
    
        .CACHE_ADDRW(8)
    
    )cache(
    
        .clk(cif.clk),
        .reset(cif.reset),
        .clear_cache(cif.clear_cache),
        
        //Query Request Signals
        .query_req_valid(cif.query_req_valid),
        .query_req_ip(cif.query_req_ip),
        .query_req_ready(cif.query_req_ready),
        
        //Query Response Signals
        .query_rsp_ready(cif.query_rsp_ready),
        .query_rsp_valid(cif.query_rsp_valid),
        .query_rsp_err(cif.query_rsp_err),
        .query_rsp_mac(cif.query_rsp_mac),
        
        //Write Request Signals
        .write_req_valid(cif.write_req_valid),
        .write_req_ip(cif.write_req_ip),
        .write_req_mac(cif.write_req_mac),
        .write_req_ready(cif.write_req_ready)
        
    );
    
    initial begin

        drv.run();

    end


endmodule
