`timescale 1ns / 1ps

interface ip_eth_rx_if();

    logic clk;
    logic reset;

    logic          s_eth_hdr_valid;
    logic [15 : 0] s_eth_type;
    logic [47 : 0] s_eth_dest_mac;
    logic [47 : 0] s_eth_src_mac;
    

    logic [7 : 0]  s_eth_axi_payload_tdata;
    logic          s_eth_axi_payload_tvalid;
    logic          s_eth_axi_payload_tlast;  
    logic          s_eth_axi_payload_tuser;   
    logic          s_eth_hdr_ready;
    logic          s_eth_axi_payload_tready;
    
    logic           m_ip_hdr_ready;
    logic           m_ip_axi_payload_tready;
    logic [47 : 0]  m_eth_dest_mac;
    logic [47 : 0]  m_eth_src_mac;
    logic [15 : 0]  m_eth_type;
    
    logic           m_ip_hdr_valid;
    logic [3  : 0]  m_ip_version;
    logic [3  : 0]  m_ip_ihl;
    logic [5  : 0]  m_ip_dscp;
    logic [1  : 0]  m_ip_ecn;
    logic [15 : 0]  m_ip_len;       
    logic [15 : 0]  m_ip_iden;
    logic [2  : 0]  m_ip_flags;
    logic [12 : 0]  m_ip_frag_off;
    logic [7  : 0]  m_ip_ttl;
    logic [7  : 0]  m_ip_protocol;
    logic [15 : 0]  m_ip_checksum;
    logic [31 : 0]  m_ip_src_ip;
    logic [31 : 0]  m_ip_dest_ip;
    logic [7  : 0]  m_ip_axi_payload_tdata;
    logic           m_ip_axi_payload_tvalid;
    logic           m_ip_axi_payload_tlast;
    logic           m_ip_axi_payload_tuser;
    
    logic           busy;
    logic           err_invalid_hdr;
    logic           err_invalid_checksum;
    logic           err_hdr_early_termination;
    logic           err_payload_early_termination;
    
    modport master(
    
        output clk,
        output reset,
        output s_eth_hdr_valid,
        output s_eth_dest_mac,
        output s_eth_src_mac,
        output s_eth_type,
        output s_eth_axi_payload_tdata,
        output s_eth_axi_payload_tvalid,
        output s_eth_axi_payload_tlast,   
        output s_eth_axi_payload_tuser,   
        input  s_eth_hdr_ready,
        input  s_eth_axi_payload_tready,
        
        output m_ip_hdr_ready,
        output m_ip_axi_payload_tready,
        input  m_eth_dest_mac,
        input  m_eth_src_mac,
        input  m_eth_type, 
        
        //IP header fields
        input  m_ip_hdr_valid,
        input  m_ip_version,
        input  m_ip_ihl,
        input  m_ip_dscp,
        input  m_ip_ecn,
        input  m_ip_len,       
        input  m_ip_iden,
        input  m_ip_flags,
        input  m_ip_frag_off,
        input  m_ip_ttl,
        input  m_ip_protocol,
        input  m_ip_checksum,
        input  m_ip_src_ip,
        input  m_ip_dest_ip,
        input  m_ip_axi_payload_tdata,
        input  m_ip_axi_payload_tvalid,
        input  m_ip_axi_payload_tlast,
        input  m_ip_axi_payload_tuser,
        
        input  busy,
        input  err_invalid_hdr,
        input  err_invalid_checksum,
        input  err_hdr_early_termination,
        input  err_payload_early_termination
        
    );

endinterface

program ip_rx_driver(ip_eth_rx_if rxif);

    initial begin
    
        rxif.reset = 1'b0;
        @(posedge rxif.clk);
        rxif.reset = 1'b1;
        @(posedge rxif.clk);
        rxif.reset = 1'b0;
        
        @(posedge rxif.clk);
        wait(rxif.s_eth_hdr_ready);
        rxif.m_ip_hdr_ready  = 1'b1;
        @(posedge rxif.clk);
        rxif.s_eth_hdr_valid = 1'b1;
        rxif.s_eth_type      = 16'h0806;
        rxif.s_eth_dest_mac  = 48'hffffffffffff;
        rxif.s_eth_src_mac   = 48'h5A5B5C5D5E5F;
        
        @(posedge rxif.clk);
        wait(rxif.s_eth_axi_payload_tready);
        rxif.s_eth_hdr_valid          = 1'b0;
        rxif.m_ip_axi_payload_tready  = 1'b1;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h45;
        rxif.s_eth_axi_payload_tvalid = 1'b1;
        rxif.s_eth_axi_payload_tlast  = 1'b0;
        rxif.s_eth_axi_payload_tuser  = 1'b1;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tuser  = 1'b0;
        rxif.s_eth_axi_payload_tdata  = 8'h00;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h00;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h18;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h1c;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h46;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h40;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h00;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h40;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h06;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'hb2;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h0a;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'hac;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h10;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h0a;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h63;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'hac;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h10;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h0a;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'h0c;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'haa;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'hbb;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'hcc;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tdata  = 8'hdd;
        rxif.s_eth_axi_payload_tlast  = 1'b1;
        
        @(posedge rxif.clk);
        rxif.s_eth_axi_payload_tlast  = 1'b0;
        #50;
        $finish;
    
    end

endprogram

program ip_rx_monitor(ip_eth_rx_if rxif);

    initial begin
    
        forever begin
        
            @(posedge rxif.clk);
            wait(rxif.m_ip_hdr_valid);
            $display("IP Header");
            $display("IP Version : %0h", rxif.m_ip_version);
            $display("IHL : %0h", rxif.m_ip_ihl);
            $display("DSCP : %0h", rxif.m_ip_dscp);
            $display("ECN : %0h", rxif.m_ip_ecn);
            $display("Length : %0h", rxif.m_ip_len);
            $display("Identifiction : %0h", rxif.m_ip_iden);
            $display("Fragment Offset : %0h", rxif.m_ip_frag_off);
            $display("Time-To-Live : %0h", rxif.m_ip_ttl);
            $display("Protocol : %0h", rxif.m_ip_protocol);
            $display("Checksum : %0h", rxif.m_ip_checksum);
            $display("SourceIP : %0h", rxif.m_ip_src_ip);
            $display("DestinationIP : %0h", rxif.m_ip_dest_ip);
            $display("Invalid header : %0h", rxif.err_invalid_hdr);
            $display("ErrorChecksum : %0h", rxif.err_invalid_checksum);
            $display("Header Early Transmission : %0h", rxif.err_hdr_early_termination);
            $display("Payloas Early Transmission : %0h", rxif.err_payload_early_termination);
        
        end
    
    end
    
    initial begin
    
        forever begin
        
            @(posedge rxif.clk);
            wait(rxif.m_ip_axi_payload_tvalid);
            $display("IP Payload");
            $display("Data : %0h", rxif.m_ip_axi_payload_tdata);
            $display("Last : %0h", rxif.m_ip_axi_payload_tlast);
            $display("User : %0h", rxif.m_ip_axi_payload_tlast);
            $display("Invalid header : %0h", rxif.err_invalid_hdr);
            $display("ErrorChecksum : %0h", rxif.err_invalid_checksum);
            $display("Header Early Transmission : %0h", rxif.err_hdr_early_termination);
            $display("Payloas Early Transmission : %0h", rxif.err_payload_early_termination);
        
        end
    
    end

endprogram

module ip_eth_rx_tb();

    ip_eth_rx_if rxif();
    ip_rx_driver  drv(rxif);
    ip_rx_monitor mon(rxif);
    
    initial rxif.clk = 0;
    always #5 rxif.clk <= ~rxif.clk;
    
    ip_eth_rx ip_eth(
    
        .clk(rxif.clk),
        .reset(rxif.reset),
        
     
        .s_eth_hdr_valid(rxif.s_eth_hdr_valid),
        .s_eth_dest_mac(rxif.s_eth_dest_mac),
        .s_eth_src_mac(rxif.s_eth_src_mac),
        .s_eth_type(rxif.s_eth_type),
        
        .s_eth_axi_payload_tdata(rxif.s_eth_axi_payload_tdata),
        .s_eth_axi_payload_tvalid(rxif.s_eth_axi_payload_tvalid),
        .s_eth_axi_payload_tlast(rxif.s_eth_axi_payload_tlast),   
        .s_eth_axi_payload_tuser(rxif.s_eth_axi_payload_tuser),   
        .s_eth_hdr_ready(rxif.s_eth_hdr_ready),
        .s_eth_axi_payload_tready(rxif.s_eth_axi_payload_tready),
        
    
        .m_ip_hdr_ready(rxif.m_ip_hdr_ready),
        .m_ip_axi_payload_tready(rxif.m_ip_axi_payload_tready),
        .m_eth_dest_mac(rxif.m_eth_dest_mac),
        .m_eth_src_mac(rxif.m_eth_src_mac),
        .m_eth_type(rxif.m_eth_type), 
        
        .m_ip_hdr_valid(rxif.m_ip_hdr_valid),
        .m_ip_version(rxif.m_ip_version),
        .m_ip_ihl(rxif.m_ip_ihl),
        .m_ip_dscp(rxif.m_ip_dscp),
        .m_ip_ecn(rxif.m_ip_ecn),
        .m_ip_len(rxif.m_ip_len),       
        .m_ip_iden(rxif.m_ip_iden),
        .m_ip_flags(rxif.m_ip_flags),
        .m_ip_frag_off(rxif.m_ip_frag_off),
        .m_ip_ttl(rxif.m_ip_ttl),
        .m_ip_protocol(rxif.m_ip_protocol),
        .m_ip_checksum(rxif.m_ip_checksum),
        .m_ip_src_ip(rxif.m_ip_src_ip),
        .m_ip_dest_ip(rxif.m_ip_dest_ip),
        .m_ip_axi_payload_tdata(rxif.m_ip_axi_payload_tdata),
        .m_ip_axi_payload_tvalid(rxif.m_ip_axi_payload_tvalid),
        .m_ip_axi_payload_tlast(rxif.m_ip_axi_payload_tlast),
        .m_ip_axi_payload_tuser(rxif.m_ip_axi_payload_tuser),
        
    
        .busy(rxif.busy),
        .err_invalid_hdr(rxif.err_invalid_hdr),
        .err_invalid_checksum(rxif.err_invalid_checksum),
        .err_hdr_early_termination(rxif.err_hdr_early_termination),
        .err_payload_early_termination(rxif.err_payload_early_termination)
    
    );

endmodule
