`timescale 1ns / 1ps

/*
*   This module is used to receive the different Ethernet header fields in parrallel and the payload associated
*   with the headers through an AXI interface, then generate the different ARP packet fields and sends them in
*   the payload of Ethernet frame.
*/

module arp_eth_rx#(

    //AXI-Stream Data Width
    parameter DATAW = 8,
    //TKEEP is the byte qualifier that indicates
    //whether content of the associated byte of
    //TDATA is processed as part of the data stream.
    parameter KEEP_EN = (DATAW > 8),
    //TKEEP Signal Width
    parameter TDATAW  = DATAW/8

)(

    input  logic clk,
    input  logic reset,
    
    /*
    *   The Ethernet frame input to the slave side of the receiver
    */
    //Header signals sent by the master
    input  logic                s_eth_hdr_valid,
    input  logic [47 : 0]       s_eth_dest_mac,
    input  logic [47 : 0]       s_eth_src_mac,
    input  logic [15 : 0]       s_eth_type,
    //Payload signals sent by the master after sending the header
    input  logic [DATAW-1 : 0]  s_eth_axi_payload_tdata,
    input  logic [TDATAW-1 : 0] s_eth_axi_payload_tkeep,
    input  logic                s_eth_axi_payload_tvalid,
    input  logic                s_eth_axi_payload_tlast,   //End of the frame (EOF)
    input  logic                s_eth_axi_payload_tuser,   //Start of the frame (SOF)
    output logic                s_eth_hdr_ready,
    output logic                s_eth_axi_payload_tready,
    
    /*
    *   The Ethernet frame output from the master side of the receiver
    */
    //ARP frame output
    input  logic                m_frame_ready,
    output logic                m_frame_valid,
    output logic [47 : 0]       m_eth_dest_mac,
    output logic [47 : 0]       m_eth_src_mac,
    output logic [15 : 0]       m_eth_type,   
    //The signal carried in the Ethernet payload section       
    output logic [15 : 0]       m_arp_htype,
    output logic [15 : 0]       m_arp_ptype,
    output logic [7  : 0]       m_arp_hlen,
    output logic [7  : 0]       m_arp_plen,
    output logic [15 : 0]       m_arp_oper,
    output logic [47 : 0]       m_arp_sha,
    output logic [31 : 0]       m_arp_spa,
    output logic [47 : 0]       m_arp_tha,
    output logic [31 : 0]       m_arp_tpa,
    
    /*
    *   Status Signals
    */
    output logic                busy,
    output logic                err_invalid_hdr,
    output logic                err_hdr_early_termination

);


    localparam BYTE_NUM = KEEP_EN ? TDATAW : 1;
    initial assert(BYTE_NUM*8 == DATAW);
    
    //ARP header size
    localparam HDR_SIZE = 28;
    
    //Number of cycles needed to transmit the whole ARP frame header
    localparam CYCLE_COUNT = (HDR_SIZE+BYTE_NUM-1)/BYTE_NUM;
    
    //Pointer width used to keep track of the sent ARP header bytes 
    localparam PTRW = $clog2(CYCLE_COUNT);
    
    /*
    *    Different fields present in the ARP packet
    */
    
    /*
    
              Field                     Length in bytes
        Hardware type (HTYPE)                 2
        Protocol type (PTYPE)                 2
        Hardware address length (HLEN)        1
        Protocol address length (PLEN)        1
        Operation (OPER)                      2
        Sender hardware address (SHA)         6
        Sender protocol address (SPA)         4
        Target hardware address (THA)         6
        Target protocol address (TPA)         4
    
    */
    
    //Intermediate signals
    logic str_eth_hdr;
    
    logic rd_eth_hdr_r, rd_eth_hdr_n;
    logic rd_arp_hdr_r, rd_arp_hdr_n;
    logic [PTRW-1 : 0] ptr_r, ptr_n;
    
    logic s_eth_hdr_ready_r, s_eth_hdr_ready_n;
    logic s_eth_axi_payload_tready_r, s_eth_axi_payload_tready_n;
    
    logic m_frame_valid_r, m_frame_valid_n;
    
    logic [47 : 0]  m_eth_dest_mac_r;
    logic [47 : 0]  m_eth_src_mac_r;
    logic [15 : 0]  m_eth_type_r;
    logic [15 : 0]  m_arp_htype_r, m_arp_htype_n;
    logic [15 : 0]  m_arp_ptype_r, m_arp_ptype_n;
    logic [7  : 0]  m_arp_hlen_r, m_arp_hlen_n;
    logic [7  : 0]  m_arp_plen_r, m_arp_plen_n;
    logic [15  : 0] m_arp_oper_r, m_arp_oper_n;
    logic [47  : 0] m_arp_sha_r, m_arp_sha_n;
    logic [31  : 0] m_arp_spa_r, m_arp_spa_n;
    logic [47  : 0] m_arp_tha_r, m_arp_tha_n;
    logic [31  : 0] m_arp_tpa_r, m_arp_tpa_n;
    
    logic busy_r;
    logic err_invalid_hdr_r, err_invalid_hdr_n;
    logic err_hdr_early_termination_r, err_hdr_early_termination_n;
    
    assign s_eth_hdr_ready          = s_eth_hdr_ready_r;
    assign s_eth_axi_payload_tready = s_eth_axi_payload_tready_r;
    
    assign m_frame_valid  = m_frame_valid_r;
    assign m_eth_dest_mac = m_eth_dest_mac_r;
    assign m_eth_src_mac  = m_eth_src_mac_r;
    assign m_eth_type     = m_eth_type_r;
    assign m_arp_htype    = m_arp_htype_r;
    assign m_arp_ptype    = m_arp_ptype_r;
    assign m_arp_hlen     = m_arp_hlen_r;
    assign m_arp_plen     = m_arp_plen_r;
    assign m_arp_oper     = m_arp_oper_r;
    assign m_arp_sha      = m_arp_sha_r;
    assign m_arp_spa      = m_arp_spa_r;
    assign m_arp_tha      = m_arp_tha_r;
    assign m_arp_tpa      = m_arp_tpa_r;
        
    assign busy                      = busy_r;
    assign err_invalid_hdr           = err_invalid_hdr_r;
    assign err_hdr_early_termination = err_hdr_early_termination_r;
    
    always_comb begin
    
        rd_eth_hdr_n = rd_eth_hdr_r;
        rd_arp_hdr_n = rd_arp_hdr_r;
        ptr_n        = ptr_r;
        
        s_eth_hdr_ready_n          = 1'b0;
        s_eth_axi_payload_tready_n = 1'b0;
        
        str_eth_hdr = 1'b0;
        
        m_frame_valid_n = m_frame_valid_r && !m_frame_ready;
        
        m_arp_htype_n = m_arp_htype_r;
        m_arp_ptype_n = m_arp_ptype_r;
        m_arp_hlen_n  = m_arp_hlen_r;
        m_arp_plen_n  = m_arp_plen_r;
        m_arp_oper_n  = m_arp_oper_r;
        m_arp_sha_n   = m_arp_sha_r;
        m_arp_spa_n   = m_arp_spa_r;
        m_arp_tha_n   = m_arp_tha_r;
        m_arp_tpa_n   = m_arp_tpa_r;
        
        err_hdr_early_termination_n = 1'b0;
        err_invalid_hdr_n           = 1'b0;
        
        if(s_eth_hdr_ready && s_eth_hdr_valid) begin
        
            if(rd_eth_hdr_r) begin
                //Read the receive header
                //Disable the read header and be ready,
                //to receive the payloads associated with the header
                str_eth_hdr  = 1'b1;
                ptr_n        = 0;
                rd_eth_hdr_n = 1'b0;
                rd_arp_hdr_n = 1'b1;
            
            end
        
        end
        
        if(s_eth_axi_payload_tvalid && s_eth_axi_payload_tready) begin
        
            if(rd_arp_hdr_r) begin
                //Receive the differrent ARP packet fields sent in the Ethernet payload
                ptr_n = ptr_r + 1;
                
                if(DATAW == 8) begin
                
                    case(ptr_r)
                    
                        0:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_htype_n[15:8]  = s_eth_axi_payload_tdata;
                        1:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_htype_n[7:0]   = s_eth_axi_payload_tdata;
                        2:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_ptype_n[15:8]  = s_eth_axi_payload_tdata;
                        3:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_ptype_n[7:0]   = s_eth_axi_payload_tdata;
                        4:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_hlen_n[7:0]    = s_eth_axi_payload_tdata;
                        5:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_plen_n[7:0]    = s_eth_axi_payload_tdata;
                        6:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_oper_n[15:8]   = s_eth_axi_payload_tdata;
                        7:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_oper_n[7:0]    = s_eth_axi_payload_tdata;
                        8:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_sha_n[47:40]   = s_eth_axi_payload_tdata;
                        9:  if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_sha_n[39:32]   = s_eth_axi_payload_tdata;
                        10: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_sha_n[31:24]   = s_eth_axi_payload_tdata;
                        11: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_sha_n[23:16]   = s_eth_axi_payload_tdata;
                        12: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_sha_n[15:8]    = s_eth_axi_payload_tdata;
                        13: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_sha_n[7:0]     = s_eth_axi_payload_tdata;
                        14: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_spa_n[31:24]   = s_eth_axi_payload_tdata;
                        15: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_spa_n[23:16]   = s_eth_axi_payload_tdata;
                        16: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_spa_n[15:8]    = s_eth_axi_payload_tdata;
                        17: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_spa_n[7:0]     = s_eth_axi_payload_tdata;
                        18: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tha_n[47:40]   = s_eth_axi_payload_tdata;
                        19: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tha_n[39:32]   = s_eth_axi_payload_tdata;
                        20: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tha_n[31:24]   = s_eth_axi_payload_tdata;
                        21: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tha_n[23:16]   = s_eth_axi_payload_tdata;
                        22: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tha_n[15:8]    = s_eth_axi_payload_tdata;
                        23: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tha_n[7:0]     = s_eth_axi_payload_tdata;
                        24: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tpa_n[31:24]   = s_eth_axi_payload_tdata;
                        25: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tpa_n[23:16]   = s_eth_axi_payload_tdata;
                        26: if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tpa_n[15:8]    = s_eth_axi_payload_tdata;
                        27: if(s_eth_axi_payload_tkeep[0] == 1'b1)  
                            begin 
                                m_arp_tpa_n[7:0] = s_eth_axi_payload_tdata; 
                                rd_arp_hdr_n     = 1'b0; 
                            end
                        
                    endcase
                    
                        
                end//DATAW == 8
                else if(DATAW == 64) begin
                
                    case(ptr_r)
                    
                        0: begin
                        
                            if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_htype_n[15:8]  = s_eth_axi_payload_tdata[7:0];
                            if(s_eth_axi_payload_tkeep[1] == 1'b1)  m_arp_htype_n[7:0]   = s_eth_axi_payload_tdata[15:8];
                            if(s_eth_axi_payload_tkeep[2] == 1'b1)  m_arp_ptype_n[15:8]  = s_eth_axi_payload_tdata[23:16];
                            if(s_eth_axi_payload_tkeep[3] == 1'b1)  m_arp_ptype_n[7:0]   = s_eth_axi_payload_tdata[31:24];
                            if(s_eth_axi_payload_tkeep[4] == 1'b1)  m_arp_hlen_n[7:0]    = s_eth_axi_payload_tdata[39:32];
                            if(s_eth_axi_payload_tkeep[5] == 1'b1)  m_arp_plen_n[7:0]    = s_eth_axi_payload_tdata[47:40];
                            if(s_eth_axi_payload_tkeep[6] == 1'b1)  m_arp_oper_n[15:8]   = s_eth_axi_payload_tdata[55:48];
                            if(s_eth_axi_payload_tkeep[7] == 1'b1)  m_arp_oper_n[7:0]    = s_eth_axi_payload_tdata[63:56]; 
                                                      
                        end
                        
                        1: begin
                        
                            if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_sha_n[47:40]   = s_eth_axi_payload_tdata[7:0];
                            if(s_eth_axi_payload_tkeep[1] == 1'b1)  m_arp_sha_n[39:32]   = s_eth_axi_payload_tdata[15:8];
                            if(s_eth_axi_payload_tkeep[2] == 1'b1)  m_arp_sha_n[31:24]   = s_eth_axi_payload_tdata[23:16];
                            if(s_eth_axi_payload_tkeep[3] == 1'b1)  m_arp_sha_n[23:16]   = s_eth_axi_payload_tdata[31:24];
                            if(s_eth_axi_payload_tkeep[4] == 1'b1)  m_arp_sha_n[15:8]    = s_eth_axi_payload_tdata[39:32];
                            if(s_eth_axi_payload_tkeep[5] == 1'b1)  m_arp_sha_n[7:0]     = s_eth_axi_payload_tdata[47:40];
                            if(s_eth_axi_payload_tkeep[6] == 1'b1)  m_arp_spa_n[31:24]   = s_eth_axi_payload_tdata[55:48];
                            if(s_eth_axi_payload_tkeep[7] == 1'b1)  m_arp_spa_n[23:16]   = s_eth_axi_payload_tdata[63:56];
                                                
                        end
                        
                        2: begin
                        
                            if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_spa_n[15:8]    = s_eth_axi_payload_tdata[7:0];
                            if(s_eth_axi_payload_tkeep[1] == 1'b1)  m_arp_spa_n[7:0]     = s_eth_axi_payload_tdata[15:8];
                            if(s_eth_axi_payload_tkeep[2] == 1'b1)  m_arp_tha_n[47:40]   = s_eth_axi_payload_tdata[23:16];
                            if(s_eth_axi_payload_tkeep[3] == 1'b1)  m_arp_tha_n[39:32]   = s_eth_axi_payload_tdata[31:24];
                            if(s_eth_axi_payload_tkeep[4] == 1'b1)  m_arp_tha_n[31:24]   = s_eth_axi_payload_tdata[39:32];
                            if(s_eth_axi_payload_tkeep[5] == 1'b1)  m_arp_tha_n[23:16]   = s_eth_axi_payload_tdata[47:40];
                            if(s_eth_axi_payload_tkeep[6] == 1'b1)  m_arp_tha_n[15:8]    = s_eth_axi_payload_tdata[55:48];
                            if(s_eth_axi_payload_tkeep[7] == 1'b1)  m_arp_tha_n[7:0]     = s_eth_axi_payload_tdata[63:56];
                                                
                        end
                        
                        3: begin

                            if(s_eth_axi_payload_tkeep[0] == 1'b1)  m_arp_tpa_n[31:24]   = s_eth_axi_payload_tdata[7:0];
                            if(s_eth_axi_payload_tkeep[1] == 1'b1)  m_arp_tpa_n[23:16]   = s_eth_axi_payload_tdata[15:8];
                            if(s_eth_axi_payload_tkeep[2] == 1'b1)  m_arp_tpa_n[15:8]    = s_eth_axi_payload_tdata[23:16]; 
                            if(s_eth_axi_payload_tkeep[3] == 1'b1)  
                            begin 
                                    m_arp_tpa_n[7:0] = s_eth_axi_payload_tdata[31:24]; 
                                    rd_arp_hdr_n     = 1'b0; 
                            end
                            
                                                
                        end
                    
                    endcase
                
                end////DATAW == 64
                
            end//rd_arp_hdr_r
            
            if(s_eth_axi_payload_tlast) begin
            
                if(rd_arp_hdr_n)
                    err_hdr_early_termination_n = 1'b1;
                else if(m_arp_hlen_n != 4'd6 || m_arp_plen_n != 4'd4)
                    err_invalid_hdr_n = 1'b1;
                else 
                    //trigger valid arp frame signal if there is not a user that wants to send frames on the bus
                    m_frame_valid_n = !s_eth_axi_payload_tuser;
                    
                ptr_n = 1'b0;
                rd_eth_hdr_n = 1'b1;
                rd_arp_hdr_n = 1'b1;
            
            end
        
        end//s_eth_axi_payload_tvalid && s_eth_axi_payload_tready
        
        if(rd_eth_hdr_n) 
            s_eth_hdr_ready_n = !m_frame_valid_n;
        else 
            s_eth_axi_payload_tready_n = 1'b1;
        
    end
    
    always@(posedge clk) begin
    
        rd_eth_hdr_r  <= rd_eth_hdr_n;
        rd_arp_hdr_r  <= rd_arp_hdr_n;
        ptr_r         <= ptr_n;
        
        s_eth_hdr_ready_r          <= s_eth_hdr_ready_n;
        s_eth_axi_payload_tready_r <= s_eth_axi_payload_tready_n;
        m_frame_valid_r            <= m_frame_valid_n;
        
        m_arp_htype_r <= m_arp_htype_n;
        m_arp_ptype_r <= m_arp_ptype_n;
        m_arp_hlen_r  <= m_arp_hlen_n;
        m_arp_plen_r  <= m_arp_plen_n;
        m_arp_oper_r  <= m_arp_oper_n;
        m_arp_sha_r   <= m_arp_sha_n;
        m_arp_spa_r   <= m_arp_spa_n;
        m_arp_tha_r   <= m_arp_tha_n;
        m_arp_tpa_r   <= m_arp_tpa_n;
        
        err_hdr_early_termination_r <= err_hdr_early_termination_n;
        err_invalid_hdr_r           <= err_invalid_hdr_n;
        
        busy_r <= rd_arp_hdr_n;
        
        if(str_eth_hdr) begin
        
            m_eth_dest_mac_r <= s_eth_dest_mac;
            m_eth_src_mac_r  <= s_eth_src_mac;
            m_eth_type_r     <= s_eth_type;
        
        end
        
        if(reset) begin
        
            rd_eth_hdr_r <= 1'b1;
            rd_arp_hdr_r <= 1'b0;
            ptr_r        <= 0;
            
            s_eth_axi_payload_tready_r <= 1'b0;
            m_frame_valid_r            <= 1'b0;
            busy_r                     <= 1'b0;
            
            err_hdr_early_termination_r <= 1'b0;
            err_invalid_hdr_r           <= 1'b0;
        
        end
    
    end
    
endmodule
