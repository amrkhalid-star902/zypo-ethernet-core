`timescale 1ns / 1ps

/*
*   This module is used to receive the different Ethernet header fields in parrallel and the payload associated
*   with the headers through an AXI interface, then generate the different IP header fields, sends them in parrallel, 
*   and after that it sends the IP payload through AXI interface
*/

module ip_eth_rx(

    input  logic clk,
    input  logic reset,
    
    /*
    *   The Ethernet frame input to the slave side of the receiver
    */
    //Header signals sent by the master
    input  logic           s_eth_hdr_valid,
    input  logic [47 : 0]  s_eth_dest_mac,
    input  logic [47 : 0]  s_eth_src_mac,
    input  logic [15 : 0]  s_eth_type,
    
    //Payload signals sent by the master after sending the header
    input  logic [7  : 0]  s_eth_axi_payload_tdata,
    input  logic           s_eth_axi_payload_tvalid,
    input  logic           s_eth_axi_payload_tlast,   //End of the frame (EOF)
    input  logic           s_eth_axi_payload_tuser,   //Start of the frame (SOF)
    output logic           s_eth_hdr_ready,
    output logic           s_eth_axi_payload_tready,
    
    /*
    *   IP Packet Output
    */
    input  logic           m_ip_hdr_ready,
    input  logic           m_ip_axi_payload_tready,
    output logic [47 : 0]  m_eth_dest_mac,
    output logic [47 : 0]  m_eth_src_mac,
    output logic [15 : 0]  m_eth_type, 
    
    //IP header fields
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
    output logic           busy,
    output logic           err_invalid_hdr,
    output logic           err_invalid_checksum,
    output logic           err_hdr_early_termination,
    output logic           err_payload_early_termination

);

    /*
    *    Different fields present in the IP header
    */
    
    /*
    
        Field                     Length
        Version                   4 bits
        IHL                       4 bits
        DSCP                      6 bits
        ECN                       2 bits
        Total Length              2 bytes
        Identification            2 bytes
        Flags                     3 bits
        Fragment offset           13 bits
        Time-to-live              1 byte
        Protocol                  1 byte
        Header checksum           2 bytes
        SourceIP                  4 bytes
        DestinationIP             4 bytes
        Options                   IHL > 5 ? (IHL-5)*4 : 0; 
        payload                   Total Length bytes
        
    */
    
    //State Machine
    localparam [2 : 0] IDLE         = 0;
    localparam [2 : 0] HEADER_RD    = 1;     //read header state
    localparam [2 : 0] PAYLOAD_RD   = 2;     //read payload state
    localparam [2 : 0] PAYLOAD_LAST = 3;
    localparam [2 : 0] WAIT_LAST    = 4;
    
    logic [2 : 0] current_state, next_state;
    
    logic [5  : 0] hdr_ptr_r, hdr_ptr_n;
    logic [15 : 0] byte_count_r, byte_count_n;
    logic [15 : 0] hdr_sum_r, hdr_sum_n;    
    logic [7  : 0] last_data_byte_r;
    
    logic s_eth_hdr_ready_r, s_eth_hdr_ready_n;
    logic s_eth_axi_payload_tready_r, s_eth_axi_payload_tready_n;
    logic str_eth_hdr;
    logic str_last_byte;
    
	logic           m_ip_hdr_valid_r, m_ip_hdr_valid_n;    
    logic [47 : 0]  m_eth_dest_mac_r;
    logic [47 : 0]  m_eth_src_mac_r;
    logic [15 : 0]  m_eth_type_r, m_eth_type_n; 
    logic [3  : 0]  m_ip_version_r, m_ip_version_n;
    logic [3  : 0]  m_ip_ihl_r, m_ip_ihl_n;
    logic [5  : 0]  m_ip_dscp_r, m_ip_dscp_n;
    logic [1  : 0]  m_ip_ecn_r, m_ip_ecn_n;
    logic [15 : 0]  m_ip_len_r, m_ip_len_n;       
    logic [15 : 0]  m_ip_iden_r, m_ip_iden_n;
    logic [2  : 0]  m_ip_flags_r, m_ip_flags_n;
    logic [12 : 0]  m_ip_frag_off_r, m_ip_frag_off_n;
    logic [7  : 0]  m_ip_ttl_r, m_ip_ttl_n;
    logic [7  : 0]  m_ip_protocol_r, m_ip_protocol_n;
    logic [15 : 0]  m_ip_checksum_r, m_ip_checksum_n;
    logic [31 : 0]  m_ip_src_ip_r, m_ip_src_ip_n;
    logic [31 : 0]  m_ip_dest_ip_r, m_ip_dest_ip_n;
    
    logic busy_r;
    logic err_invalid_hdr_r, err_invalid_hdr_n;
    logic err_invalid_checksum_r, err_invalid_checksum_n;
    logic err_hdr_early_termination_r, err_hdr_early_termination_n;
    logic err_payload_early_termination_r, err_payload_early_termination_n;
    
    //Datapath signals
    logic [7 : 0] m_ip_axi_payload_tdata_internal;
    logic         m_ip_axi_payload_tvalid_internal;
    logic         m_ip_axi_payload_tready_internal;
    logic         m_ip_axi_payload_tready_internal_e;
    logic         m_ip_axi_payload_tlast_internal;
    logic         m_ip_axi_payload_tuser_internal;
    
    assign s_eth_hdr_ready          = s_eth_hdr_ready_r;
    assign s_eth_axi_payload_tready = s_eth_axi_payload_tready_r;
    
    assign m_ip_hdr_valid = m_ip_hdr_valid_r;
    assign m_eth_dest_mac = m_eth_dest_mac_r;
    assign m_eth_src_mac  = m_eth_src_mac_r;
    assign m_eth_type     = m_eth_type_r;
    assign m_ip_version   = m_ip_version_r;
    assign m_ip_ihl       = m_ip_ihl_r;
    assign m_ip_dscp      = m_ip_dscp_r;
    assign m_ip_ecn       = m_ip_ecn_r;
    assign m_ip_len       = m_ip_len_r;
    assign m_ip_iden      = m_ip_iden_r;
    assign m_ip_flags     = m_ip_flags_r;
    assign m_ip_frag_off  = m_ip_frag_off_r;
    assign m_ip_ttl       = m_ip_ttl_r;
    assign m_ip_protocol  = m_ip_protocol_r;
    assign m_ip_checksum  = m_ip_checksum_r;
    assign m_ip_src_ip    = m_ip_src_ip_r;
    assign m_ip_dest_ip   = m_ip_dest_ip_r;
    
    assign busy                          = busy_r;
    assign err_invalid_hdr               = err_invalid_hdr_r;
    assign err_invalid_checksum          = err_invalid_checksum_r;
    assign err_hdr_early_termination     = err_hdr_early_termination_r;
    assign err_payload_early_termination = err_payload_early_termination_r;
    
    //Function to perform 1's Complement sum
    function logic [15 : 0] sum1c (input logic [15 : 0] a, b);
    
        logic [16 : 0] sum;
        begin
        
            sum   = a + b;
            sum1c = sum[15:0] + sum[16]; 
        
        end
    
    endfunction
    
    always_comb begin
    
        next_state = IDLE;
        
        s_eth_hdr_ready_n          = 1'b0;
        s_eth_axi_payload_tready_n = 1'b0;
        
        str_last_byte = 1'b0;
        str_eth_hdr   = 1'b0;
        
        hdr_ptr_n    = hdr_ptr_r;
        byte_count_n = byte_count_r;
        hdr_sum_n    = hdr_sum_r;
        
        m_ip_hdr_valid_n = m_ip_hdr_valid_r && !m_ip_hdr_ready;
        
        err_hdr_early_termination_n     = 1'b0;
        err_payload_early_termination_n = 1'b0;
        
        err_invalid_hdr_n      = 1'b0;
        err_invalid_checksum_n = 1'b0;
        
        m_ip_axi_payload_tdata_internal  = 8'b0;
        m_ip_axi_payload_tvalid_internal = 1'b0;
        m_ip_axi_payload_tlast_internal  = 1'b0;
        m_ip_axi_payload_tuser_internal  = 1'b0;
        
        m_ip_version_n   = m_ip_version_r;
        m_ip_ihl_n       = m_ip_ihl_r;
        m_ip_dscp_n      = m_ip_dscp_r;
        m_ip_ecn_n       = m_ip_ecn_r;
        m_ip_len_n       = m_ip_len_r;
        m_ip_iden_n      = m_ip_iden_r;
        m_ip_flags_n     = m_ip_flags_r;
        m_ip_frag_off_n  = m_ip_frag_off_r;
        m_ip_ttl_n       = m_ip_ttl_r;
        m_ip_protocol_n  = m_ip_protocol_r;
        m_ip_checksum_n  = m_ip_checksum_r;
        m_ip_src_ip_n    = m_ip_src_ip_r;
        m_ip_dest_ip_n   = m_ip_dest_ip_r;
        
        case(current_state)
            
            IDLE: begin
            
                //wait for valid header
                hdr_ptr_n = 6'b0;
                hdr_sum_n = 16'b0;
                
                s_eth_hdr_ready_n = !m_ip_hdr_valid_n;
                
                if(s_eth_hdr_valid && s_eth_hdr_ready) begin
                
                    s_eth_hdr_ready_n          = 1'b0;
                    s_eth_axi_payload_tready_n = 1'b1; 
                    str_eth_hdr                = 1'b1;
                    next_state                 = HEADER_RD;
                
                end
                else begin
                
                    next_state = IDLE;
                
                end
            
            end//IDLE
            
            HEADER_RD: begin
            
                s_eth_axi_payload_tready_n = 1'b1;
                
                //The number of bytes equal to the Length field in the IP header minus the length of the header
                byte_count_n = m_ip_len_r - 16'h14;
                
                if(s_eth_axi_payload_tvalid && s_eth_axi_payload_tready) begin
                
                    hdr_ptr_n  = hdr_ptr_r + 1;
                    next_state = HEADER_RD;
                    
                
                    //The 1's Complement sum is perfromed on 16 bits of received data
                    //when the data recived posistion is even then the input is {data0, 8'b0}
                    //when the data recived posistion is odd  then the input is {8'b0, data1}
                    //in this way the two conssective piece of data will produce 16 bit word
                    //when they summed together (data0, data1) (IP header data is sent in Big Endian Way)
                    if(hdr_ptr_n[0]) 
                        hdr_sum_n = sum1c(hdr_sum_r, {8'b0, s_eth_axi_payload_tdata});
                    else
                        hdr_sum_n = sum1c(hdr_sum_r, {s_eth_axi_payload_tdata, 8'b0});
                        
                    case(hdr_ptr_r)
                    
                        6'h0 : {m_ip_version_n, m_ip_ihl_n}            = s_eth_axi_payload_tdata; 
                        6'h1 : {m_ip_dscp_n, m_ip_ecn_n}               = s_eth_axi_payload_tdata; 
                        6'h2 : m_ip_len_n[15 : 8]                      = s_eth_axi_payload_tdata; 
                        6'h3 : m_ip_len_n[7  : 0]                      = s_eth_axi_payload_tdata;
                        6'h4 : m_ip_iden_n[15 : 0]                     = s_eth_axi_payload_tdata; 
                        6'h5 : m_ip_iden_n[7  : 0]                     = s_eth_axi_payload_tdata; 
                        6'h6 : {m_ip_flags_n, m_ip_frag_off_n[12 : 8]} = s_eth_axi_payload_tdata;
                        6'h7 : m_ip_frag_off_n[7  : 0]                 = s_eth_axi_payload_tdata;
                        6'h8 : m_ip_ttl_n                              = s_eth_axi_payload_tdata;
                        6'h9 : m_ip_protocol_n                         = s_eth_axi_payload_tdata;
                        6'ha : m_ip_checksum_n[15 : 8]                 = s_eth_axi_payload_tdata;
                        6'hb : m_ip_checksum_n[7  : 0]                 = s_eth_axi_payload_tdata;
                        6'hc : m_ip_src_ip_n[31 : 24]                  = s_eth_axi_payload_tdata;
                        6'hd : m_ip_src_ip_n[23 : 16]                  = s_eth_axi_payload_tdata;
                        6'he : m_ip_src_ip_n[15 : 8]                   = s_eth_axi_payload_tdata;
                        6'hf : m_ip_src_ip_n[7  : 0]                   = s_eth_axi_payload_tdata;
                        6'h10: m_ip_dest_ip_n[31 : 24]                 = s_eth_axi_payload_tdata;
                        6'h11: m_ip_dest_ip_n[23 : 16]                 = s_eth_axi_payload_tdata;
                        6'h12: m_ip_dest_ip_n[15  : 8]                 = s_eth_axi_payload_tdata;
                        6'h13: begin
                        
                            m_ip_dest_ip_n[7 : 0] = s_eth_axi_payload_tdata;
                            if(m_ip_version_r != 4'h4 || m_ip_ihl_r != 4'h5) begin
                                
                                //IP version is not version 4
                                //Packets containing some options considered as dangerous so they are dropped 
                                err_invalid_hdr_n = 1'b1;
                                next_state = WAIT_LAST;
                            
                            end else if(hdr_sum_n != 16'hffff) begin
                            
                                 err_invalid_checksum_n = 1'b1;   
                                 next_state             = WAIT_LAST;
                            
                            end else begin
                            
                                m_ip_hdr_valid_n = 1'b1;
                                next_state       = PAYLOAD_RD;
                                
                                s_eth_axi_payload_tready_n = m_ip_axi_payload_tready_internal_e;
                            
                            end
                        
                        end
                    
                    endcase
                    
                    if(s_eth_axi_payload_tlast) begin
                    
                        err_hdr_early_termination_n = 1'b1;
                        m_ip_hdr_valid_n            = 1'b0;
                        s_eth_hdr_ready_n           = !m_ip_hdr_valid_n;
                        s_eth_axi_payload_tready_n  = 1'b0;
                        next_state                  = IDLE;
                    
                    end
                
                end else begin
                
                    next_state = HEADER_RD;
                
                end

            
            end//HEADER_RD
            
            PAYLOAD_RD: begin
                
                //Read the payload of the IP frame
                s_eth_axi_payload_tready_n = m_ip_axi_payload_tready_internal_e;
               
                m_ip_axi_payload_tdata_internal = s_eth_axi_payload_tdata;
                m_ip_axi_payload_tlast_internal = s_eth_axi_payload_tlast;
                m_ip_axi_payload_tuser_internal = s_eth_axi_payload_tuser;
               
                if(s_eth_axi_payload_tvalid && s_eth_axi_payload_tready) begin
               
                    //Byte transfer
                    byte_count_n = byte_count_r - 1; 
                    
                    m_ip_axi_payload_tvalid_internal = 1'b1;    
                    if(s_eth_axi_payload_tlast) begin
                    
                        if(byte_count_r > 1) begin
                            
                            //The length dosnot match the Length field in the header
                            m_ip_axi_payload_tuser_internal = 1'b1;
                            err_payload_early_termination_n = 1'b1;
                        
                        end
                        
                        s_eth_hdr_ready_n           = !m_ip_hdr_valid_n;
                        s_eth_axi_payload_tready_n  = 1'b0;
                        next_state                  = IDLE;
                    
                    end else begin
                    
                        if(byte_count_r == 1) begin
                        
                            str_last_byte                    = 1'b1;
                            m_ip_axi_payload_tvalid_internal = 1'b0;
                            next_state                       = PAYLOAD_LAST;
                        
                        end else begin
                            
                            next_state = PAYLOAD_RD;
                        
                        end
                    
                    end          
               
                end else begin
                
                    next_state = PAYLOAD_RD;
                
                end
            
            end//PAYLOAD_RD
            
            PAYLOAD_LAST: begin
            
                s_eth_axi_payload_tready_n = m_ip_axi_payload_tready_internal_e;
                
                m_ip_axi_payload_tdata_internal = last_data_byte_r;
                m_ip_axi_payload_tlast_internal = s_eth_axi_payload_tlast;
                m_ip_axi_payload_tuser_internal = s_eth_axi_payload_tuser;
                
                if(s_eth_axi_payload_tvalid && s_eth_axi_payload_tready) begin
                
                    if(s_eth_axi_payload_tlast) begin
                    
                        s_eth_hdr_ready_n                = !m_ip_hdr_valid_n;
                        s_eth_axi_payload_tready_n       = 1'b0;
                        m_ip_axi_payload_tvalid_internal = 1'b0;
                        next_state                       = IDLE;
                    
                    end else begin
                    
                        next_state = PAYLOAD_LAST;
                    
                    end

                end else begin
                
                    next_state = PAYLOAD_LAST;
                
                end
            
            end//PAYLOAD_LAST
            
            WAIT_LAST: begin
            
                //Read and discard until EOF
                s_eth_axi_payload_tready_n = 1'b1;
                
                if(s_eth_axi_payload_tvalid && s_eth_axi_payload_tready) begin
                
                    if(s_eth_axi_payload_tlast) begin
                
                        s_eth_hdr_ready_n                = !m_ip_hdr_valid_n;
                        s_eth_axi_payload_tready_n       = 1'b0;
                        next_state                       = IDLE;
                
                    end else begin
                    
                        next_state = WAIT_LAST;
                    
                    end
                
                end else begin
                
                    next_state = WAIT_LAST;
                
                end
            
            end//WAIT_LAST
        
        endcase
    
    end
    
    always@(posedge clk) begin
        
        m_ip_version_r   <= m_ip_version_n;
        m_ip_ihl_r       <= m_ip_ihl_n;
        m_ip_dscp_r      <= m_ip_dscp_n;
        m_ip_ecn_r       <= m_ip_ecn_n;
        m_ip_len_r       <= m_ip_len_n;
        m_ip_iden_r      <= m_ip_iden_n;
        m_ip_flags_r     <= m_ip_flags_n;
        m_ip_frag_off_r  <= m_ip_frag_off_n;
        m_ip_ttl_r       <= m_ip_ttl_n;
        m_ip_protocol_r  <= m_ip_protocol_n;
        m_ip_checksum_r  <= m_ip_checksum_n;
        m_ip_src_ip_r    <= m_ip_src_ip_n;
        m_ip_dest_ip_r   <= m_ip_dest_ip_n;
        
        if(reset) begin
        
            current_state                    <= IDLE;
            s_eth_hdr_ready_r                <= 1'b0;
            s_eth_axi_payload_tready_r       <= 1'b0;
            m_ip_hdr_valid_r                 <= 1'b0;
            busy_r                           <= 1'b0;
            err_invalid_hdr_r                <= 1'b0;
            err_invalid_checksum_r           <= 1'b0;
            err_hdr_early_termination_r      <= 1'b0;
            err_payload_early_termination_r  <= 1'b0;
        
        end else begin
        
            current_state                    <= next_state;
            s_eth_hdr_ready_r                <= s_eth_hdr_ready_n;
            s_eth_axi_payload_tready_r       <= s_eth_axi_payload_tready_n;
            m_ip_hdr_valid_r                 <= m_ip_hdr_valid_n;
            busy_r                           <= next_state != IDLE;
            err_invalid_hdr_r                <= err_invalid_hdr_n;
            err_invalid_checksum_r           <= err_invalid_checksum_n;
            err_hdr_early_termination_r      <= err_hdr_early_termination_n;
            err_payload_early_termination_r  <= err_payload_early_termination_n;
        
        end
        
        hdr_ptr_r     <= hdr_ptr_n;
        byte_count_r  <= byte_count_n;
        hdr_sum_r     <= hdr_sum_n;
        
        //Datapath signals update
        if(str_eth_hdr) begin
        
            m_eth_dest_mac_r  <= s_eth_dest_mac;
            m_eth_src_mac_r   <= s_eth_src_mac;
            m_eth_type_r      <= s_eth_type;
        
        end
        
        if(str_last_byte) begin
        
            last_data_byte_r <= m_ip_axi_payload_tdata_internal;
        
        end
        
    
    end
    
    logic [7 : 0] m_ip_axi_payload_tdata_r;
    logic         m_ip_axi_payload_tvalid_r, m_ip_axi_payload_tvalid_n;
    logic         m_ip_axi_payload_tlast_r;
    logic         m_ip_axi_payload_tuser_r;
    
    logic [7 : 0] m_ip_axi_payload_tdata_temp;
    logic         m_ip_axi_payload_tvalid_temp, m_ip_axi_payload_tvalid_temp_n;
    logic         m_ip_axi_payload_tlast_temp;
    logic         m_ip_axi_payload_tuser_temp;
    
    //Datapath control signals
    logic str_ip_payload_internal_to_out;
    logic str_ip_payload_internal_to_temp;
    logic str_ip_payload_temp_to_out;
    
    assign m_ip_axi_payload_tdata  = m_ip_axi_payload_tdata_r;
    assign m_ip_axi_payload_tvalid = m_ip_axi_payload_tvalid_r;
    assign m_ip_axi_payload_tlast  = m_ip_axi_payload_tlast_r;
    assign m_ip_axi_payload_tuser  = m_ip_axi_payload_tuser_r;
    
    
    assign m_ip_axi_payload_tready_internal_e = m_ip_axi_payload_tready || (!m_ip_axi_payload_tvalid_temp && !m_ip_axi_payload_tvalid_r);
    
    always_comb begin
    
        m_ip_axi_payload_tvalid_n      = m_ip_axi_payload_tvalid_r;
        m_ip_axi_payload_tvalid_temp_n = m_ip_axi_payload_tvalid_temp;
        
        str_ip_payload_internal_to_out  = 1'b0;
        str_ip_payload_internal_to_temp = 1'b0;
        str_ip_payload_temp_to_out      = 1'b0;
        
        if(m_ip_axi_payload_tready_internal) begin
        
            //there is ready input
            if(m_ip_axi_payload_tready || !m_ip_axi_payload_tvalid_r) begin
            
                //The output is ready or,
                //it still currently not valid
                m_ip_axi_payload_tvalid_n      = m_ip_axi_payload_tvalid_internal;
                str_ip_payload_internal_to_out = 1'b1;
            
            end else begin
                
                //output is not ready
                //store it in temp registers
                m_ip_axi_payload_tvalid_temp_n   = m_ip_axi_payload_tvalid_internal;
                str_ip_payload_internal_to_temp  = 1'b1;
            
            end
        
        end else if(m_ip_axi_payload_tready) begin
        
            //input is not ready but output is
            m_ip_axi_payload_tvalid_n      = m_ip_axi_payload_tvalid_temp;
            m_ip_axi_payload_tvalid_temp_n = 1'b0;
            str_ip_payload_temp_to_out     = 1'b1;
        
        end
    
    end
    
    always@(posedge clk) begin
    
        m_ip_axi_payload_tvalid_r        <= m_ip_axi_payload_tvalid_n;
        m_ip_axi_payload_tvalid_temp     <= m_ip_axi_payload_tvalid_temp_n;
        m_ip_axi_payload_tready_internal <= m_ip_axi_payload_tready_internal_e;
        
        if(str_ip_payload_internal_to_out) begin
        
            m_ip_axi_payload_tdata_r <= m_ip_axi_payload_tdata_internal;
            m_ip_axi_payload_tlast_r <= m_ip_axi_payload_tlast_internal;
            m_ip_axi_payload_tuser_r <= m_ip_axi_payload_tuser_internal;
        
        end else if(str_ip_payload_temp_to_out) begin
        
            m_ip_axi_payload_tdata_r <= m_ip_axi_payload_tdata_temp;
            m_ip_axi_payload_tlast_r <= m_ip_axi_payload_tlast_temp;
            m_ip_axi_payload_tuser_r <= m_ip_axi_payload_tuser_temp;
    
        
        end
        
        if(str_ip_payload_internal_to_temp) begin
        
            m_ip_axi_payload_tdata_temp <= m_ip_axi_payload_tdata_internal;
            m_ip_axi_payload_tlast_temp <= m_ip_axi_payload_tlast_internal;
            m_ip_axi_payload_tuser_temp <= m_ip_axi_payload_tuser_internal;
        
        end
        
        if(reset) begin
        
            m_ip_axi_payload_tvalid_r        <= 1'b0;
            m_ip_axi_payload_tvalid_temp     <= 1'b0;
            m_ip_axi_payload_tready_internal <= 1'b0;
        
        end
    
    end
    
endmodule
