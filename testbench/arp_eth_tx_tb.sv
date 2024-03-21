`timescale 1ns / 1ps

interface eth_tx_if#(parameter DATAW = 64, parameter TDATAW = DATAW/8)();

    logic clk;
    logic reset;

    logic                m_eth_hdr_valid;
    logic [15 : 0]       m_eth_type;
    logic [47 : 0]       m_eth_dest_mac;
    logic [47 : 0]       m_eth_src_mac;
    

    logic [DATAW-1 : 0]  m_eth_axi_payload_tdata;
    logic [TDATAW-1 : 0] m_eth_axi_payload_tkeep;
    logic                m_eth_axi_payload_tvalid;
    logic                m_eth_axi_payload_tlast;  
    logic                m_eth_axi_payload_tuser;   
    logic                m_eth_hdr_ready;
    logic                m_eth_axi_payload_tready;
    
    logic                s_frame_ready;
    logic                s_frame_valid;
    logic [47 : 0]       s_eth_dest_mac;
    logic [47 : 0]       s_eth_src_mac;
    logic [15 : 0]       s_eth_type;   
    
    logic [15 : 0]       s_arp_htype;
    logic [15 : 0]       s_arp_ptype;
    logic [15 : 0]       s_arp_oper;
    logic [47 : 0]       s_arp_sha;
    logic [31 : 0]       s_arp_spa;
    logic [47 : 0]       s_arp_tha;
    logic [31 : 0]       s_arp_tpa;
    
    logic                busy;

    
    modport master(
        
        output clk,
        output reset,
        output m_eth_hdr_ready,
        output m_eth_axi_payload_tready,
        input  m_eth_hdr_valid,
        input  m_eth_dest_mac,
        input  m_eth_src_mac,
        input  m_eth_type,
        input  m_eth_axi_payload_tdata,
        input  m_eth_axi_payload_tkeep,
        input  m_eth_axi_payload_tvalid,
        input  m_eth_axi_payload_tlast,   
        input  m_eth_axi_payload_tuser,   

        
        input  s_frame_ready,
        output s_frame_valid,
        output s_eth_dest_mac,
        output s_eth_src_mac,
        output s_eth_type,   
        output s_arp_htype,
        output s_arp_ptype,
        output s_arp_oper,
        output s_arp_sha,
        output s_arp_spa,
        output s_arp_tha,
        output s_arp_tpa,
        
        input  busy
    
    );

endinterface

program driver_tx(eth_tx_if txif);
    
    initial begin
    
        txif.reset = 1'b0;
        @(posedge txif.clk);
        txif.reset = 1'b1;
        @(posedge txif.clk);
        txif.reset = 1'b0;
        
        @(posedge txif.clk);
        wait(txif.s_frame_ready);
        txif.m_eth_hdr_ready          = 1'b1;
        txif.m_eth_axi_payload_tready = 1'b1;
        txif.s_frame_ready            = 1'b1;
        
        @(posedge txif.clk);
        txif.s_eth_dest_mac = 48'hffffffffffff;
        txif.s_eth_src_mac  = 48'haabbccddeeff;
        txif.s_eth_type     = 16'h0806;
        txif.s_arp_htype    = 1;
        txif.s_arp_ptype    = 16'h0800;
        txif.s_arp_oper     = 1; 
        txif.s_arp_sha      = 48'haabbccddeeff;
        txif.s_arp_spa      = 32'h32456789;
        txif.s_arp_tha      = 48'hffffffffffff;
        txif.s_arp_tpa      = 32'h67854321;
        
        @(posedge txif.clk);
        txif.s_frame_valid            = 1'b1;
        
        #50;
        $finish;
        
    
    end

endprogram

program monitor_tx(eth_tx_if txif);

    initial begin
        
        forever begin
        
            @(posedge txif.clk);
            wait(txif.m_eth_axi_payload_tvalid);
            $display("PayLoad Data = %0h , Valid_Bytes = %0h", txif.m_eth_axi_payload_tdata, txif.m_eth_axi_payload_tkeep);
            
        end
    
    end

endprogram

module arp_eth_tx_tb();
    
    eth_tx_if txif();

    driver_tx  drv (txif);
    monitor_tx mon (txif);
    
    initial txif.clk = 0;
    always #5 txif.clk <= ~txif.clk;
    
    arp_eth_tx#(
    
        .DATAW(64)
    
    )arp_tx(
    
        .clk(txif.clk),
        .reset(txif.reset),
        .m_eth_hdr_valid(txif.m_eth_hdr_valid),
        .m_eth_dest_mac(txif.m_eth_dest_mac),
        .m_eth_src_mac(txif.m_eth_src_mac),
        .m_eth_type(txif.m_eth_type),
    
        .m_eth_axi_payload_tdata(txif.m_eth_axi_payload_tdata),
        .m_eth_axi_payload_tkeep(txif.m_eth_axi_payload_tkeep),
        .m_eth_axi_payload_tvalid(txif.m_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(txif.m_eth_axi_payload_tlast),   
        .m_eth_axi_payload_tuser(txif.m_eth_axi_payload_tuser),   
        .m_eth_hdr_ready(txif.m_eth_hdr_ready),
        .m_eth_axi_payload_tready(txif.m_eth_axi_payload_tready),
        
    
        .s_frame_ready(txif.s_frame_ready),
        .s_frame_valid(txif.s_frame_valid),
        .s_eth_dest_mac(txif.s_eth_dest_mac),
        .s_eth_src_mac(txif.s_eth_src_mac),
        .s_eth_type(txif.s_eth_type),   
      
        .s_arp_htype(txif.s_arp_htype),
        .s_arp_ptype(txif.s_arp_ptype),
        .s_arp_oper(txif.s_arp_oper),
        .s_arp_sha(txif.s_arp_sha),
        .s_arp_spa(txif.s_arp_spa),
        .s_arp_tha(txif.s_arp_tha),
        .s_arp_tpa(txif.s_arp_tpa),
        
        .busy(txif.busy)
    
    );

endmodule
