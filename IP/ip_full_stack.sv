`timescale 1ns / 1ps


module ip_full_stack#(

    parameter CACHE_ADDRW = 8,
    parameter REQ_RET_CNT = 4,
    parameter REQ_RET_INT = 5,
    parameter REQ_TIMEOUT = 5

)(

    input  logic clk,
    input  logic reset,
    
    /*
    *   Network Configuration
    */
    input  logic [47 : 0]  local_mac,
    input  logic [31 : 0]  local_ip,
    input  logic [31 : 0]  gateway_ip,
    input  logic [31 : 0]  subnet_mask,
    input  logic           clear_cache,
    
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

    logic arp_req_valid;
    logic arp_req_ready;
    logic arp_rsp_valid;
    logic arp_rsp_ready;
    logic arp_rsp_err;
    
    logic [47 : 0] arp_rsp_mac;
    logic [31 : 0] arp_req_ip;
    
    logic ip_rx_eth_hdr_valid;
    logic ip_rx_eth_hdr_ready;
    logic ip_rx_eth_axi_payload_tvalid;
    logic ip_rx_eth_axi_payload_tready;
    logic ip_rx_eth_axi_payload_tlast;
    logic ip_rx_eth_axi_payload_tuser;
    
    logic [47 : 0] ip_rx_eth_dest_mac;
    logic [47 : 0] ip_rx_eth_src_mac;
    logic [15 : 0] ip_rx_eth_type;
    logic [7  : 0] ip_rx_eth_axi_payload_tdata;
    
    logic ip_tx_eth_hdr_valid;
    logic ip_tx_eth_hdr_ready;
    logic ip_tx_eth_axi_payload_tvalid;
    logic ip_tx_eth_axi_payload_tready;
    logic ip_tx_eth_axi_payload_tlast;
    logic ip_tx_eth_axi_payload_tuser;
    
    logic [47 : 0] ip_tx_eth_dest_mac;
    logic [47 : 0] ip_tx_eth_src_mac;
    logic [15 : 0] ip_tx_eth_type;
    logic [7  : 0] ip_tx_eth_axi_payload_tdata;
    
    logic arp_rx_eth_hdr_valid;
    logic arp_rx_eth_hdr_ready;
    logic arp_rx_eth_axi_payload_tvalid;
    logic arp_rx_eth_axi_payload_tready;
    logic arp_rx_eth_axi_payload_tlast;
    logic arp_rx_eth_axi_payload_tuser;
    
    logic [47 : 0] arp_rx_eth_dest_mac;
    logic [47 : 0] arp_rx_eth_src_mac;
    logic [15 : 0] arp_rx_eth_type;
    logic [7  : 0] arp_rx_eth_axi_payload_tdata;
    
    logic arp_tx_eth_hdr_valid;
    logic arp_tx_eth_hdr_ready;
    logic arp_tx_eth_axi_payload_tvalid;
    logic arp_tx_eth_axi_payload_tready;
    logic arp_tx_eth_axi_payload_tlast;
    logic arp_tx_eth_axi_payload_tuser;
    
    logic [47 : 0] arp_tx_eth_dest_mac;
    logic [47 : 0] arp_tx_eth_src_mac;
    logic [15 : 0] arp_tx_eth_type;
    logic [7  : 0] arp_tx_eth_axi_payload_tdata;
    
    //Protocol Select
    logic s_ip_select;
    logic s_arp_select;
    logic s_non_valid;
    
    assign s_ip_select  = s_eth_type == 16'h0800;
    assign s_arp_select = s_eth_type == 16'h0806;
    assign s_non_valid  = !(s_ip_select || s_arp_select);
    
    logic s_ip_select_r, s_arp_select_r, s_non_valid_r;
    
    always@(posedge clk) begin
    
        if(reset) begin
        
            s_ip_select_r  <= 1'b0; 
            s_arp_select_r <= 1'b0;   
            s_non_valid_r  <= 1'b0;   
        
        end else begin
        
            if(!(s_ip_select_r && s_arp_select_r && s_non_valid_r) ||
                (s_eth_axi_payload_tvalid && s_eth_axi_payload_tready && s_eth_axi_payload_tlast)) 
            begin
            
                s_ip_select_r  <= s_ip_select; 
                s_arp_select_r <= s_arp_select;   
                s_non_valid_r  <= s_non_valid;   
        
            end else begin
            
                s_ip_select_r  <= 1'b0; 
                s_arp_select_r <= 1'b0;   
                s_non_valid_r  <= 1'b0;  
            
            end
        
        end
    
    end
    
    assign ip_rx_eth_hdr_valid = s_ip_select && s_eth_hdr_valid;
    assign ip_rx_eth_dest_mac  = s_eth_dest_mac;
    assign ip_rx_eth_src_mac   = s_eth_src_mac;
    assign ip_rx_eth_type      = 16'h0800;
    
    assign ip_rx_eth_axi_payload_tdata  = s_eth_axi_payload_tdata;
    assign ip_rx_eth_axi_payload_tvalid = s_ip_select_r && s_eth_axi_payload_tvalid;
    assign ip_rx_eth_axi_payload_tlast  = s_eth_axi_payload_tlast;
    assign ip_rx_eth_axi_payload_tuser  = s_eth_axi_payload_tuser;
    
    assign arp_rx_eth_hdr_valid = s_arp_select && s_eth_hdr_valid;
    assign arp_rx_eth_dest_mac  = s_eth_dest_mac;
    assign arp_rx_eth_src_mac   = s_eth_src_mac;
    assign arp_rx_eth_type      = 16'h0806;
    
    assign arp_rx_eth_axi_payload_tdata  = s_eth_axi_payload_tdata;
    assign arp_rx_eth_axi_payload_tvalid = s_arp_select_r && s_eth_axi_payload_tvalid;
    assign arp_rx_eth_axi_payload_tlast  = s_eth_axi_payload_tlast;
    assign arp_rx_eth_axi_payload_tuser  = s_eth_axi_payload_tuser;     
    
    assign s_eth_hdr_ready = (s_ip_select  && ip_rx_eth_hdr_ready)  ||
                             (s_arp_select && arp_rx_eth_hdr_ready) ||
                             (s_non_valid); 
                             
    assign s_eth_axi_payload_tready = (s_ip_select_r && ip_rx_eth_axi_payload_tready)   ||
                                      (s_arp_select_r && arp_rx_eth_axi_payload_tready) ||
                                      (s_non_valid_r);
                                      

    eth_arb_mux#(
    
        .NUM_REQS(2),
        .DATAW(8),
        .KEEP_EN(0),
        .ID_EN(0),
        .DEST_EN(0),
        .USER_EN(1),
        .ARP_TYPE("p")  
    
    )arp_ip_mux(
    
        .clk(clk),
        .reset(reset),
        
        .s_eth_hdr_valid({ip_tx_eth_hdr_valid, arp_tx_eth_hdr_valid}),
        .s_eth_dest_mac({ip_tx_eth_dest_mac, arp_tx_eth_dest_mac}),
        .s_eth_src_mac({ip_tx_eth_src_mac, arp_tx_eth_src_mac}),
        .s_eth_type({ip_tx_eth_type, arp_tx_eth_type}),    
        .s_eth_axi_payload_tdata({ip_tx_eth_axi_payload_tdata, arp_tx_eth_axi_payload_tdata}),
        .s_eth_axi_payload_tkeep(0),
        .s_eth_axi_payload_tvalid({ip_tx_eth_axi_payload_tvalid, arp_tx_eth_axi_payload_tvalid}),
        .s_eth_axi_payload_tlast({ip_tx_eth_axi_payload_tlast, arp_tx_eth_axi_payload_tlast}),   
        .s_eth_axi_payload_tuser({ip_tx_eth_axi_payload_tuser, arp_tx_eth_axi_payload_tuser}),   
        .s_eth_axi_payload_tid(0),
        .s_eth_axi_payload_tdest(0),
        .s_eth_hdr_ready({ip_tx_eth_hdr_ready, arp_tx_eth_hdr_ready}),
        .s_eth_axi_payload_tready({ip_tx_eth_axi_payload_tready, arp_tx_eth_axi_payload_tready}),
        
    
        /*
        *   Ethernet frame output
        */
        .m_eth_hdr_ready(m_eth_hdr_ready),
        .m_eth_axi_payload_tready(m_eth_axi_payload_tready),
        .m_eth_hdr_valid(m_eth_hdr_valid),
        .m_eth_dest_mac(m_eth_dest_mac),
        .m_eth_src_mac(m_eth_src_mac),
        .m_eth_type(m_eth_type),    
        .m_eth_axi_payload_tdata(m_eth_axi_payload_tdata),
        .m_eth_axi_payload_tvalid(m_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(m_eth_axi_payload_tlast),
        .m_eth_axi_payload_tkeep(),
        .m_eth_axi_payload_tuser(m_eth_axi_payload_tuser),   
        .m_eth_axi_payload_tid(),
        .m_eth_axi_payload_tdest()
    
    );
    
    
    IP ip_inst(
    
        .clk(clk),
        .reset(reset),
        
        .local_mac(local_mac),
        
        .s_eth_hdr_valid(ip_rx_eth_hdr_valid),
        .s_eth_dest_mac(ip_rx_eth_dest_mac),
        .s_eth_src_mac(ip_rx_eth_src_mac),
        .s_eth_type(ip_rx_eth_type),    
        .s_eth_axi_payload_tdata(ip_rx_eth_axi_payload_tdata),
        .s_eth_axi_payload_tvalid(ip_rx_eth_axi_payload_tvalid),
        .s_eth_axi_payload_tlast(ip_rx_eth_axi_payload_tlast),   
        .s_eth_axi_payload_tuser(ip_rx_eth_axi_payload_tuser),   
        .s_eth_hdr_ready(ip_rx_eth_hdr_ready),
        .s_eth_axi_payload_tready(ip_rx_eth_axi_payload_tready),
    
        .m_eth_hdr_ready(ip_tx_eth_hdr_ready),
        .m_eth_axi_payload_tready(ip_tx_eth_axi_payload_tready),
        .m_eth_hdr_valid(ip_tx_eth_hdr_valid),
        .m_eth_dest_mac(ip_tx_eth_dest_mac),
        .m_eth_src_mac(ip_tx_eth_src_mac),
        .m_eth_type(ip_tx_eth_type),    
        .m_eth_axi_payload_tdata(ip_tx_eth_axi_payload_tdata),
        .m_eth_axi_payload_tvalid(ip_tx_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(ip_tx_eth_axi_payload_tlast),   
        .m_eth_axi_payload_tuser(ip_tx_eth_axi_payload_tuser),   
    
        .arp_req_ready(arp_req_ready),
        .arp_rsp_valid(arp_rsp_valid),
        .arp_rsp_err(arp_rsp_err),
        .arp_rsp_mac(arp_rsp_mac),
        .arp_req_valid(arp_req_valid),
        .arp_req_ip(arp_req_ip),
        .arp_rsp_ready(arp_rsp_ready),
               
        .s_ip_hdr_valid(s_ip_hdr_valid),
        .s_ip_dscp(s_ip_dscp),
        .s_ip_ecn(s_ip_ecn),
        .s_ip_len(s_ip_len),       
        .s_ip_ttl(s_ip_ttl),
        .s_ip_protocol(s_ip_protocol),
        .s_ip_src_ip(s_ip_src_ip),
        .s_ip_dest_ip(s_ip_dest_ip),
        .s_ip_axi_payload_tdata(s_ip_axi_payload_tdata),
        .s_ip_axi_payload_tvalid(s_ip_axi_payload_tvalid),
        .s_ip_axi_payload_tlast(s_ip_axi_payload_tlast),
        .s_ip_axi_payload_tuser(s_ip_axi_payload_tuser),
        .s_ip_hdr_ready(s_ip_hdr_ready),
        .s_ip_axi_payload_tready(s_ip_axi_payload_tready),
        
        .m_ip_hdr_ready(m_ip_hdr_ready),
        .m_ip_axi_payload_tready(m_ip_axi_payload_tready),
        .m_ip_eth_dest_mac(m_ip_eth_dest_mac),
        .m_ip_eth_src_mac(m_ip_eth_src_mac),
        .m_ip_eth_type(m_ip_eth_type), 
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
        
        .rx_busy(rx_busy),
        .tx_busy(tx_busy),
        .rx_err_invalid_hdr(rx_err_invalid_hdr),
        .rx_err_invalid_checksum(rx_err_invalid_checksum),
        .rx_err_hdr_early_termination(rx_err_hdr_early_termination),
        .rx_err_payload_early_termination(rx_err_payload_early_termination),
        .tx_err_payload_early_termination(tx_err_payload_early_termination),
        .tx_err_arp_failed(tx_err_arp_failed)
        
    );
    
    
    ARP#(
    
        //AXI-Stream Data Width
        .CACHE_ADDRW(CACHE_ADDRW),
        .REQ_RET_CNT(REQ_RET_CNT),
        .REQ_RET_INT(REQ_RET_INT),
        .REQ_TIMEOUT(REQ_TIMEOUT)
        
    )arp_inst(
    
        .clk(clk),
        .reset(reset),
        
        /*
        *   The Network configuration
        */
        .local_mac(local_mac),
        .local_ip(local_ip),
        .gateway_ip(gateway_ip),
        .subnet_mask(subnet_mask),
        .clear_cache(clear_cache),
        
        /*
        *   The Ethernet frame input 
        */
        .s_eth_hdr_valid(arp_rx_eth_hdr_valid),
        .s_eth_dest_mac(arp_rx_eth_dest_mac),
        .s_eth_src_mac(arp_rx_eth_src_mac),
        .s_eth_type(arp_rx_eth_type),
        .s_eth_axi_payload_tdata(arp_rx_eth_axi_payload_tdata),
        .s_eth_axi_payload_tkeep(0),
        .s_eth_axi_payload_tvalid(arp_rx_eth_axi_payload_tvalid),
        .s_eth_axi_payload_tlast(arp_rx_eth_axi_payload_tlast),   
        .s_eth_axi_payload_tuser(arp_rx_eth_axi_payload_tuser),   
        .s_eth_hdr_ready(arp_rx_eth_hdr_ready),
        .s_eth_axi_payload_tready(arp_rx_eth_axi_payload_tready),
        
        /*
        *   The Ethernet frame output
        */
        .m_eth_hdr_ready(arp_tx_eth_hdr_ready),
        .m_eth_axi_payload_tready(arp_tx_eth_axi_payload_tready),
        .m_eth_hdr_valid(arp_tx_eth_hdr_valid),
        .m_eth_dest_mac(arp_tx_eth_dest_mac),
        .m_eth_src_mac(arp_tx_eth_src_mac),
        .m_eth_type(arp_tx_eth_type),
        .m_eth_axi_payload_tdata(arp_tx_eth_axi_payload_tdata),
        .m_eth_axi_payload_tkeep(),
        .m_eth_axi_payload_tvalid(arp_tx_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(arp_tx_eth_axi_payload_tlast),   
        .m_eth_axi_payload_tuser(arp_tx_eth_axi_payload_tuser),   
        
        /*
        *   The ARP request 
        */
        .arp_req_valid(arp_req_valid),
        .arp_req_ip(arp_req_ip),
        .arp_rsp_ready(arp_rsp_ready),
        .arp_req_ready(arp_req_ready),
        .arp_rsp_valid(arp_rsp_valid),
        .arp_rsp_err(arp_rsp_err),
        .arp_rsp_mac(arp_rsp_mac)
        
    );


endmodule
