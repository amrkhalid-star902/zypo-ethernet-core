`timescale 1ns / 1ps

interface ip_eth_tx_if();
    
    logic clk;
    logic reset;
    
    logic          m_eth_hdr_valid;
    logic [15 : 0] m_eth_type;
    logic [47 : 0] m_eth_dest_mac;
    logic [47 : 0] m_eth_src_mac;
    
    
    logic [7 : 0]  m_eth_axi_payload_tdata;
    logic          m_eth_axi_payload_tvalid;
    logic          m_eth_axi_payload_tlast;  
    logic          m_eth_axi_payload_tuser;   
    logic          m_eth_hdr_ready;
    logic          m_eth_axi_payload_tready;
    
    logic           s_ip_hdr_ready;
    logic           s_ip_axi_payload_tready;
    logic [47 : 0]  s_eth_dest_mac;
    logic [47 : 0]  s_eth_src_mac;
    logic [15 : 0]  s_eth_type;
    
    logic           s_ip_hdr_valid;
    logic [5  : 0]  s_ip_dscp;
    logic [1  : 0]  s_ip_ecn;
    logic [15 : 0]  s_ip_len;       
    logic [15 : 0]  s_ip_iden;
    logic [2  : 0]  s_ip_flags;
    logic [12 : 0]  s_ip_frag_off; 
    logic [7  : 0]  s_ip_ttl;
    logic [7  : 0]  s_ip_protocol;
    logic [31 : 0]  s_ip_src_ip;
    logic [31 : 0]  s_ip_dest_ip;
    logic [7  : 0]  s_ip_axi_payload_tdata;
    logic           s_ip_axi_payload_tvalid;
    logic           s_ip_axi_payload_tlast;
    logic           s_ip_axi_payload_tuser;
    
    logic           busy;
    logic           err_payload_early_termination;
    
    modport master(
    
        input  clk,
        input  reset,
        input  m_eth_hdr_valid,
        input  m_eth_dest_mac,
        input  m_eth_src_mac,
        input  m_eth_type,
        input  m_eth_axi_payload_tdata,
        input  m_eth_axi_payload_tvalid,
        input  m_eth_axi_payload_tlast,   
        input  m_eth_axi_payload_tuser,   
        output m_eth_hdr_ready,
        output m_eth_axi_payload_tready,
        
        input  s_ip_hdr_ready,
        input  s_ip_axi_payload_tready,
        output s_eth_dest_mac,
        output s_eth_src_mac,
        output s_eth_type, 
        
        //IP header fields
        output s_ip_hdr_valid,
        output s_ip_dscp,
        output s_ip_ecn,
        output s_ip_len,       
        output s_ip_iden,
        output s_ip_flags,
        output s_ip_frag_off,
        output s_ip_ttl,
        output s_ip_protocol,
        output s_ip_src_ip,
        output s_ip_dest_ip,
        output s_ip_axi_payload_tdata,
        output s_ip_axi_payload_tvalid,
        output s_ip_axi_payload_tlast,
        output s_ip_axi_payload_tuser,
        
        input  busy,
        input  err_payload_early_termination
        
    );


endinterface

program ip_tx_driver(ip_eth_tx_if txif);

    initial begin
    
        txif.reset = 1'b0;
        txif.s_ip_axi_payload_tvalid = 1'b0;
        txif.s_ip_axi_payload_tlast  = 1'b0;
        txif.s_ip_axi_payload_tuser  = 1'b0;
        @(posedge txif.clk);
        txif.reset = 1'b1;
        @(posedge txif.clk);
        txif.reset = 1'b0;
        
        @(posedge txif.clk);
        wait(txif.s_ip_hdr_ready);
        txif.m_eth_hdr_ready          = 1'b1;
        txif.m_eth_axi_payload_tready = 1'b1;
        
        @(posedge txif.clk);
        txif.s_eth_dest_mac = 48'hffffffffffff;
        txif.s_eth_src_mac  = 48'haabbccddeeff;
        txif.s_eth_type     = 16'h0806;
        txif.s_ip_dscp      = 0;
        txif.s_ip_ecn       = 0;
        txif.s_ip_len       = 16'h18;
        txif.s_ip_iden      = 16'h4536;
        txif.s_ip_flags     = 3'h2;
        txif.s_ip_frag_off  = 0;
        txif.s_ip_ttl       = 8'h40;
        txif.s_ip_protocol  = 8'h11;
        txif.s_ip_src_ip    = 32'h11223344;
        txif.s_ip_dest_ip   = 32'h11223355;
        
        @(posedge txif.clk);
        txif.s_ip_hdr_valid          = 1'b1;
        
        @(posedge txif.clk);
        wait(txif.s_ip_axi_payload_tready);
        txif.s_ip_hdr_valid          = 1'b0;
        txif.s_ip_axi_payload_tdata  = 8'h5a;
        txif.s_ip_axi_payload_tvalid = 1'b1;
        txif.s_ip_axi_payload_tlast  = 1'b0;
        txif.s_ip_axi_payload_tuser  = 1'b1;
        
        @(posedge txif.clk);
        txif.s_ip_axi_payload_tdata  = 8'h5b;
        txif.s_ip_axi_payload_tuser  = 1'b0;
        
        @(posedge txif.clk);
        txif.s_ip_axi_payload_tdata  = 8'h5c;
        
        @(posedge txif.clk);
        txif.s_ip_axi_payload_tdata  = 8'h5d;
        txif.s_ip_axi_payload_tlast  = 1'b1;
        
        @(posedge txif.clk);
        txif.s_ip_axi_payload_tvalid = 1'b0;
        txif.s_ip_axi_payload_tlast  = 1'b0;
        
        wait(txif.m_eth_axi_payload_tlast);
        #10;
        $finish;
    
    end

endprogram

program ip_tx_monitor(ip_eth_tx_if txif);

    initial begin
    
        forever begin
        
            @(posedge txif.clk);
            wait(txif.m_eth_hdr_valid);
            $display("Destination MAC: %0h", txif.m_eth_dest_mac);
            $display("Source MAC: %0h", txif.m_eth_src_mac);
            $display("ETH Type: %0h", txif.m_eth_type);
            $display("Header Fields: %0h", txif.m_eth_axi_payload_tdata);
            
        
        end
    
    end
    
    initial begin
    
        forever begin
        
            @(posedge txif.clk);
            wait(txif.m_eth_axi_payload_tvalid);
            $display("Payload Data: %0h", txif.m_eth_axi_payload_tdata);
        
        end
    
    end

endprogram

module ip_eth_tx_tb();

    ip_eth_tx_if txif();
    ip_tx_driver  drv(txif);
    ip_tx_monitor mon(txif);
    
    initial txif.clk = 0;
    always #5 txif.clk <= ~txif.clk;

    ip_eth_tx ip_eth_tx(
    
        .clk(txif.clk),
        .reset(txif.reset),
        
     
        .m_eth_hdr_valid(txif.m_eth_hdr_valid),
        .m_eth_dest_mac(txif.m_eth_dest_mac),
        .m_eth_src_mac(txif.m_eth_src_mac),
        .m_eth_type(txif.m_eth_type),
        
        .m_eth_axi_payload_tdata(txif.m_eth_axi_payload_tdata),
        .m_eth_axi_payload_tvalid(txif.m_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(txif.m_eth_axi_payload_tlast),   
        .m_eth_axi_payload_tuser(txif.m_eth_axi_payload_tuser),   
        .m_eth_hdr_ready(txif.m_eth_hdr_ready),
        .m_eth_axi_payload_tready(txif.m_eth_axi_payload_tready),
        
    
        .s_ip_hdr_ready(txif.s_ip_hdr_ready),
        .s_ip_axi_payload_tready(txif.s_ip_axi_payload_tready),
        .s_eth_dest_mac(txif.s_eth_dest_mac),
        .s_eth_src_mac(txif.s_eth_src_mac),
        .s_eth_type(txif.s_eth_type), 
        
        .s_ip_hdr_valid(txif.s_ip_hdr_valid),
        .s_ip_dscp(txif.s_ip_dscp),
        .s_ip_ecn(txif.s_ip_ecn),
        .s_ip_len(txif.s_ip_len),       
        .s_ip_iden(txif.s_ip_iden),
        .s_ip_flags(txif.s_ip_flags),
        .s_ip_frag_off(txif.s_ip_frag_off),
        .s_ip_ttl(txif.s_ip_ttl),
        .s_ip_protocol(txif.s_ip_protocol),
        .s_ip_src_ip(txif.s_ip_src_ip),
        .s_ip_dest_ip(txif.s_ip_dest_ip),
        .s_ip_axi_payload_tdata(txif.s_ip_axi_payload_tdata),
        .s_ip_axi_payload_tvalid(txif.s_ip_axi_payload_tvalid),
        .s_ip_axi_payload_tlast(txif.s_ip_axi_payload_tlast),
        .s_ip_axi_payload_tuser(txif.s_ip_axi_payload_tuser),
        
    
        .busy(txif.busy),
        .err_payload_early_termination(txif.err_payload_early_termination)
    
    );

endmodule
