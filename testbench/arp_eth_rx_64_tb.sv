`timescale 1ns / 1ps


interface eth_rx_64_if#(parameter DATAW = 64, parameter TDATAW = DATAW/8)();

    logic clk;
    logic reset;

    logic                s_eth_hdr_valid;
    logic [15 : 0]       s_eth_type;
    logic [47 : 0]       s_eth_dest_mac;
    logic [47 : 0]       s_eth_src_mac;
    

    logic [DATAW-1 : 0]  s_eth_axi_payload_tdata;
    logic [TDATAW-1 : 0] s_eth_axi_payload_tkeep;
    logic                s_eth_axi_payload_tvalid;
    logic                s_eth_axi_payload_tlast;  
    logic                s_eth_axi_payload_tuser;   
    logic                s_eth_hdr_ready;
    logic                s_eth_axi_payload_tready;
    
    logic                m_frame_ready;
    logic                m_frame_valid;
    logic [47 : 0]       m_eth_dest_mac;
    logic [47 : 0]       m_eth_src_mac;
    logic [15 : 0]       m_eth_type;   
    
    logic [15 : 0]       m_arp_htype;
    logic [15 : 0]       m_arp_ptype;
    logic [7  : 0]       m_arp_hlen;
    logic [7  : 0]       m_arp_plen;
    logic [15 : 0]       m_arp_oper;
    logic [47 : 0]       m_arp_sha;
    logic [31 : 0]       m_arp_spa;
    logic [47 : 0]       m_arp_tha;
    logic [31 : 0]       m_arp_tpa;
    
    logic                busy;
    logic                err_invalid_hdr;
    logic                err_hdr_early_termination;
    
    modport master(
        
        output  clk,
        output  reset,
        output  s_eth_hdr_valid,
        output  s_eth_dest_mac,
        output  s_eth_src_mac,
        output  s_eth_type,
        output  s_eth_axi_payload_tdata,
        output  s_eth_axi_payload_tkeep,
        output  s_eth_axi_payload_tvalid,
        output  s_eth_axi_payload_tlast,   
        output  s_eth_axi_payload_tuser,   
        input   s_eth_hdr_ready,
        input   s_eth_axi_payload_tready,
        
        output m_frame_ready,
        input  m_frame_valid,
        input  m_eth_dest_mac,
        input  m_eth_src_mac,
        input  m_eth_type,   
        input  m_arp_htype,
        input  m_arp_ptype,
        input  m_arp_hlen,
        input  m_arp_plen,
        input  m_arp_oper,
        input  m_arp_sha,
        input  m_arp_spa,
        input  m_arp_tha,
        input  m_arp_tpa,
        
        input  busy,
        input  err_invalid_hdr,
        input  err_hdr_early_termination
    
    );

endinterface

program driver_64(eth_rx_64_if rxif);

    initial begin
    
        rxif.reset = 1'b0;
        @(posedge rxif.clk);
        rxif.reset = 1'b1;
        @(posedge rxif.clk);
        rxif.reset = 1'b0;
        
        @(posedge rxif.clk);
        wait(rxif.s_eth_hdr_ready);
        rxif.s_eth_hdr_valid = 1'b1;
        rxif.s_eth_type      = 16'h0806;
        rxif.s_eth_dest_mac  = 48'hffffffffffff;
        rxif.s_eth_src_mac   = 48'h445566778899;
        
        @(posedge rxif.clk);
        wait(rxif.s_eth_axi_payload_tready);
        rxif.s_eth_hdr_valid          = 1'b0;
        rxif.m_frame_ready            = 1'b1;
        rxif.s_eth_axi_payload_tvalid = 1'b1;
        rxif.s_eth_axi_payload_tuser  = 1'b1;
        rxif.s_eth_axi_payload_tdata  = 64'h0100040608000100;
        rxif.s_eth_axi_payload_tkeep  = 8'hff;
        rxif.s_eth_axi_payload_tlast  = 1'b0;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 64'h3344445566778899;
        rxif.s_eth_axi_payload_tuser  = 1'b0;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 64'hffffffffffff1122;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 64'h12674523;
        rxif.s_eth_axi_payload_tkeep  = 8'h0f;
        rxif.s_eth_axi_payload_tlast  = 1'b1;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tvalid = 1'b0;
        
        @(posedge rxif.clk);
        $finish;
        
        
    
    end

endprogram

program monitor_64(eth_rx_64_if rxif);

    initial begin
    
        forever begin
            
            @(posedge rxif.clk);
            wait(rxif.m_frame_valid);
            $display("Output Frame");
            $display("Destantion MAC = %0h", rxif.m_eth_dest_mac);
            $display("Source MAC = %0h", rxif.m_eth_src_mac);
            $display("Ether Type = %0h", rxif.m_eth_type);
            $display("Htype = %0h", rxif.m_arp_htype);
            $display("Ptype = %0h", rxif.m_arp_ptype);
            $display("HLEN = %0h", rxif.m_arp_hlen);
            $display("PLEN = %0h", rxif.m_arp_plen);
            $display("OPER = %0h", rxif.m_arp_oper);
            $display("SHA = %0h", rxif.m_arp_sha);
            $display("SPA = %0h", rxif.m_arp_spa);
            $display("THA = %0h", rxif.m_arp_tha);
            $display("TPA = %0h", rxif.m_arp_tpa);
            $display("Invalid Header = %0h", rxif.err_invalid_hdr);
            $display("Err Termenation = %0h", rxif.err_hdr_early_termination);
            
        
        end
    
    end

endprogram

module arp_eth_rx_64_tb();

    eth_rx_64_if rxif();
    
    driver_64  drv64 (rxif);
    monitor_64 mon64 (rxif);
    
    initial rxif.clk = 0;
    always #5 rxif.clk <= ~rxif.clk;


    arp_eth_rx#(
    
        .DATAW(64)
    
    )arp_rx(
    
        .clk(rxif.clk),
        .reset(rxif.reset),
        .s_eth_hdr_valid(rxif.s_eth_hdr_valid),
        .s_eth_dest_mac(rxif.s_eth_dest_mac),
        .s_eth_src_mac(rxif.s_eth_src_mac),
        .s_eth_type(rxif.s_eth_type),
    
        .s_eth_axi_payload_tdata(rxif.s_eth_axi_payload_tdata),
        .s_eth_axi_payload_tkeep(rxif.s_eth_axi_payload_tkeep),
        .s_eth_axi_payload_tvalid(rxif.s_eth_axi_payload_tvalid),
        .s_eth_axi_payload_tlast(rxif.s_eth_axi_payload_tlast),   
        .s_eth_axi_payload_tuser(rxif.s_eth_axi_payload_tuser),   
        .s_eth_hdr_ready(rxif.s_eth_hdr_ready),
        .s_eth_axi_payload_tready(rxif.s_eth_axi_payload_tready),
        
    
        .m_frame_ready(rxif.m_frame_ready),
        .m_frame_valid(rxif.m_frame_valid),
        .m_eth_dest_mac(rxif.m_eth_dest_mac),
        .m_eth_src_mac(rxif.m_eth_src_mac),
        .m_eth_type(rxif.m_eth_type),   
      
        .m_arp_htype(rxif.m_arp_htype),
        .m_arp_ptype(rxif.m_arp_ptype),
        .m_arp_hlen(rxif.m_arp_hlen),
        .m_arp_plen(rxif.m_arp_plen),
        .m_arp_oper(rxif.m_arp_oper),
        .m_arp_sha(rxif.m_arp_sha),
        .m_arp_spa(rxif.m_arp_spa),
        .m_arp_tha(rxif.m_arp_tha),
        .m_arp_tpa(rxif.m_arp_tpa),
        
        .busy(rxif.busy),
        .err_invalid_hdr(rxif.err_invalid_hdr),
        .err_hdr_early_termination(rxif.err_hdr_early_termination)
    
    );

endmodule
