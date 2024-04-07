`timescale 1ns / 1ps

interface ip_full_if();
    
    logic clk;
    logic reset;
    
    logic [47 : 0] local_mac;
    logic [31 : 0]  local_ip;
    logic [31 : 0]  gateway_ip;
    logic [31 : 0]  subnet_mask;
    logic           clear_cache;
    
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
    logic           s_ip_hdr_valid;
    logic [5  : 0]  s_ip_dscp;
    logic [1  : 0]  s_ip_ecn;
    logic [15 : 0]  s_ip_len;       
    logic [7  : 0]  s_ip_ttl;
    logic [7  : 0]  s_ip_protocol;
    logic [31 : 0]  s_ip_src_ip;
    logic [31 : 0]  s_ip_dest_ip;
    logic [7  : 0]  s_ip_axi_payload_tdata;
    logic           s_ip_axi_payload_tvalid;
    logic           s_ip_axi_payload_tlast;
    logic           s_ip_axi_payload_tuser;
    
    logic           m_ip_hdr_ready;
    logic           m_ip_axi_payload_tready;
    logic [47 : 0]  m_ip_eth_dest_mac;
    logic [47 : 0]  m_ip_eth_src_mac;
    logic [15 : 0]  m_ip_eth_type;
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
    
    logic           rx_busy;
    logic           tx_busy;
    logic           rx_err_invalid_hdr;
    logic           rx_err_invalid_checksum;
    logic           rx_err_hdr_early_termination;
    logic           rx_err_payload_early_termination;
    logic           tx_err_payload_early_termination;
    logic           tx_err_arp_failed;
    
    modport master(
    
        output clk,
        output reset,
        
        output local_mac,
        output local_ip,
        output gateway_ip,
        output subnet_mask,
        output clear_cache,
        
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
        output s_ip_hdr_valid,
        output s_ip_dscp,
        output s_ip_ecn,
        output s_ip_len,       
        output s_ip_ttl,
        output s_ip_protocol,
        output s_ip_src_ip,
        output s_ip_dest_ip,
        output s_ip_axi_payload_tdata,
        output s_ip_axi_payload_tvalid,
        output s_ip_axi_payload_tlast,
        output s_ip_axi_payload_tuser,
        
        output m_ip_hdr_ready,
        output m_ip_axi_payload_tready,
        input  m_ip_eth_dest_mac,
        input  m_ip_eth_src_mac,
        input  m_ip_eth_type, 
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
        
        output rx_busy,
        output tx_busy,
        output rx_err_invalid_hdr,
        output rx_err_invalid_checksum,
        output rx_err_hdr_early_termination,
        output rx_err_payload_early_termination,
        output tx_err_payload_early_termination,
        output tx_err_arp_failed
    
    );

endinterface

program driver_ip_full(ip_full_if ipif);
    
    initial begin
    
        ipif.reset = 1'b0;
        @(posedge ipif.clk);
        ipif.reset = 1'b1;
        @(posedge ipif.clk);
        ipif.reset = 1'b0;
        
        ipif.m_eth_hdr_ready          = 1'b1;
        ipif.m_eth_axi_payload_tready = 1'b1;
        
        //Receive IP packet
        @(posedge ipif.clk);
        wait(ipif.s_eth_hdr_ready);
        $display("IP Rx send ETH header");
        ipif.m_ip_hdr_ready  = 1'b1;
        
        @(posedge ipif.clk);
        ipif.s_eth_hdr_valid = 1'b1;
        ipif.s_eth_type      = 16'h0800;
        ipif.s_eth_dest_mac  = 48'hffffffffffff;
        ipif.s_eth_src_mac   = 48'hDADBDCD1DEDF;
        
        @(posedge ipif.clk);
        wait(ipif.s_eth_axi_payload_tready);
        $display("IP Rx send IP header");
        ipif.s_eth_hdr_valid          = 1'b0;
        ipif.m_ip_axi_payload_tready  = 1'b1;
        
        //Send different IP Header fields
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h45;
        ipif.s_eth_axi_payload_tvalid = 1'b1;
        ipif.s_eth_axi_payload_tlast  = 1'b0;
        ipif.s_eth_axi_payload_tuser  = 1'b1;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tuser  = 1'b0;
        ipif.s_eth_axi_payload_tdata  = 8'h00;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h00;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h18;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h1c;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h46;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h40;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h00;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h40;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h06;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'hb2;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h0a;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'hac;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h10;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h0a;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h63;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'hac;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h10;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h0a;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'h0c;
        
        //Send IP payload
        @(posedge ipif.clk);
        $display("IP Rx send IP payload data");
        ipif.s_eth_axi_payload_tdata  = 8'haa;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'hbb;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'hcc;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tdata  = 8'hdd;
        ipif.s_eth_axi_payload_tlast  = 1'b1;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tvalid = 1'b0;
        ipif.s_eth_axi_payload_tlast  = 1'b0;
        
        //Send ARP Request
        @(posedge ipif.clk);
        wait(ipif.s_eth_hdr_ready);
        $display("Send ARP Packet");
        ipif.s_eth_hdr_valid = 1'b1;
        ipif.s_eth_type      = 16'h0806;
        ipif.s_eth_dest_mac  = 48'hffffffffffff;
        ipif.s_eth_src_mac   = 48'hB1B2B3B4B5B6;
        
        @(posedge ipif.clk);
        wait(ipif.s_eth_axi_payload_tready);
        ipif.s_eth_hdr_valid          = 1'b0;
        ipif.s_eth_axi_payload_tvalid = 1'b1;
        ipif.s_eth_axi_payload_tuser  = 1'b0;
        ipif.s_eth_axi_payload_tdata  = 0;
        ipif.s_eth_axi_payload_tlast  = 1'b0;
        
        @(posedge ipif.clk);
        //HTYPE
        ipif.s_eth_axi_payload_tdata  = 1;
        ipif.s_eth_axi_payload_tuser  = 1'b0;
        
        @(posedge ipif.clk);
        //PTYPR
        ipif.s_eth_axi_payload_tdata  = 8'h08;
        
        @(posedge ipif.clk);
        //PTYPR
        ipif.s_eth_axi_payload_tdata  = 0;
        
        @(posedge ipif.clk);
        //HLEN
        ipif.s_eth_axi_payload_tdata  = 8'h06;
        
        @(posedge ipif.clk);
        //PLEN
        ipif.s_eth_axi_payload_tdata  = 8'h04;
        
        @(posedge ipif.clk);
        //OPER
        ipif.s_eth_axi_payload_tdata  = 8'h00;
        
        @(posedge ipif.clk);
        //OPER
        ipif.s_eth_axi_payload_tdata  = 8'h01;
        
        @(posedge ipif.clk);
        //SHA
        ipif.s_eth_axi_payload_tdata  = 8'hB1;
        
        @(posedge ipif.clk);
        //SHA
        ipif.s_eth_axi_payload_tdata  = 8'hB2;
        
        @(posedge ipif.clk);
        //SHA
        ipif.s_eth_axi_payload_tdata  = 8'hB3;
        
        @(posedge ipif.clk);
        //SHA
        ipif.s_eth_axi_payload_tdata  = 8'hB4;
        
        @(posedge ipif.clk);
        //SHA
        ipif.s_eth_axi_payload_tdata  = 8'hB5;
        
        @(posedge ipif.clk);
        //SHA
        ipif.s_eth_axi_payload_tdata  = 8'hB6;
        
        @(posedge ipif.clk);
        //SPA
        ipif.s_eth_axi_payload_tdata  = 8'hC0;
        
        @(posedge ipif.clk);
        //SPA
        ipif.s_eth_axi_payload_tdata  = 8'hA8;
        
        @(posedge ipif.clk);
        //SPA
        ipif.s_eth_axi_payload_tdata  = 8'h01;
        
        @(posedge ipif.clk);
        //SPA
        ipif.s_eth_axi_payload_tdata  = 8'h66;
        
        @(posedge ipif.clk);
        //THA
        ipif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge ipif.clk);
        //THA
        ipif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge ipif.clk);
        //THA
        ipif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge ipif.clk);
        //THA
        ipif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge ipif.clk);
        //THA
        ipif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge ipif.clk);
        //THA
        ipif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge ipif.clk);
        //TPA
        ipif.s_eth_axi_payload_tdata  = 8'hC0;
        
        @(posedge ipif.clk);
        //TPA
        ipif.s_eth_axi_payload_tdata  = 8'hA8;
        
        @(posedge ipif.clk);
        //TPA
        ipif.s_eth_axi_payload_tdata  = 8'h01;
        
        @(posedge ipif.clk);
        //TPA
        ipif.s_eth_axi_payload_tdata  = 8'h64;
        ipif.s_eth_axi_payload_tlast  = 1'b1;
        
        @(posedge ipif.clk);
        ipif.s_eth_axi_payload_tvalid = 1'b0;
        ipif.s_eth_axi_payload_tlast  = 1'b0;
        
        wait(ipif.m_eth_axi_payload_tlast);
        $display("ARP Sent Succeffully");
        
        //Transmit IP packet
        @(posedge ipif.clk);
        wait(!(ipif.s_ip_hdr_ready));
        $display("IP TX send ETH IP header");
        ipif.s_ip_hdr_valid           = 1'b1;
        ipif.s_ip_dscp                = 0;
        ipif.s_ip_ecn                 = 0;
        ipif.s_ip_len                 = 16'h18;
        ipif.s_ip_ttl                 = 8'h40;
        ipif.s_ip_protocol            = 8'h11;
        ipif.s_ip_src_ip              = 32'hc0a80161;
        ipif.s_ip_dest_ip             = 32'hc0a80166;
        
        @(posedge ipif.clk);
        wait(ipif.s_ip_axi_payload_tready);
        $display("IP TX send ETH IP payload data");
        ipif.s_ip_hdr_valid          = 1'b0;
        ipif.s_ip_axi_payload_tdata  = 8'h5a;
        ipif.s_ip_axi_payload_tvalid = 1'b1;
        ipif.s_ip_axi_payload_tlast  = 1'b0;
        ipif.s_ip_axi_payload_tuser  = 1'b1;
        
        @(posedge ipif.clk);
        ipif.s_ip_axi_payload_tdata  = 8'h5b;
        ipif.s_ip_axi_payload_tuser  = 1'b0;
        
        @(posedge ipif.clk);
        ipif.s_ip_axi_payload_tdata  = 8'h5c;
        
        @(posedge ipif.clk);
        ipif.s_ip_axi_payload_tdata  = 8'h5d;
        ipif.s_ip_axi_payload_tlast  = 1'b1;
        
        @(posedge ipif.clk);
        ipif.s_ip_axi_payload_tvalid = 1'b0;
        ipif.s_ip_axi_payload_tlast  = 1'b0;
        
        wait(ipif.m_eth_axi_payload_tlast);
        #10;
        $finish;
    
        
    end  

endprogram

program intialize_ip_full(ip_full_if ipif);

    initial begin
        
        ipif.local_mac                         = 48'h5A5152535455;
		ipif.local_ip                          = 32'hc0a80164;
		ipif.gateway_ip                        = 32'hc0a80101;
		ipif.subnet_mask                       = 32'hffffff00;
        ipif.s_eth_hdr_valid                   = 0;
        ipif.s_eth_dest_mac                    = 0;
        ipif.s_eth_src_mac                     = 0;
        ipif.s_eth_type                        = 0;
        ipif.s_eth_axi_payload_tdata           = 0;
        ipif.s_eth_axi_payload_tvalid          = 0;
        ipif.s_eth_axi_payload_tlast           = 0;   
        ipif.s_eth_axi_payload_tuser           = 0;   
        ipif.m_eth_hdr_ready                   = 0;
        ipif.m_eth_axi_payload_tready          = 0;
        ipif.s_ip_hdr_valid                    = 0;
        ipif.s_ip_dscp                         = 0;
        ipif.s_ip_ecn                          = 0;
        ipif.s_ip_len                          = 0;       
        ipif.s_ip_ttl                          = 0;
        ipif.s_ip_protocol                     = 0;
        ipif.s_ip_src_ip                       = 0;
        ipif.s_ip_dest_ip                      = 0;
        ipif.s_ip_axi_payload_tdata            = 0;
        ipif.s_ip_axi_payload_tvalid           = 0;
        ipif.s_ip_axi_payload_tlast            = 0;
        ipif.s_ip_axi_payload_tuser            = 0;
        ipif.m_ip_hdr_ready                    = 0;
        ipif.m_ip_axi_payload_tready           = 0;
        ipif.rx_busy                           = 0;
        ipif.tx_busy                           = 0;
        ipif.rx_err_invalid_hdr                = 0;
        ipif.rx_err_invalid_checksum           = 0;
        ipif.rx_err_hdr_early_termination      = 0;
        ipif.rx_err_payload_early_termination  = 0;
        ipif.tx_err_payload_early_termination  = 0;
        ipif.tx_err_arp_failed                 = 0;
    
    end

endprogram

program monitor_ip_full(ip_full_if ipif);

    initial begin
    
        forever begin
        
            @(posedge ipif.clk);
            wait(ipif.m_ip_hdr_valid);
            $display("IP Header");
            $display("IP Version : %0h", ipif.m_ip_version);
            $display("IHL : %0h", ipif.m_ip_ihl);
            $display("DSCP : %0h", ipif.m_ip_dscp);
            $display("ECN : %0h", ipif.m_ip_ecn);
            $display("Length : %0h", ipif.m_ip_len);
            $display("Identifiction : %0h", ipif.m_ip_iden);
            $display("Fragment Offset : %0h", ipif.m_ip_frag_off);
            $display("Time-To-Live : %0h", ipif.m_ip_ttl);
            $display("Protocol : %0h", ipif.m_ip_protocol);
            $display("Checksum : %0h", ipif.m_ip_checksum);
            $display("SourceIP : %0h", ipif.m_ip_src_ip);
            $display("DestinationIP : %0h", ipif.m_ip_dest_ip);
        
        end
    
    end
    
    initial begin
    
        forever begin
        
            @(posedge ipif.clk);
            wait(ipif.m_ip_axi_payload_tvalid);
            $display("IP Payload");
            $display("Data : %0h", ipif.m_ip_axi_payload_tdata);
            $display("Last : %0h", ipif.m_ip_axi_payload_tlast);
            $display("User : %0h", ipif.m_ip_axi_payload_tlast);
        
        end
    
    end
    
    initial begin
    
        @(posedge ipif.clk);
        wait(ipif.m_eth_hdr_valid);
        $display("New Ethernet Header");
        $display("Destination MAC: %0h", ipif.m_eth_dest_mac);
        $display("Source MAC: %0h", ipif.m_eth_src_mac);
        $display("ETH Type: %0h", ipif.m_eth_type);
    
    end
    
    initial begin
    
        @(posedge ipif.clk);
        wait(ipif.m_eth_axi_payload_tvalid);
        $display("New Ethernet Payload");
        $display("Payload Data : %0h", ipif.m_eth_axi_payload_tdata);
    
    end

endprogram

program monitor_error_ip_full(ip_full_if ipif);

    initial begin
    
        forever begin
        
            @(posedge ipif.clk);
            if(ipif.rx_err_invalid_hdr               || ipif.rx_err_invalid_checksum ||
               ipif.rx_err_hdr_early_termination     || ipif.rx_err_payload_early_termination ||
               ipif.tx_err_payload_early_termination || ipif.tx_err_arp_failed) begin
                
                $display("Error Occured");
            
            
            end
        
        end
    
    end

endprogram

module ip_full_stack_tb();

    ip_full_if ipif();
    driver_ip_full       drv(ipif);
    monitor_ip_full       mon(ipif);
    intialize_ip_full     init(ipif);
    monitor_error_ip_full mon_err(ipif);
    
    initial ipif.clk = 0;
    always #5 ipif.clk <= ~ipif.clk;


    ip_full_stack ip_inst(
    
        .clk(ipif.clk),
        .reset(ipif.reset),
        
        /*
        *   Network Configuration
        */
        .local_mac(ipif.local_mac),
        .local_ip(ipif.local_ip),
        .gateway_ip(ipif.gateway_ip),
        .subnet_mask(ipif.subnet_mask),
        .clear_cache(ipif.clear_cache),
        
        /*
        *   Ethernet frame input
        */
        
        .s_eth_hdr_valid(ipif.s_eth_hdr_valid),
        .s_eth_dest_mac(ipif.s_eth_dest_mac),
        .s_eth_src_mac(ipif.s_eth_src_mac),
        .s_eth_type(ipif.s_eth_type),    
        .s_eth_axi_payload_tdata(ipif.s_eth_axi_payload_tdata),
        .s_eth_axi_payload_tvalid(ipif.s_eth_axi_payload_tvalid),
        .s_eth_axi_payload_tlast(ipif.s_eth_axi_payload_tlast),   //End of the frame (EOF)
        .s_eth_axi_payload_tuser(ipif.s_eth_axi_payload_tuser),   //Start of the frame (SOF)
        .s_eth_hdr_ready(ipif.s_eth_hdr_ready),
        .s_eth_axi_payload_tready(ipif.s_eth_axi_payload_tready),
        
        /*
        *   Ethernet frame output
        */
        .m_eth_hdr_ready(ipif.m_eth_hdr_ready),
        .m_eth_axi_payload_tready(ipif.m_eth_axi_payload_tready),
        .m_eth_hdr_valid(ipif.m_eth_hdr_valid),
        .m_eth_dest_mac(ipif.m_eth_dest_mac),
        .m_eth_src_mac(ipif.m_eth_src_mac),
        .m_eth_type(ipif.m_eth_type),    
        .m_eth_axi_payload_tdata(ipif.m_eth_axi_payload_tdata),
        .m_eth_axi_payload_tvalid(ipif.m_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(ipif.m_eth_axi_payload_tlast),   //End of the frame (EOF)
        .m_eth_axi_payload_tuser(ipif.m_eth_axi_payload_tuser),   //Start of the frame (SOF)
        
                
        /*
        *   IP frame input 
        */        
        .s_ip_hdr_valid(ipif.s_ip_hdr_valid),
        .s_ip_dscp(ipif.s_ip_dscp),
        .s_ip_ecn(ipif.s_ip_ecn),
        .s_ip_len(ipif.s_ip_len),       
        .s_ip_ttl(ipif.s_ip_ttl),
        .s_ip_protocol(ipif.s_ip_protocol),
        .s_ip_src_ip(ipif.s_ip_src_ip),
        .s_ip_dest_ip(ipif.s_ip_dest_ip),
        .s_ip_axi_payload_tdata(ipif.s_ip_axi_payload_tdata),
        .s_ip_axi_payload_tvalid(ipif.s_ip_axi_payload_tvalid),
        .s_ip_axi_payload_tlast(ipif.s_ip_axi_payload_tlast),
        .s_ip_axi_payload_tuser(ipif.s_ip_axi_payload_tuser),
        .s_ip_hdr_ready(ipif.s_ip_hdr_ready),
        .s_ip_axi_payload_tready(ipif.s_ip_axi_payload_tready),
        
        /*
        *   IP frame output 
        */ 
        .m_ip_hdr_ready(ipif.m_ip_hdr_ready),
        .m_ip_axi_payload_tready(ipif.m_ip_axi_payload_tready),
        .m_ip_eth_dest_mac(ipif.m_ip_eth_dest_mac),
        .m_ip_eth_src_mac(ipif.m_ip_eth_src_mac),
        .m_ip_eth_type(ipif.m_ip_eth_type), 
        .m_ip_hdr_valid(ipif.m_ip_hdr_valid),
        .m_ip_version(ipif.m_ip_version),
        .m_ip_ihl(ipif.m_ip_ihl),
        .m_ip_dscp(ipif.m_ip_dscp),
        .m_ip_ecn(ipif.m_ip_ecn),
        .m_ip_len(ipif.m_ip_len),       
        .m_ip_iden(ipif.m_ip_iden),
        .m_ip_flags(ipif.m_ip_flags),
        .m_ip_frag_off(ipif.m_ip_frag_off),
        .m_ip_ttl(ipif.m_ip_ttl),
        .m_ip_protocol(ipif.m_ip_protocol),
        .m_ip_checksum(ipif.m_ip_checksum),
        .m_ip_src_ip(ipif.m_ip_src_ip),
        .m_ip_dest_ip(ipif.m_ip_dest_ip),
        .m_ip_axi_payload_tdata(ipif.m_ip_axi_payload_tdata),
        .m_ip_axi_payload_tvalid(ipif.m_ip_axi_payload_tvalid),
        .m_ip_axi_payload_tlast(ipif.m_ip_axi_payload_tlast),
        .m_ip_axi_payload_tuser(ipif.m_ip_axi_payload_tuser),
        
        /*
        *   Status Signals
        */
        .rx_busy(ipif.rx_busy),
        .tx_busy(ipif.tx_busy),
        .rx_err_invalid_hdr(ipif.rx_err_invalid_hdr),
        .rx_err_invalid_checksum(ipif.rx_err_invalid_checksum),
        .rx_err_hdr_early_termination(ipif.rx_err_hdr_early_termination),
        .rx_err_payload_early_termination(ipif.rx_err_payload_early_termination),
        .tx_err_payload_early_termination(ipif.tx_err_payload_early_termination),
        .tx_err_arp_failed(ipif.tx_err_arp_failed)
        
    );


endmodule
