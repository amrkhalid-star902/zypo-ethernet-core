`timescale 1ns / 1ps


module arp_eth_tx#(

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
    
    //ARP Frame Input
    input  logic                s_frame_valid,
    input  logic [47 : 0]       s_eth_dest_mac,
    input  logic [47 : 0]       s_eth_src_mac,
    input  logic [15 : 0]       s_eth_type,   
    input  logic [15 : 0]       s_arp_htype,
    input  logic [15 : 0]       s_arp_ptype,
    input  logic [15 : 0]       s_arp_oper,
    input  logic [47 : 0]       s_arp_sha,
    input  logic [31 : 0]       s_arp_spa,
    input  logic [47 : 0]       s_arp_tha,
    input  logic [31 : 0]       s_arp_tpa,
    output logic                s_frame_ready,
    
    //Ethernet Frame Output
	input  logic                m_eth_hdr_ready,
    input  logic                m_eth_axi_payload_tready,
    output logic                m_eth_hdr_valid,
    output logic [47 : 0]       m_eth_dest_mac,
    output logic [47 : 0]       m_eth_src_mac,
    output logic [15 : 0]       m_eth_type,
    output logic [DATAW-1 : 0]  m_eth_axi_payload_tdata,
    output logic [TDATAW-1 : 0] m_eth_axi_payload_tkeep,
    output logic                m_eth_axi_payload_tvalid,
    output logic                m_eth_axi_payload_tlast,   //End of the frame (EOF)
    output logic                m_eth_axi_payload_tuser,   //Start of the frame (SOF)
    
    //Status
    output logic                busy

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
    
    logic str_frame;
    logic send_arp_hdr_r, send_arp_hdr_n;
    
    logic [PTRW-1 : 0] ptr_r, ptr_n;
    
    logic [15 : 0]  arp_htype_r;
    logic [15 : 0]  arp_ptype_r;
    logic [15  : 0] arp_oper_r;
    logic [47  : 0] arp_sha_r;
    logic [31  : 0] arp_spa_r;
    logic [47  : 0] arp_tha_r;
    logic [31  : 0] arp_tpa_r;
    
    logic s_frame_ready_r, s_frame_ready_n;
    logic m_eth_hdr_valid_r, m_eth_hdr_valid_n;
    logic busy_r;
    
    logic [47 : 0]  m_eth_dest_mac_r;
    logic [47 : 0]  m_eth_src_mac_r;
    logic [15 : 0]  m_eth_type_r;
    
    logic [DATAW-1 : 0]  m_eth_axi_payload_tdata_i;
    logic [TDATAW-1 : 0] m_eth_axi_payload_tkeep_i;
    logic                m_eth_axi_payload_tvalid_i;
    logic                m_eth_axi_payload_tready_i;
    logic                m_eth_axi_payload_tready_e;
    logic                m_eth_axi_payload_tlast_i;
    logic                m_eth_axi_payload_tuser_i;
    
    assign s_frame_ready   = s_frame_ready_r;
    assign m_eth_hdr_valid = m_eth_hdr_valid_r;
    assign m_eth_dest_mac  = m_eth_dest_mac_r;
    assign m_eth_src_mac   = m_eth_src_mac_r;
    assign m_eth_type      = m_eth_type_r;
    assign busy            = busy_r;
    
    always_comb begin
    
        send_arp_hdr_n  = send_arp_hdr_r;
        s_frame_ready_n = 1'b0;
        
        ptr_n     = ptr_r;
        str_frame = 1'b0;
        
        m_eth_hdr_valid_n = m_eth_hdr_valid_r && !m_eth_hdr_ready;
        
        m_eth_axi_payload_tdata_i  = 0;
        m_eth_axi_payload_tkeep_i  = 0;
        m_eth_axi_payload_tvalid_i = 1'b0;
        m_eth_axi_payload_tlast_i  = 1'b0;
        m_eth_axi_payload_tuser_i  = 1'b0;
        
        if(s_frame_ready && s_frame_valid) begin
        
            str_frame = 1'b1;
            ptr_n     = 0;
            
            m_eth_hdr_valid_n = 1'b1;
            send_arp_hdr_n    = 1'b1;
        
        end
        
        if(m_eth_axi_payload_tready_i) begin
            
            if(send_arp_hdr_r) begin
            
                ptr_n = ptr_r + 1;
                
                m_eth_axi_payload_tdata_i  = 0;
                m_eth_axi_payload_tkeep_i  = 0;
                m_eth_axi_payload_tvalid_i = 1'b1;
                m_eth_axi_payload_tlast_i  = 1'b0;
                m_eth_axi_payload_tuser_i  = 1'b0;
                
                if(DATAW == 8) begin
                    
                    m_eth_axi_payload_tkeep_i = 1'b1;
                    case(ptr_r)
                    
                        0:  m_eth_axi_payload_tdata_i = arp_htype_r[15:8];
                        1:  m_eth_axi_payload_tdata_i = arp_htype_r[7:0];
                        2:  m_eth_axi_payload_tdata_i = arp_ptype_r[15:8];
                        3:  m_eth_axi_payload_tdata_i = arp_ptype_r[7:0];
                        4:  m_eth_axi_payload_tdata_i = 8'd6;
                        5:  m_eth_axi_payload_tdata_i = 8'd4;
                        6:  m_eth_axi_payload_tdata_i = arp_oper_r[15:8];
                        7:  m_eth_axi_payload_tdata_i = arp_oper_r[7:0];
                        8:  m_eth_axi_payload_tdata_i = arp_sha_r[47:40];
                        9:  m_eth_axi_payload_tdata_i = arp_sha_r[39:32];
                        10: m_eth_axi_payload_tdata_i = arp_sha_r[31:24];
                        11: m_eth_axi_payload_tdata_i = arp_sha_r[23:16];
                        12: m_eth_axi_payload_tdata_i = arp_sha_r[15:8];
                        13: m_eth_axi_payload_tdata_i = arp_sha_r[7:0];
                        14: m_eth_axi_payload_tdata_i = arp_spa_r[31:24];
                        15: m_eth_axi_payload_tdata_i = arp_spa_r[23:16];
                        16: m_eth_axi_payload_tdata_i = arp_spa_r[15:8];
                        17: m_eth_axi_payload_tdata_i = arp_spa_r[7:0];
                        18: m_eth_axi_payload_tdata_i = arp_tha_r[47:40];
                        19: m_eth_axi_payload_tdata_i = arp_tha_r[39:32];
                        20: m_eth_axi_payload_tdata_i = arp_tha_r[31:24];
                        21: m_eth_axi_payload_tdata_i = arp_tha_r[23:16];
                        22: m_eth_axi_payload_tdata_i = arp_tha_r[15:8];
                        23: m_eth_axi_payload_tdata_i = arp_tha_r[7:0];
                        24: m_eth_axi_payload_tdata_i = arp_tpa_r[31:24];
                        25: m_eth_axi_payload_tdata_i = arp_tpa_r[23:16];
                        26: m_eth_axi_payload_tdata_i = arp_tpa_r[15:8];
                        27: begin 
                        
                                m_eth_axi_payload_tdata_i  = arp_tpa_r[7:0];
                                m_eth_axi_payload_tlast_i  = 1'b1;
                                send_arp_hdr_n             = 1'b0;
                                
                            end
                        
                    endcase
                
                end//DATAW == 8
                
                if(DATAW == 64) begin
                
                    case(ptr_r)
                    
                        0: begin
                        
                            m_eth_axi_payload_tdata_i[7:0]   = arp_htype_r[15:8];
                            m_eth_axi_payload_tdata_i[15:8]  = arp_htype_r[7:0]; 
                            m_eth_axi_payload_tdata_i[23:16] = arp_ptype_r[15:8];
                            m_eth_axi_payload_tdata_i[31:24] = arp_ptype_r[7 :0]; 
                            m_eth_axi_payload_tdata_i[39:32] = 8'd6;
                            m_eth_axi_payload_tdata_i[47:40] = 8'd4;
                            m_eth_axi_payload_tdata_i[55:48] = arp_oper_r[15:8];
                            m_eth_axi_payload_tdata_i[63:56] = arp_oper_r[7:0];
                            
                            m_eth_axi_payload_tkeep_i = 8'hff;
                        
                        end
                        
                        1: begin
                        
                            m_eth_axi_payload_tdata_i[7:0]   = arp_sha_r[47:40];
                            m_eth_axi_payload_tdata_i[15:8]  = arp_sha_r[39:32]; 
                            m_eth_axi_payload_tdata_i[23:16] = arp_sha_r[31:24];
                            m_eth_axi_payload_tdata_i[31:24] = arp_sha_r[23:16]; 
                            m_eth_axi_payload_tdata_i[39:32] = arp_sha_r[15:8]; 
                            m_eth_axi_payload_tdata_i[47:40] = arp_sha_r[7:0]; 
                            m_eth_axi_payload_tdata_i[55:48] = arp_spa_r[31:24];
                            m_eth_axi_payload_tdata_i[63:56] = arp_spa_r[23:16];
                            
                            m_eth_axi_payload_tkeep_i = 8'hff;
                        
                        end
                        
                        2: begin
                        
                            m_eth_axi_payload_tdata_i[7:0]   = arp_spa_r[15:8];
                            m_eth_axi_payload_tdata_i[15:8]  = arp_spa_r[7:0]; 
                            m_eth_axi_payload_tdata_i[23:16] = arp_tha_r[47:40];
                            m_eth_axi_payload_tdata_i[31:24] = arp_tha_r[39:32]; 
                            m_eth_axi_payload_tdata_i[39:32] = arp_tha_r[31:24]; 
                            m_eth_axi_payload_tdata_i[47:40] = arp_tha_r[23:16]; 
                            m_eth_axi_payload_tdata_i[55:48] = arp_tha_r[15:8];
                            m_eth_axi_payload_tdata_i[63:56] = arp_tha_r[7:0];
                            
                            m_eth_axi_payload_tkeep_i = 8'hff;
                        
                        end 
                        
                        3: begin
                        
                            m_eth_axi_payload_tdata_i[7:0]   = arp_tpa_r[31:24];
                            m_eth_axi_payload_tdata_i[15:8]  = arp_tpa_r[23:16]; 
                            m_eth_axi_payload_tdata_i[23:16] = arp_tpa_r[15:8];
                            m_eth_axi_payload_tdata_i[31:24] = arp_tpa_r[7:0]; 
                            m_eth_axi_payload_tdata_i[39:32] = 8'hff; 
                            m_eth_axi_payload_tdata_i[47:40] = 8'hff; 
                            m_eth_axi_payload_tdata_i[55:48] = 8'hff;
                            m_eth_axi_payload_tdata_i[63:56] = 8'hff;
                            
                            m_eth_axi_payload_tkeep_i  = 8'h0f;
                            m_eth_axi_payload_tlast_i  = 1'b1;
                            send_arp_hdr_n             = 1'b0;
                        
                        end                                                 
                    
                    endcase
                
                end//DATAW == 64
                
            end//send_arp_hdr_n
        
        end//m_eth_axi_payload_tready_i
        
        s_frame_ready_n = !m_eth_hdr_valid_n && !send_arp_hdr_n;
    
    end
    
    always@(posedge clk) begin
    
        send_arp_hdr_r <= send_arp_hdr_n;
        ptr_r          <= ptr_n;
        
        s_frame_ready_r   <= s_frame_ready_n;
        m_eth_hdr_valid_r <= m_eth_hdr_valid_n;
        busy_r            <= send_arp_hdr_n;
        
        if(str_frame) begin
        
            m_eth_dest_mac_r <= s_eth_dest_mac;
            m_eth_src_mac_r  <= s_eth_src_mac;
            m_eth_type_r     <= s_eth_type;
            arp_htype_r      <= s_arp_htype;
            arp_ptype_r      <= s_arp_ptype;
            arp_oper_r       <= s_arp_oper;
            arp_sha_r        <= s_arp_sha;
            arp_spa_r        <= s_arp_spa;
            arp_tha_r        <= s_arp_tha;
            arp_tpa_r        <= s_arp_tpa;
        
        end
        
        if(reset) begin
        
            send_arp_hdr_r <= 1'b0;
            ptr_r          <= 0;
            busy_r         <= 1'b0;
            
            s_frame_ready_r   <= 1'b0;
            m_eth_hdr_valid_r <= 1'b0;
        
        end
    
    end
    
    logic [DATAW-1 : 0]  m_eth_axi_payload_tdata_r;
    logic [TDATAW-1 : 0] m_eth_axi_payload_tkeep_r;
    logic                m_eth_axi_payload_tvalid_r;
    logic                m_eth_axi_payload_tvalid_n;
    logic                m_eth_axi_payload_tlast_r;
    logic                m_eth_axi_payload_tuser_r;
    
    logic [DATAW-1 : 0]  m_eth_axi_payload_tdata_tmp;
    logic [TDATAW-1 : 0] m_eth_axi_payload_tkeep_tmp;
    logic                m_eth_axi_payload_tvalid_tmp_r;
    logic                m_eth_axi_payload_tvalid_tmp_n;
    logic                m_eth_axi_payload_tlast_tmp;
    logic                m_eth_axi_payload_tuser_tmp;
    
    
    logic str_eth_payload_i;                    //Intermediate to output
    logic str_eth_payload_temp;                 //Intermediate to temp 
    logic str_eth_axi_payload_temp_to_output;
    
    assign m_eth_axi_payload_tdata  = m_eth_axi_payload_tdata_r;
    assign m_eth_axi_payload_tkeep  = m_eth_axi_payload_tkeep_r;
    assign m_eth_axi_payload_tvalid = m_eth_axi_payload_tvalid_r;
    assign m_eth_axi_payload_tlast  = m_eth_axi_payload_tlast_r;
    assign m_eth_axi_payload_tuser  = m_eth_axi_payload_tuser_r;
    
    // enable ready input next cycle if output is ready or if both output registers are empty
    assign m_eth_axi_payload_tready_e = m_eth_axi_payload_tready || (!m_eth_axi_payload_tvalid_tmp_r && !m_eth_axi_payload_tvalid_r);
    
    
    always_comb begin
    
        m_eth_axi_payload_tvalid_n     = m_eth_axi_payload_tvalid_r;
        m_eth_axi_payload_tvalid_tmp_n = m_eth_axi_payload_tvalid_tmp_r;
        
        str_eth_payload_i                  = 1'b0;
        str_eth_payload_temp               = 1'b0;
        str_eth_axi_payload_temp_to_output = 1'b0;
        
        if(m_eth_axi_payload_tready_i) begin
        
            if(m_eth_axi_payload_tready || !m_eth_axi_payload_tvalid_r) begin
            
                m_eth_axi_payload_tvalid_n = m_eth_axi_payload_tvalid_i;
                str_eth_payload_i          = 1'b1;
            
            end else begin
            
                m_eth_axi_payload_tvalid_tmp_n = m_eth_axi_payload_tvalid_i;
                str_eth_payload_temp           = 1'b1;
            
            end
        
        end else if(m_eth_axi_payload_tready) begin
        
            // input is not ready, but output is ready
            m_eth_axi_payload_tvalid_n     = m_eth_axi_payload_tvalid_tmp_r;
            m_eth_axi_payload_tvalid_tmp_n = 1'b0;
            
            str_eth_axi_payload_temp_to_output = 1'b1;
        
        end
        
    end
    
    always@(posedge clk) begin
    
        m_eth_axi_payload_tvalid_r  <= m_eth_axi_payload_tvalid_n;
        m_eth_axi_payload_tready_i  <= m_eth_axi_payload_tready_e;
        
        m_eth_axi_payload_tvalid_tmp_r <= m_eth_axi_payload_tvalid_tmp_n;
        
        if(str_eth_payload_i) begin
            
            m_eth_axi_payload_tdata_r <= m_eth_axi_payload_tdata_i;
            m_eth_axi_payload_tkeep_r <= m_eth_axi_payload_tkeep_i;
            m_eth_axi_payload_tlast_r <= m_eth_axi_payload_tlast_i;
            m_eth_axi_payload_tuser_r <= m_eth_axi_payload_tuser_i;
        
        end else if(str_eth_axi_payload_temp_to_output) begin
        
            m_eth_axi_payload_tdata_r <= m_eth_axi_payload_tdata_tmp;
            m_eth_axi_payload_tkeep_r <= m_eth_axi_payload_tkeep_tmp;
            m_eth_axi_payload_tlast_r <= m_eth_axi_payload_tlast_tmp;
            m_eth_axi_payload_tuser_r <= m_eth_axi_payload_tuser_tmp;
        
        end
        
        if(str_eth_payload_temp) begin
        
            m_eth_axi_payload_tdata_tmp <= m_eth_axi_payload_tdata_i;
            m_eth_axi_payload_tkeep_tmp <= m_eth_axi_payload_tkeep_i;
            m_eth_axi_payload_tlast_tmp <= m_eth_axi_payload_tlast_i;
            m_eth_axi_payload_tuser_tmp <= m_eth_axi_payload_tuser_i;
        
        end
        
        if(reset) begin
        
            m_eth_axi_payload_tvalid_r     <= 1'b0;
            m_eth_axi_payload_tready_i     <= 1'b0;
            m_eth_axi_payload_tvalid_tmp_r <= 1'b0;
        
        end
    
    end
 
endmodule
