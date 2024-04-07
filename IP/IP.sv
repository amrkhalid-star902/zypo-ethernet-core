`timescale 1ns / 1ps

/*
*   IP Version 4 module equipped with Ethernet interface
*/

module IP(

    input  logic clk,
    input  logic reset,
    
    /*
    *   Network Configuration
    */
    input  logic [47 : 0]  local_mac,
    
    /*
    *   Ethernet frame input
    */
    
    input  logic           s_eth_hdr_valid,
    input  logic [47 : 0]  s_eth_dest_mac,
    input  logic [47 : 0]  s_eth_src_mac,
    input  logic [15 : 0]  s_eth_type,    
    input  logic [7  : 0]  s_eth_axi_payload_tdata,
    input  logic           s_eth_axi_payload_tvalid,
    input  logic           s_eth_axi_payload_tlast,   //End of the frame (EOF)
    input  logic           s_eth_axi_payload_tuser,   //Start of the frame (SOF)
    output logic           s_eth_hdr_ready,
    output logic           s_eth_axi_payload_tready,
    
    /*
    *   Ethernet frame output
    */
    input  logic           m_eth_hdr_ready,
    input  logic           m_eth_axi_payload_tready,
    output logic           m_eth_hdr_valid,
    output logic [47 : 0]  m_eth_dest_mac,
    output logic [47 : 0]  m_eth_src_mac,
    output logic [15 : 0]  m_eth_type,    
    output logic [7  : 0]  m_eth_axi_payload_tdata,
    output logic           m_eth_axi_payload_tvalid,
    output logic           m_eth_axi_payload_tlast,   //End of the frame (EOF)
    output logic           m_eth_axi_payload_tuser,   //Start of the frame (SOF)
    
    /*
    *   ARP request 
    */
    input  logic           arp_req_ready,
    input  logic           arp_rsp_valid,
    input  logic           arp_rsp_err,
    input  logic [47 : 0]  arp_rsp_mac,
    output logic           arp_req_valid,
    output logic [31 : 0]  arp_req_ip,
    output logic           arp_rsp_ready,
    
    /*
    *   IP frame input 
    */        
    input  logic           s_ip_hdr_valid,
    input  logic [5  : 0]  s_ip_dscp,
    input  logic [1  : 0]  s_ip_ecn,
    input  logic [15 : 0]  s_ip_len,       
    input  logic [7  : 0]  s_ip_ttl,
    input  logic [7  : 0]  s_ip_protocol,
    input  logic [31 : 0]  s_ip_src_ip,
    input  logic [31 : 0]  s_ip_dest_ip,
    input  logic [7  : 0]  s_ip_axi_payload_tdata,
    input  logic           s_ip_axi_payload_tvalid,
    input  logic           s_ip_axi_payload_tlast,
    input  logic           s_ip_axi_payload_tuser,
    output logic           s_ip_hdr_ready,
    output logic           s_ip_axi_payload_tready,
    
    /*
    *   IP frame output 
    */ 
    input  logic           m_ip_hdr_ready,
    input  logic           m_ip_axi_payload_tready,
    output logic [47 : 0]  m_ip_eth_dest_mac,
    output logic [47 : 0]  m_ip_eth_src_mac,
    output logic [15 : 0]  m_ip_eth_type, 
    output logic           m_ip_hdr_valid,
    output logic [3  : 0]  m_ip_version,
    output logic [3  : 0]  m_ip_ihl,
    output logic [5  : 0]  m_ip_dscp,
    output logic [1  : 0]  m_ip_ecn,
    output logic [15 : 0]  m_ip_len,       
    output logic [15 : 0]  m_ip_iden,
    output logic [2  : 0]  m_ip_flags,
    output logic [12 : 0]  m_ip_frag_off,
    output logic [7  : 0]  m_ip_ttl,
    output logic [7  : 0]  m_ip_protocol,
    output logic [15 : 0]  m_ip_checksum,
    output logic [31 : 0]  m_ip_src_ip,
    output logic [31 : 0]  m_ip_dest_ip,
    output logic [7  : 0]  m_ip_axi_payload_tdata,
    output logic           m_ip_axi_payload_tvalid,
    output logic           m_ip_axi_payload_tlast,
    output logic           m_ip_axi_payload_tuser,
    
    /*
    *   Status Signals
    */
    output logic           rx_busy,
    output logic           tx_busy,
    output logic           rx_err_invalid_hdr,
    output logic           rx_err_invalid_checksum,
    output logic           rx_err_hdr_early_termination,
    output logic           rx_err_payload_early_termination,
    output logic           tx_err_payload_early_termination,
    output logic           tx_err_arp_failed
    
);


    //State Machine
    localparam [1 : 0] IDLE         = 0;
    localparam [1 : 0] ARP_QUERY    = 1;     
    localparam [1 : 0] WAIT_PACKET  = 2;  
    
    logic [1 : 0] current_state, next_state;  
    
    logic out_ip_hdr_valid_r, out_ip_hdr_valid_n;
    logic out_ip_hdr_ready;
    logic out_ip_axi_payload_tready;
    logic [47 : 0] out_eth_dest_mac_r, out_eth_dest_mac_n; 
    
    ip_eth_rx ip_eth_rx_inst(
    
        .clk(clk),
        .reset(reset),
        
     
        .s_eth_hdr_valid(s_eth_hdr_valid),
        .s_eth_dest_mac(s_eth_dest_mac),
        .s_eth_src_mac(s_eth_src_mac),
        .s_eth_type(s_eth_type),
        
        .s_eth_axi_payload_tdata(s_eth_axi_payload_tdata),
        .s_eth_axi_payload_tvalid(s_eth_axi_payload_tvalid),
        .s_eth_axi_payload_tlast(s_eth_axi_payload_tlast),   
        .s_eth_axi_payload_tuser(s_eth_axi_payload_tuser),   
        .s_eth_hdr_ready(s_eth_hdr_ready),
        .s_eth_axi_payload_tready(s_eth_axi_payload_tready),
        
    
        .m_ip_hdr_ready(m_ip_hdr_ready),
        .m_ip_axi_payload_tready(m_ip_axi_payload_tready),
        .m_eth_dest_mac(m_ip_eth_dest_mac),
        .m_eth_src_mac(m_ip_eth_src_mac),
        .m_eth_type(m_ip_eth_type), 
        
        .m_ip_hdr_valid(m_ip_hdr_valid),
        .m_ip_version(m_ip_version),
        .m_ip_ihl(m_ip_ihl),
        .m_ip_dscp(m_ip_dscp),
        .m_ip_ecn(m_ip_ecn),
        .m_ip_len(m_ip_len),       
        .m_ip_iden(m_ip_iden),
        .m_ip_flags(m_ip_flags),
        .m_ip_frag_off(m_ip_frag_off),
        .m_ip_ttl(m_ip_ttl),
        .m_ip_protocol(m_ip_protocol),
        .m_ip_checksum(m_ip_checksum),
        .m_ip_src_ip(m_ip_src_ip),
        .m_ip_dest_ip(m_ip_dest_ip),
        .m_ip_axi_payload_tdata(m_ip_axi_payload_tdata),
        .m_ip_axi_payload_tvalid(m_ip_axi_payload_tvalid),
        .m_ip_axi_payload_tlast(m_ip_axi_payload_tlast),
        .m_ip_axi_payload_tuser(m_ip_axi_payload_tuser),
        
    
        .busy(rx_busy),
        .err_invalid_hdr(rx_err_invalid_hdr),
        .err_invalid_checksum(rx_err_invalid_checksum),
        .err_hdr_early_termination(rx_err_hdr_early_termination),
        .err_payload_early_termination(rx_err_payload_early_termination)
    
    );
    

    ip_eth_tx ip_eth_tx_inst(
    
        .clk(clk),
        .reset(reset),
        
     
        .m_eth_hdr_valid(m_eth_hdr_valid),
        .m_eth_dest_mac(m_eth_dest_mac),
        .m_eth_src_mac(m_eth_src_mac),
        .m_eth_type(m_eth_type),
        
        .m_eth_axi_payload_tdata(m_eth_axi_payload_tdata),
        .m_eth_axi_payload_tvalid(m_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(m_eth_axi_payload_tlast),   
        .m_eth_axi_payload_tuser(m_eth_axi_payload_tuser),   
        .m_eth_hdr_ready(m_eth_hdr_ready),
        .m_eth_axi_payload_tready(m_eth_axi_payload_tready),
        
    
        .s_ip_hdr_ready(out_ip_hdr_ready),
        .s_ip_axi_payload_tready(out_ip_axi_payload_tready),
        .s_eth_dest_mac(out_eth_dest_mac_r),
        .s_eth_src_mac(local_mac),
        .s_eth_type(16'h0800), 
        
        .s_ip_hdr_valid(out_ip_hdr_valid_r),
        .s_ip_dscp(s_ip_dscp),
        .s_ip_ecn(s_ip_ecn),
        .s_ip_len(s_ip_len),       
        .s_ip_iden(16'h0),
        .s_ip_flags(3'h2),
        .s_ip_frag_off(13'h0),
        .s_ip_ttl(s_ip_ttl),
        .s_ip_protocol(s_ip_protocol),
        .s_ip_src_ip(s_ip_src_ip),
        .s_ip_dest_ip(s_ip_dest_ip),
        .s_ip_axi_payload_tdata(s_ip_axi_payload_tdata),
        .s_ip_axi_payload_tvalid(s_ip_axi_payload_tvalid),
        .s_ip_axi_payload_tlast(s_ip_axi_payload_tlast),
        .s_ip_axi_payload_tuser(s_ip_axi_payload_tuser),
        
    
        .busy(tx_busy),
        .err_payload_early_termination(tx_err_payload_early_termination)
    
    );
    
    logic s_ip_hdr_ready_r, s_ip_hdr_ready_n;
    logic arp_req_valid_r, arp_req_valid_n;
    logic arp_rsp_ready_r, arp_rsp_ready_n;
    logic drop_packet_r, drop_packet_n;
    
    assign s_ip_hdr_ready          = s_ip_hdr_ready_r;
    assign s_ip_axi_payload_tready = out_ip_axi_payload_tready || drop_packet_r;
    
    assign arp_req_valid = arp_req_valid_r;
    assign arp_req_ip    = s_ip_dest_ip;
    assign arp_rsp_ready = arp_rsp_ready_r;
    
    assign tx_err_arp_failed = arp_rsp_err;
    
    
    always_comb begin
    
        next_state = IDLE;
        
        arp_req_valid_n = arp_req_valid_r && !arp_req_ready;
        arp_rsp_ready_n = 1'b0;
        drop_packet_n   = 1'b0;
        
        s_ip_hdr_ready_n = 1'b0;
        
        out_ip_hdr_valid_n = out_ip_hdr_valid_r && !out_ip_hdr_ready;
        out_eth_dest_mac_n = out_eth_dest_mac_r;
        
        case(current_state)
            
            IDLE: begin
            
                if(s_ip_hdr_valid) begin
                
                    //Send ARP request
                    arp_req_valid_n = 1'b1;
                    arp_rsp_ready_n = 1'b1;
                    next_state      = ARP_QUERY;
                
                end else begin
                
                    next_state = IDLE;
                
                end
            
            end//IDLE
            
            ARP_QUERY: begin
                
                if(arp_rsp_valid) begin
                
                    if(arp_rsp_err) begin
                    
                        //Failed to retrive MAC address
                        //Drop the packet
                        s_ip_hdr_ready_n = 1'b1;
                        drop_packet_n    = 1'b1;
                        next_state       = WAIT_PACKET;
                    
                    end else begin
                    
                        //MAC address retrived successfully
                        s_ip_hdr_ready_n   = 1'b1;
                        out_ip_hdr_valid_n = 1'b1;
                        out_eth_dest_mac_n = arp_rsp_mac;
                        next_state         = WAIT_PACKET;
                    
                    end
                
                end else begin
                
                    next_state = ARP_QUERY;
                
                end
            
            end//ARP_QUERY
            
            WAIT_PACKET: begin
            
                drop_packet_n = drop_packet_r;
                
                //wait for the full packet transimmison
                if(s_ip_axi_payload_tlast && s_ip_axi_payload_tready && s_ip_axi_payload_tvalid) begin
                
                    next_state = IDLE;
                
                end else begin
                
                    next_state = WAIT_PACKET;
                
                end
            
            end//WAIT_PACKET
        
        endcase
    
    end

    always@(posedge clk) begin
    
        if(reset) begin
        
            current_state      <= IDLE;
            arp_req_valid_r    <= 1'b0;
            arp_rsp_ready_r    <= 1'b0;
            drop_packet_r      <= 1'b0;
            s_ip_hdr_ready_r   <= 1'b0;
            out_ip_hdr_valid_r <= 1'b0;
        
        end else begin
        
            current_state      <= next_state;
            arp_req_valid_r    <= arp_req_valid_n;
            arp_rsp_ready_r    <= arp_rsp_ready_n;
            drop_packet_r      <= drop_packet_n;
            s_ip_hdr_ready_r   <= s_ip_hdr_ready_n;
            out_ip_hdr_valid_r <= out_ip_hdr_valid_n;
        
        end
        
        out_eth_dest_mac_r <= out_eth_dest_mac_n;
    
    end

endmodule

