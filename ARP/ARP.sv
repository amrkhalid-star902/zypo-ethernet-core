`timescale 1ns / 1ps


module ARP#(

    //AXI-Stream Data Width
    parameter DATAW = 8,
    //TKEEP is the byte qualifier that indicates
    //whether content of the associated byte of
    //TDATA is processed as part of the data stream.
    parameter KEEP_EN = (DATAW > 8),
    //TKEEP Signal Width
    parameter TDATAW  = DATAW/8,
    //Log2 Cache Address Width
    parameter CACHE_ADDRW = 8,
    //ARP Request Retry Count
    parameter REQ_RET_CNT = 4,
    //ARP Request Retry Interval (in cycles)
    parameter REQ_RET_INT = 125000000*2,
    //ARP Request TimeOut (in cycles)
    parameter REQ_TIMEOUT = 125000000*30
    

)(

    input  logic clk,
    input  logic reset,
    
    /*
    *   The Network configuration
    */
    input  logic [47 : 0]       local_mac,
    input  logic [31 : 0]       local_ip,
    input  logic [31 : 0]       gateway_ip,
    input  logic [31 : 0]       subnet_mask,
    input  logic                clear_cache,
    
    /*
    *   The Ethernet frame input 
    */
    input  logic                s_eth_hdr_valid,
    input  logic [47 : 0]       s_eth_dest_mac,
    input  logic [47 : 0]       s_eth_src_mac,
    input  logic [15 : 0]       s_eth_type,
    input  logic [DATAW-1 : 0]  s_eth_axi_payload_tdata,
    input  logic [TDATAW-1 : 0] s_eth_axi_payload_tkeep,
    input  logic                s_eth_axi_payload_tvalid,
    input  logic                s_eth_axi_payload_tlast,   
    input  logic                s_eth_axi_payload_tuser,   
    output logic                s_eth_hdr_ready,
    output logic                s_eth_axi_payload_tready,
    
    /*
    *   The Ethernet frame output
    */
    input  logic                m_eth_hdr_ready,
    input  logic                m_eth_axi_payload_tready,
    output logic                m_eth_hdr_valid,
    output logic [47 : 0]       m_eth_dest_mac,
    output logic [47 : 0]       m_eth_src_mac,
    output logic [15 : 0]       m_eth_type,
    output logic [DATAW-1 : 0]  m_eth_axi_payload_tdata,
    output logic [TDATAW-1 : 0] m_eth_axi_payload_tkeep,
    output logic                m_eth_axi_payload_tvalid,
    output logic                m_eth_axi_payload_tlast,   
    output logic                m_eth_axi_payload_tuser,   
    
    /*
    *   The ARP request 
    */
    input  logic                arp_req_valid,
    input  logic [31 : 0]       arp_req_ip,
    input  logic                arp_rsp_ready,
    output logic                arp_req_ready,
    output logic                arp_rsp_valid,
    output logic                arp_rsp_err,
    output logic [47 : 0]       arp_rsp_mac
    
);

/*

    1) ARP Request Retry Count:
    
    This parameter defines the number of attempts a device will make to resolve the MAC address associated with a specific IP address using ARP.
    It represents the maximum number of ARP request transmissions the device will perform before considering the ARP resolution process failed.
    If the device doesn't receive a response after reaching the specified retry count, it may report an ARP resolution failure or take other appropriate actions based on its configuration.
    
    2) ARP Request Retry Interval (in cycles):
    
    This parameter determines the duration or interval between successive ARP request transmissions.
    It represents the time gap between each attempt made by the device to resolve the MAC address through ARP.
    The retry interval is typically measured in cycles, where a cycle could represent a clock cycle or some other unit of time depending on the hardware or system configuration.
    A shorter retry interval means the device will make ARP request attempts more frequently, while a longer interval means attempts are spaced further apart.
    
    3) ARP Request Timeout (in cycles):
    
    This parameter defines the maximum time duration within which a device expects to receive a response to an ARP request.
    It represents the timeout period after which the device considers the ARP resolution process unsuccessful if no response is received.
    The timeout duration is typically measured in cycles, similar to the retry interval.
    If the device doesn't receive a response within the specified timeout period, it may retransmit the ARP request based on the retry count or report a timeout error.

*/

    localparam [15 : 0] ARP_OPER_REQ   = 16'h1;     //ARP Request
    localparam [15 : 0] ARP_OPER_REP   = 16'h2;     //ARP Replay
    localparam [15 : 0] INARP_OPER_REQ = 16'h8;     //Inverse ARP Request
    localparam [15 : 0] INARP_OPER_REP = 16'h9;     //Inverse ARP Replay
    
    logic In_frame_valid;
    logic In_frame_ready;
    
    logic [47 : 0] In_eth_dest_mac;
    logic [47 : 0] In_eth_src_mac;
    logic [15 : 0] In_eth_type;
    logic [15 : 0] In_arp_htype;
    logic [15 : 0] In_arp_ptype;
    logic [7  : 0] In_arp_hlen;
    logic [7  : 0] In_arp_plen;
    logic [15 : 0] In_arp_oper;
    logic [47 : 0] In_arp_sha;
    logic [31 : 0] In_arp_spa;
    logic [47 : 0] In_arp_tha;
    logic [31 : 0] In_arp_tpa;
    
    
    arp_eth_rx#(
    
        .DATAW(DATAW),
        .KEEP_EN(KEEP_EN),
        .TDATAW(TDATAW)
    
    )arp_rx(
    
        .clk(clk),
        .reset(reset),
        .s_eth_hdr_valid(s_eth_hdr_valid),
        .s_eth_dest_mac(s_eth_dest_mac),
        .s_eth_src_mac(s_eth_src_mac),
        .s_eth_type(s_eth_type),
    
        .s_eth_axi_payload_tdata(s_eth_axi_payload_tdata),
        .s_eth_axi_payload_tkeep(s_eth_axi_payload_tkeep),
        .s_eth_axi_payload_tvalid(s_eth_axi_payload_tvalid),
        .s_eth_axi_payload_tlast(s_eth_axi_payload_tlast),   
        .s_eth_axi_payload_tuser(s_eth_axi_payload_tuser),   
        .s_eth_hdr_ready(s_eth_hdr_ready),
        .s_eth_axi_payload_tready(s_eth_axi_payload_tready),
        
    
        .m_frame_ready(In_frame_ready),
        .m_frame_valid(In_frame_valid),
        .m_eth_dest_mac(In_eth_dest_mac),
        .m_eth_src_mac(In_eth_src_mac),
        .m_eth_type(In_eth_type),   
      
        .m_arp_htype(In_arp_htype),
        .m_arp_ptype(In_arp_ptype),
        .m_arp_hlen(In_arp_hlen),
        .m_arp_plen(In_arp_plen),
        .m_arp_oper(In_arp_oper),
        .m_arp_sha(In_arp_sha),
        .m_arp_spa(In_arp_spa),
        .m_arp_tha(In_arp_tha),
        .m_arp_tpa(In_arp_tpa),
        
        .busy(),
        .err_invalid_hdr(),
        .err_hdr_early_termination()
    
    );
    
    logic Out_frame_valid_r, Out_frame_valid_n;
    logic Out_frame_ready;
    
    logic [47 : 0] Out_eth_dest_mac_r, Out_eth_dest_mac_n;
    logic [15 : 0] Out_arp_oper_r, Out_arp_oper_n;
    logic [47 : 0] Out_arp_tha_r, Out_arp_tha_n;
    logic [31 : 0] Out_arp_tpa_r, Out_arp_tpa_n;
    
    
    arp_eth_tx#(
    
        .DATAW(DATAW),
        .KEEP_EN(KEEP_EN),
        .TDATAW(TDATAW)
    
    )arp_tx(
    
        .clk(clk),
        .reset(reset),
        .m_eth_hdr_valid(m_eth_hdr_valid),
        .m_eth_dest_mac(m_eth_dest_mac),
        .m_eth_src_mac(m_eth_src_mac),
        .m_eth_type(m_eth_type),
    
        .m_eth_axi_payload_tdata(m_eth_axi_payload_tdata),
        .m_eth_axi_payload_tkeep(m_eth_axi_payload_tkeep),
        .m_eth_axi_payload_tvalid(m_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(m_eth_axi_payload_tlast),   
        .m_eth_axi_payload_tuser(m_eth_axi_payload_tuser),   
        .m_eth_hdr_ready(m_eth_hdr_ready),
        .m_eth_axi_payload_tready(m_eth_axi_payload_tready),
        
    
        .s_frame_ready(Out_frame_ready),
        .s_frame_valid(Out_frame_valid_r),
        .s_eth_dest_mac(Out_eth_dest_mac_r),
        .s_eth_src_mac(local_mac),
        .s_eth_type(16'h0806),   
      
        .s_arp_htype(16'h1),
        .s_arp_ptype(16'h0800),
        .s_arp_oper(Out_arp_oper_r),
        .s_arp_sha(local_mac),
        .s_arp_spa(local_ip),
        .s_arp_tha(Out_arp_tha_r),
        .s_arp_tpa(Out_arp_tpa_r),
        
        .busy()
    
    );
    
    
    logic cache_query_req_valid_r, cache_query_req_valid_n;
    logic cache_query_rsp_valid;
    logic cache_query_rsp_err;
    
    logic [31 : 0] cache_query_req_ip_r, cache_query_req_ip_n;
    logic [47 : 0] cache_query_rsp_mac;
    
    
    logic cache_write_req_valid_r, cache_write_req_valid_n;
    
    logic [31 : 0] cache_write_req_ip_r, cache_write_req_ip_n;
    logic [47 : 0] cache_write_rsp_mac_r, cache_write_rsp_mac_n;
    
    arb_cache#(
    
        .CACHE_ADDRW(CACHE_ADDRW)
    
    )cache(
    
        .clk(clk),
        .reset(reset),
        .clear_cache(clear_cache),
        
        //Query Request Signals
        .query_req_valid(cache_query_req_valid_r),
        .query_req_ip(cache_query_req_ip_r),
        .query_req_ready(),
        
        //Query Response Signals
        .query_rsp_ready(1'b1),
        .query_rsp_valid(cache_query_rsp_valid),
        .query_rsp_err(cache_query_rsp_err),
        .query_rsp_mac(cache_query_rsp_mac),
        
        //Write Request Signals
        .write_req_valid(cache_write_req_valid_r),
        .write_req_ip(cache_write_req_ip_r),
        .write_req_mac(cache_write_rsp_mac_r),
        .write_req_ready()
        
    );
    
    logic send_arp_request_r, send_arp_request_n;
    logic arp_req_ready_r, arp_req_ready_n;
    logic arp_rsp_valid_r, arp_rsp_valid_n;
    logic arp_rsp_err_r, arp_rsp_err_n;
    
    logic [31 : 0] arp_req_ip_r, arp_req_ip_n;
    logic [47 : 0] arp_rsp_mac_r, arp_rsp_mac_n;
    logic [5  : 0] arp_req_retry_cnt_r, arp_req_retry_cnt_n;
    logic [35 : 0] arp_req_timer_r, arp_req_timer_n;
    
    assign arp_req_ready = arp_req_ready_r;
    assign arp_rsp_valid = arp_rsp_valid_r;
    assign arp_rsp_err   = arp_rsp_err_r;
    assign arp_rsp_mac   = arp_rsp_mac_r;
    
    always_comb begin
    
        In_frame_ready = 1'b0;
        
        Out_frame_valid_n  = Out_frame_valid_r;
        Out_eth_dest_mac_n = Out_eth_dest_mac_r;
        Out_arp_oper_n     = Out_arp_oper_r;
        Out_arp_tha_n      = Out_arp_tha_r;
        Out_arp_tpa_n      = Out_arp_tpa_r;
        
        cache_query_req_valid_n = 1'b0;
        cache_query_req_ip_n    = cache_query_req_ip_r;
        cache_write_req_valid_n = 1'b0;
        cache_write_rsp_mac_n   = cache_write_rsp_mac_r;
        cache_write_req_ip_n    = cache_write_req_ip_r;
        
        arp_req_ready_n     = 1'b0;
        arp_req_ip_n        = arp_req_ip_r;
        send_arp_request_n  = send_arp_request_r;
        arp_req_retry_cnt_n = arp_req_retry_cnt_r;
        arp_req_timer_n     = arp_req_timer_r;
        arp_rsp_valid_n     = arp_rsp_valid_r && !arp_rsp_ready;
        arp_rsp_err_n       = 1'b0;
        arp_rsp_mac_n       = 48'h0;
        
        In_frame_ready = Out_frame_ready;
        
        //Manage the received requests
        if(In_frame_valid && In_frame_ready) begin
        
            if(In_eth_type == 16'h0806 && In_arp_htype == 16'h1 && In_arp_ptype == 16'h0800) begin
            
                //The address of the sender is stored in the cache
                cache_write_req_valid_n = 1'b1;
                cache_write_rsp_mac_n   = In_arp_sha;
                cache_write_req_ip_n    = In_arp_spa;
                
                //The Request sent is ARP
                if(In_arp_oper == ARP_OPER_REQ) begin
                
                    if(In_arp_tpa == local_ip) begin
                    
                        Out_frame_valid_n  = 1'b1;
                        Out_eth_dest_mac_n = In_eth_src_mac;
                        Out_arp_oper_n     = ARP_OPER_REP;
                        Out_arp_tha_n      = In_arp_sha;
                        Out_arp_tpa_n      = In_arp_spa;
                    
                    end
                
                end else if(In_arp_oper == INARP_OPER_REQ) begin
                    //The Request sent is Inverse ARP
                    if(In_arp_tpa == local_mac) begin
                    
                        Out_frame_valid_n  = 1'b1;
                        Out_eth_dest_mac_n = In_eth_src_mac;
                        Out_arp_oper_n     = INARP_OPER_REP;
                        Out_arp_tha_n      = In_arp_sha;
                        Out_arp_tpa_n      = In_arp_spa;
                    
                    end
                
                end
                            
            end
        
        end
        
        //If an error occurs an ARP request will be sent instead of ARP reply
        if(send_arp_request_r) begin
        
            arp_req_ready_n         = 1'b0;
            cache_query_req_valid_n = 1'b1;
            //decrement the timer counter
            arp_req_timer_n         = arp_req_timer_r - 1;
            
            //If another response is received from the device which did not cause an error,
            //then the arp query succedds and a valid response will be sent without an error.
            if(cache_query_rsp_valid && !cache_query_rsp_err) begin
            
                send_arp_request_n      = 1'b0;
                cache_query_req_valid_n = 1'b0;
                arp_rsp_valid_n         = 1'b1;
                arp_rsp_err_n           = 1'b0;
                arp_rsp_mac_n           = cache_query_rsp_mac;
            
            end
            
            //TimeOut occurs
            if(arp_req_timer_r == 0) begin
            
                //TimeOut occurs but the device still has a number of retries yet
                if(arp_req_retry_cnt_r > 0) begin
                
                    //Send another ARP request frame
                    Out_frame_valid_n  = 1'b1;
                    Out_eth_dest_mac_n = 48'hffffffffffff;
                    Out_arp_oper_n     = ARP_OPER_REQ;
                    Out_arp_tha_n      = 48'h0;
                    Out_arp_tpa_n      = arp_req_ip_r;
                    
                    arp_req_retry_cnt_n = arp_req_retry_cnt_r - 1;
                    
                    if(arp_req_retry_cnt_r > 1) 
                        arp_req_timer_n = REQ_RET_INT;
                    else
                        arp_req_timer_n = REQ_TIMEOUT;
                
                end else begin
                
                    //The are no more retries
                    send_arp_request_n = 1'b0;
                    arp_rsp_valid_n    = 1'b1;
                    arp_rsp_err_n      = 1'b1;
                    
                    cache_query_req_valid_n = 1'b0;
                
                end
                
            end //TimeOut
        
        end else begin
        
            arp_req_ready_n = !arp_rsp_valid_n;
            if(cache_query_req_valid_r) begin
            
                cache_query_req_valid_n = 1'b1;
                if(cache_query_rsp_valid) begin
                
                    if(cache_query_rsp_err) begin
                    
                        send_arp_request_n = 1'b1;
                        
                        //Send ARP request frame
                        Out_frame_valid_n  = 1'b1;
                        Out_eth_dest_mac_n = 48'hffffffffffff;
                        Out_arp_oper_n     = ARP_OPER_REQ;
                        Out_arp_tha_n      = 48'h0;
                        Out_arp_tpa_n      = arp_req_ip_r;
                        
                        //Set the timeout and retry counter
                        arp_req_retry_cnt_n = REQ_RET_CNT-1;
                        arp_req_timer_n     = REQ_RET_INT;
                    
                    end else begin
                    
                        cache_query_req_valid_n = 1'b0;
                        arp_rsp_valid_n         = 1'b1;
                        arp_rsp_err_n           = 1'b0;
                        arp_rsp_mac_n           = cache_query_rsp_mac;
                    
                    end
                
                end
            
            end else if(arp_req_valid && arp_req_ready)begin
            
                //A broadcast address to all subnets is received
                if(arp_req_ip == 32'hffffffff) begin
                
                    arp_rsp_valid_n = 1'b1;
                    arp_rsp_err_n   = 1'b0;
                    arp_rsp_mac_n   = 48'hffffffffffff;
                
                end else if(((arp_req_ip ^ gateway_ip) & subnet_mask) == 0) begin
                
                    //The address within the subnet
                    //A broadcast address to all the subnet
                    if(~(arp_req_ip | subnet_mask) == 0) begin
                    
                        arp_rsp_valid_n = 1'b1;
                        arp_rsp_err_n   = 1'b0;
                        arp_rsp_mac_n   = 48'hffffffffffff;
                        
                    end else begin
                    
                        //Uni-cast address to a specific node in the subnet
                        cache_query_req_valid_n = 1'b1;
                        cache_query_req_ip_n    = arp_req_ip;
                        arp_req_ip_n            = arp_req_ip;
                    
                    end
                
                end else begin
                
                    //outside the subnet
                    cache_query_req_valid_n = 1'b1;
                    cache_query_req_ip_n    = gateway_ip;
                    arp_req_ip_n            = gateway_ip;
                
                end
            
            end
        
        end
        
    end
    
    always@(posedge clk) begin
    
        if(reset) begin
        
            Out_frame_valid_r       <= 1'b0;   
            cache_query_req_valid_r <= 1'b0;
            cache_write_req_valid_r <= 1'b0;
            
            arp_req_ready_r     <= 1'b0;
            send_arp_request_r  <= 1'b0;
            arp_req_retry_cnt_r <= 0;
            arp_req_timer_r     <= 0;
            arp_rsp_valid_r     <= 1'b0;
        
        end else begin
        
            Out_frame_valid_r       <= Out_frame_valid_n;   
            cache_query_req_valid_r <= cache_query_req_valid_n;
            cache_write_req_valid_r <= cache_write_req_valid_n;
            
            arp_req_ready_r     <= arp_req_ready_n;
            send_arp_request_r  <= send_arp_request_n;
            arp_req_retry_cnt_r <= arp_req_retry_cnt_n;
            arp_req_timer_r     <= arp_req_timer_n;
            arp_rsp_valid_r     <= arp_rsp_valid_n;
        
        end
        
        cache_query_req_ip_r   <= cache_query_req_ip_n;
        Out_eth_dest_mac_r     <= Out_eth_dest_mac_n;
        Out_arp_oper_r         <= Out_arp_oper_n;
        Out_arp_tha_r          <= Out_arp_tha_n;
        Out_arp_tpa_r          <= Out_arp_tpa_n;
        cache_write_rsp_mac_r  <= cache_write_rsp_mac_n;
        cache_write_req_ip_r   <= cache_write_req_ip_n;
        arp_req_ip_r           <= arp_req_ip_n;
        arp_rsp_err_r          <= arp_rsp_err_n;
        arp_rsp_mac_r          <= arp_rsp_mac_n;
    
    end

endmodule
