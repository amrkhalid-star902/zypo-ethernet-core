`timescale 1ns / 1ps


/*
*   This module is used to receive IP Frame headers in parrallel and the IP payload, then combine them
*   and convert them to Ethernet payload and send them through AXI interface
*/

module ip_eth_tx(

    input  logic clk,
    input  logic reset,
    
    //IP Frame 
    input  logic [47 : 0]  s_eth_dest_mac,
    input  logic [47 : 0]  s_eth_src_mac,
    input  logic [15 : 0]  s_eth_type,         
    input  logic           s_ip_hdr_valid,
    input  logic [5  : 0]  s_ip_dscp,
    input  logic [1  : 0]  s_ip_ecn,
    input  logic [15 : 0]  s_ip_len,       
    input  logic [15 : 0]  s_ip_iden,
    input  logic [2  : 0]  s_ip_flags,
    input  logic [12 : 0]  s_ip_frag_off,
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
    
    //Ethernet Frame
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
    *   Status Signals
    */
    output logic           busy,
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
    localparam [2 : 0] HEADER_WR    = 1;     //write header state
    localparam [2 : 0] PAYLOAD_WR   = 2;     //write payload state
    localparam [2 : 0] PAYLOAD_LAST = 3;
    //localparam [2 : 0] WAIT_LAST    = 4;
    
    logic [2 : 0] current_state, next_state;
    
    logic [5  : 0] hdr_ptr_r, hdr_ptr_n;
    logic [15 : 0] byte_count_r, byte_count_n;
    logic [15 : 0] hdr_sum_r, hdr_sum_n;    
    logic [7  : 0] last_data_byte_r;
    
    logic [5  : 0]  ip_dscp_r;
    logic [1  : 0]  ip_ecn_r;
    logic [15 : 0]  ip_len_r;       
    logic [15 : 0]  ip_iden_r;
    logic [2  : 0]  ip_flags_r;
    logic [12 : 0]  ip_frag_off_r;
    logic [7  : 0]  ip_ttl_r; 
    logic [7  : 0]  ip_protocol_r;
    logic [31 : 0]  ip_src_ip_r;
    logic [31 : 0]  ip_dest_ip_r;
    
    //Datapath control signals
    logic str_ip_hdr;
    logic str_last_byte;
    
    logic s_ip_hdr_ready_r, s_ip_hdr_ready_n;
    logic s_ip_axi_payload_tready_r, s_ip_axi_payload_tready_n;
    
    logic           m_eth_hdr_valid_r, m_eth_hdr_valid_n;
    logic [47 : 0]  m_eth_dest_mac_r, m_eth_dest_mac_n;
    logic [47 : 0]  m_eth_src_mac_r, m_eth_src_mac_n;
    logic [15 : 0]  m_eth_type_r, m_eth_type_n;
    
    logic busy_r;
    logic err_payload_early_termination_r, err_payload_early_termination_n;
    
    //Datapath signals
    logic [7 : 0] m_eth_axi_payload_tdata_internal;
    logic         m_eth_axi_payload_tvalid_internal;
    logic         m_eth_axi_payload_tready_internal;
    logic         m_eth_axi_payload_tready_internal_e;
    logic         m_eth_axi_payload_tlast_internal;
    logic         m_eth_axi_payload_tuser_internal;
    
    assign s_ip_hdr_ready          = s_ip_hdr_ready_r;
    assign s_ip_axi_payload_tready = s_ip_axi_payload_tready_r;
    
    assign m_eth_hdr_valid = m_eth_hdr_valid_r;
    assign m_eth_dest_mac  = m_eth_dest_mac_r;
    assign m_eth_src_mac   = m_eth_src_mac_r;
    assign m_eth_type      = m_eth_type_r;
    
    assign busy                          = busy_r;
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
    
        s_ip_hdr_ready_n          = 1'b0;
        s_ip_axi_payload_tready_n = 1'b0;
        
        str_last_byte = 1'b0;
        str_ip_hdr    = 1'b0;
        
        hdr_ptr_n    = hdr_ptr_r;
        byte_count_n = byte_count_r;
        hdr_sum_n    = hdr_sum_r;
        
        m_eth_hdr_valid_n = m_eth_hdr_valid_r && !m_eth_hdr_ready;
        

        err_payload_early_termination_n = 1'b0;
        
        
        m_eth_axi_payload_tdata_internal  = 8'b0;
        m_eth_axi_payload_tvalid_internal = 1'b0;
        m_eth_axi_payload_tlast_internal  = 1'b0;
        m_eth_axi_payload_tuser_internal  = 1'b0;
        
        case(current_state)
        
            IDLE: begin
        
                //wait for valid header
                hdr_ptr_n = 6'b0;
                hdr_sum_n = 16'b0;
                
                s_ip_hdr_ready_n = !m_eth_hdr_valid_n;
                
                if(s_ip_hdr_valid && s_ip_hdr_ready) begin
                
                    s_ip_hdr_ready_n           = 1'b0;
                    str_ip_hdr                 = 1'b1;
                    m_eth_hdr_valid_n          = 1'b1;
                    
                    if(m_eth_axi_payload_tready_internal) begin
                        
                        //Send the First byte of the IP header (IP version and IHP)
                        m_eth_axi_payload_tvalid_internal = 1'b1;
                        m_eth_axi_payload_tdata_internal  = {4'h4, 4'h5};  
                        hdr_ptr_n = 6'h1; 
                    
                    end
                    
                    next_state = HEADER_WR;
                
                end
                else begin
                
                    next_state = IDLE;
                
                end
            
            end//IDLE
            
            HEADER_WR: begin
                            
                //The number of bytes equal to the Length field in the IP header minus the length of the header
                byte_count_n = ip_len_r - 16'h14;
                
                if(m_eth_axi_payload_tready_internal) begin
                
                    hdr_ptr_n  = hdr_ptr_r + 1;
                    next_state = HEADER_WR;
                    
                    m_eth_axi_payload_tvalid_internal = 1'b1;
                    
                    case(hdr_ptr_r) 
                    
                        6'h0: begin
                        
                            m_eth_axi_payload_tdata_internal  = {4'h4, 4'h5};
                        
                        end
                        
                        6'h1: begin
                        
                            m_eth_axi_payload_tdata_internal  = {ip_dscp_r, ip_ecn_r};
                            hdr_sum_n = {4'h4, 4'h5, ip_dscp_r, ip_ecn_r};
                        
                        end
                        
                        6'h2: begin
                        
                            m_eth_axi_payload_tdata_internal  = ip_len_r[15:8];
                            hdr_sum_n = sum1c(hdr_sum_r, ip_len_r);
                        
                        end
                        
                        6'h3: begin
                        
                            m_eth_axi_payload_tdata_internal  = ip_len_r[7:0];
                            hdr_sum_n = sum1c(hdr_sum_r, ip_iden_r);
                        
                        end
                        
                        6'h4: begin
                        
                            m_eth_axi_payload_tdata_internal  = ip_iden_r[15:8];
                            hdr_sum_n = sum1c(hdr_sum_r, {ip_flags_r, ip_frag_off_r});
                        
                        end        
                        
                        6'h5: begin
                        
                            m_eth_axi_payload_tdata_internal  = ip_iden_r[7:0];
                            hdr_sum_n = sum1c(hdr_sum_r, {ip_ttl_r, ip_protocol_r});
                        
                        end   
                        
                        6'h6: begin
                        
                            m_eth_axi_payload_tdata_internal  = {ip_flags_r, ip_frag_off_r[12:8]};
                            hdr_sum_n = sum1c(hdr_sum_r, {ip_ttl_r, ip_src_ip_r[31:16]});
                        
                        end   
                        
                        6'h7: begin
                        
                            m_eth_axi_payload_tdata_internal  = ip_frag_off_r[7:0];
                            hdr_sum_n = sum1c(hdr_sum_r, {ip_ttl_r, ip_src_ip_r[15:0]});
                        
                        end 
                        
                        6'h8: begin
                        
                            m_eth_axi_payload_tdata_internal  = ip_ttl_r;
                            hdr_sum_n = sum1c(hdr_sum_r, {ip_ttl_r, ip_dest_ip_r[31:16]});
                        
                        end  
                        
                        6'h9: begin
                        
                            m_eth_axi_payload_tdata_internal  = ip_protocol_r;
                            hdr_sum_n = sum1c(hdr_sum_r, {ip_ttl_r, ip_dest_ip_r[15:0]});
                        
                        end
                        
                        6'ha : m_eth_axi_payload_tdata_internal = ~hdr_sum_n[15:8];
                        6'hb : m_eth_axi_payload_tdata_internal = ~hdr_sum_n[7 :0]; 
                        6'hc : m_eth_axi_payload_tdata_internal = ip_src_ip_r[31:24];
                        6'hd : m_eth_axi_payload_tdata_internal = ip_src_ip_r[23:16];
                        6'he : m_eth_axi_payload_tdata_internal = ip_src_ip_r[15:8];   
                        6'hf : m_eth_axi_payload_tdata_internal = ip_src_ip_r[7 :0];  
                        6'h10: m_eth_axi_payload_tdata_internal = ip_dest_ip_r[31:24];
                        6'h11: m_eth_axi_payload_tdata_internal = ip_dest_ip_r[23:16];
                        6'h12: m_eth_axi_payload_tdata_internal = ip_dest_ip_r[15:8];   
                        6'h13: begin
                         
                            m_eth_axi_payload_tdata_internal = ip_dest_ip_r[7:0];   
                            s_ip_axi_payload_tready_n        = m_eth_axi_payload_tready_internal_e;
                            next_state                       = PAYLOAD_WR;
                                             
                        end
                        
                    endcase
                
                end else begin
                
                    next_state = HEADER_WR;
                
                end

            end//HEADER_WR
            
            PAYLOAD_WR: begin
                
                s_ip_axi_payload_tready_n = m_eth_axi_payload_tready_internal_e;
            
                m_eth_axi_payload_tdata_internal = s_ip_axi_payload_tdata;
                m_eth_axi_payload_tlast_internal = s_ip_axi_payload_tlast;
                m_eth_axi_payload_tuser_internal = s_ip_axi_payload_tuser;
                
                if(s_ip_axi_payload_tvalid && s_ip_axi_payload_tready) begin
                
                    byte_count_n                      = byte_count_r - 1; 
                    m_eth_axi_payload_tvalid_internal = 1'b1;
                    
                    if(s_ip_axi_payload_tlast) begin
                    
                        if(byte_count_r != 1) begin
                            
                            //The length dosnot match the Length field in the header
                            m_eth_axi_payload_tuser_internal = 1'b1;
                            err_payload_early_termination_n = 1'b1;
                        
                        end
                        
                        s_ip_hdr_ready_n           = !m_eth_hdr_valid_n;
                        s_ip_axi_payload_tready_n  = 1'b0;
                        next_state                 = IDLE;
                    
                    end else begin
                    
                        if(byte_count_r == 1) begin
                    
                            str_last_byte                     = 1'b1;
                            m_eth_axi_payload_tvalid_internal = 1'b0;
                            next_state                        = PAYLOAD_LAST;
                        
                        end else begin
                            
                            next_state = PAYLOAD_WR;
                        
                        end
                    
                    end
                
                end else begin
                
                    next_state = PAYLOAD_WR;
                
                end
                
            end//PAYLOAD_WR
            
            PAYLOAD_LAST: begin
            
                s_ip_axi_payload_tready_n = m_eth_axi_payload_tready_internal_e;
                
                m_eth_axi_payload_tdata_internal = last_data_byte_r;
                m_eth_axi_payload_tlast_internal = s_ip_axi_payload_tlast;
                m_eth_axi_payload_tuser_internal = s_ip_axi_payload_tuser;
                
                if(s_ip_axi_payload_tvalid && s_ip_axi_payload_tready) begin
                
                    if(s_ip_axi_payload_tlast) begin
                    
                        s_ip_hdr_ready_n                  = !m_eth_hdr_valid_n;
                        s_ip_axi_payload_tready_n         = 1'b0;
                        m_eth_axi_payload_tvalid_internal = 1'b0;
                        next_state                        = IDLE;
                    
                    end else begin
                    
                        next_state = PAYLOAD_LAST;
                    
                    end

                end else begin
                
                    next_state = PAYLOAD_LAST;
                
                end
            
            end//PAYLOAD_LAST
        
        endcase
    
    end
    
    
    always@(posedge clk) begin
        
        if(reset) begin
        
            current_state                    <= IDLE;
            s_ip_hdr_ready_r                 <= 1'b0;
            s_ip_axi_payload_tready_r        <= 1'b0;
            m_eth_hdr_valid_r                <= 1'b0;
            busy_r                           <= 1'b0;
            err_payload_early_termination_r  <= 1'b0;
        
        end else begin
        
            current_state                    <= next_state;
            s_ip_hdr_ready_r                 <= s_ip_hdr_ready_n;
            s_ip_axi_payload_tready_r        <= s_ip_axi_payload_tready_n;
            m_eth_hdr_valid_r                <= m_eth_hdr_valid_n;
            busy_r                           <= next_state != IDLE;
            err_payload_early_termination_r  <= err_payload_early_termination_n;
        
        end
        
        hdr_ptr_r     <= hdr_ptr_n;
        byte_count_r  <= byte_count_n;
        hdr_sum_r     <= hdr_sum_n;
        
        //Datapath signals update
        if(str_ip_hdr) begin
        
            m_eth_dest_mac_r  <= s_eth_dest_mac;
            m_eth_src_mac_r   <= s_eth_src_mac;
            m_eth_type_r      <= s_eth_type;
            ip_dscp_r         <= s_ip_dscp;
            ip_ecn_r          <= s_ip_ecn;
            ip_len_r          <= s_ip_len;       
            ip_iden_r         <= s_ip_iden;
            ip_flags_r        <= s_ip_flags;
            ip_frag_off_r     <= s_ip_frag_off;
            ip_ttl_r          <= s_ip_ttl; 
            ip_protocol_r     <= s_ip_protocol;
            ip_src_ip_r       <= s_ip_src_ip;
            ip_dest_ip_r      <= s_ip_dest_ip;
        
        end
        
        if(str_last_byte) begin
        
            last_data_byte_r <= m_eth_axi_payload_tdata_internal;
        
        end
        
    
    end
    
    logic [7 : 0] m_eth_axi_payload_tdata_r;
    logic         m_eth_axi_payload_tvalid_r, m_eth_axi_payload_tvalid_n;
    logic         m_eth_axi_payload_tlast_r;
    logic         m_eth_axi_payload_tuser_r;
    
    logic [7 : 0] m_eth_axi_payload_tdata_temp;
    logic         m_eth_axi_payload_tvalid_temp, m_eth_axi_payload_tvalid_temp_n;
    logic         m_eth_axi_payload_tlast_temp;
    logic         m_eth_axi_payload_tuser_temp;
    
    //Datapath control signals
    logic str_eth_payload_internal_to_out;
    logic str_eth_payload_internal_to_temp;
    logic str_eth_payload_temp_to_out;
    
    assign m_eth_axi_payload_tdata  = m_eth_axi_payload_tdata_r;
    assign m_eth_axi_payload_tvalid = m_eth_axi_payload_tvalid_r;
    assign m_eth_axi_payload_tlast  = m_eth_axi_payload_tlast_r;
    assign m_eth_axi_payload_tuser  = m_eth_axi_payload_tuser_r;

    assign m_eth_axi_payload_tready_internal_e = m_eth_axi_payload_tready || (!m_eth_axi_payload_tvalid_temp && !m_eth_axi_payload_tvalid_r);


    always_comb begin
    
        m_eth_axi_payload_tvalid_n      = m_eth_axi_payload_tvalid_r;
        m_eth_axi_payload_tvalid_temp_n = m_eth_axi_payload_tvalid_temp;
        
        str_eth_payload_internal_to_out  = 1'b0;
        str_eth_payload_internal_to_temp = 1'b0;
        str_eth_payload_temp_to_out      = 1'b0;
        
        if(m_eth_axi_payload_tready_internal) begin
        
            //there is ready input
            if(m_eth_axi_payload_tready || !m_eth_axi_payload_tvalid_r) begin
            
                //The output is ready or,
                //it still currently not valid
                m_eth_axi_payload_tvalid_n      = m_eth_axi_payload_tvalid_internal;
                str_eth_payload_internal_to_out = 1'b1;
            
            end else begin
                
                //output is not ready
                //store it in temp registers
                m_eth_axi_payload_tvalid_temp_n   = m_eth_axi_payload_tvalid_internal;
                str_eth_payload_internal_to_temp  = 1'b1;
            
            end
        
        end else if(m_eth_axi_payload_tready) begin
        
            //input is not ready but output is
            m_eth_axi_payload_tvalid_n      = m_eth_axi_payload_tvalid_temp;
            m_eth_axi_payload_tvalid_temp_n = 1'b0;
            str_eth_payload_temp_to_out     = 1'b1;
        
        end
    
    end
    
    always@(posedge clk) begin
    
        m_eth_axi_payload_tvalid_r        <= m_eth_axi_payload_tvalid_n;
        m_eth_axi_payload_tvalid_temp     <= m_eth_axi_payload_tvalid_temp_n;
        m_eth_axi_payload_tready_internal <= m_eth_axi_payload_tready_internal_e;
        
        if(str_eth_payload_internal_to_out) begin
        
            m_eth_axi_payload_tdata_r <= m_eth_axi_payload_tdata_internal;
            m_eth_axi_payload_tlast_r <= m_eth_axi_payload_tlast_internal;
            m_eth_axi_payload_tuser_r <= m_eth_axi_payload_tuser_internal;
        
        end else if(str_eth_payload_temp_to_out) begin
        
            m_eth_axi_payload_tdata_r <= m_eth_axi_payload_tdata_temp;
            m_eth_axi_payload_tlast_r <= m_eth_axi_payload_tlast_temp;
            m_eth_axi_payload_tuser_r <= m_eth_axi_payload_tuser_temp;
    
        
        end
        
        if(str_eth_payload_internal_to_temp) begin
        
            m_eth_axi_payload_tdata_temp <= m_eth_axi_payload_tdata_internal;
            m_eth_axi_payload_tlast_temp <= m_eth_axi_payload_tlast_internal;
            m_eth_axi_payload_tuser_temp <= m_eth_axi_payload_tuser_internal;
        
        end
        
        if(reset) begin
        
            m_eth_axi_payload_tvalid_r        <= 1'b0;
            m_eth_axi_payload_tvalid_temp     <= 1'b0;
            m_eth_axi_payload_tready_internal <= 1'b0;
        
        end
    
    end

endmodule
