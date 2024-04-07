`timescale 1ns / 1ps


module eth_arb_mux#(

    parameter NUM_REQS   = 2,
    parameter DATAW      = 8,
    parameter KEEP_EN    = (DATAW > 8),
    parameter TDATAW     = DATAW/8,
    parameter ID_EN      = 0,
    parameter ID_WIDTH   = 8,
    parameter DEST_EN    = 0,
    parameter DEST_WIDTH = 8,
    parameter USER_EN    = 1,
    parameter USER_WIDTH = 1,
    parameter ARB_TYPE   = "P"

)(

    input  logic clk,
    input  logic reset,
    

    /*
    *   Ethernet frame input
    */
    
    input  logic [NUM_REQS-1 : 0]             s_eth_hdr_valid,
    input  logic [(NUM_REQS*48)-1 : 0]        s_eth_dest_mac,
    input  logic [(NUM_REQS*48)-1 : 0]        s_eth_src_mac,
    input  logic [(NUM_REQS*16)-1 : 0]        s_eth_type,    
    input  logic [NUM_REQS*DATAW-1  : 0]      s_eth_axi_payload_tdata,
    input  logic [NUM_REQS*TDATAW-1 : 0]      s_eth_axi_payload_tkeep,
    input  logic [NUM_REQS-1 : 0]             s_eth_axi_payload_tvalid,
    input  logic [NUM_REQS-1 : 0]             s_eth_axi_payload_tlast,   
    input  logic [NUM_REQS*USER_WIDTH-1 : 0]  s_eth_axi_payload_tuser,   
    input  logic [NUM_REQS*ID_WIDTH-1 : 0]    s_eth_axi_payload_tid,
    input  logic [NUM_REQS*DEST_WIDTH-1 : 0]  s_eth_axi_payload_tdest,
    output logic [NUM_REQS-1 : 0]             s_eth_hdr_ready,
    output logic [NUM_REQS-1 : 0]             s_eth_axi_payload_tready,
    

    /*
    *   Ethernet frame output
    */
    input  logic                              m_eth_hdr_ready,
    input  logic                              m_eth_axi_payload_tready,
    output logic                              m_eth_hdr_valid,
    output logic [47 : 0]                     m_eth_dest_mac,
    output logic [47 : 0]                     m_eth_src_mac,
    output logic [15 : 0]                     m_eth_type,    
    output logic [DATAW-1  : 0]               m_eth_axi_payload_tdata,
    output logic                              m_eth_axi_payload_tvalid,
    output logic                              m_eth_axi_payload_tlast,
    output logic [TDATAW-1 : 0]               m_eth_axi_payload_tkeep,
    output logic [USER_WIDTH-1 : 0]           m_eth_axi_payload_tuser,   
    output logic [ID_WIDTH-1 : 0]             m_eth_axi_payload_tid,
    output logic [DEST_WIDTH-1 : 0]           m_eth_axi_payload_tdest

);
    
    localparam INDEXW = $clog2(NUM_REQS);
    
    logic frame_r, frame_n;
    
    logic [NUM_REQS-1 : 0] s_eth_hdr_ready_r, s_eth_hdr_ready_n;
    
    logic                     m_eth_hdr_valid_r, m_eth_hdr_valid_n;
    logic [47 : 0]            m_eth_dest_mac_r, m_eth_dest_mac_n;
    logic [47 : 0]            m_eth_src_mac_r, m_eth_src_mac_n;
    logic [15 : 0]            m_eth_type_r, m_eth_type_n; 
    
    logic [NUM_REQS-1 : 0] valid_req;
    logic [NUM_REQS-1 : 0] acknowledge;
    logic [NUM_REQS-1 : 0]  grant;
    logic                   valid;
    logic [INDEXW-1 : 0]    grant_index;
    
    //Internal datapath
    logic [DATAW-1  : 0]      m_eth_axi_payload_tdata_internal;
    logic                     m_eth_axi_payload_tvalid_internal;
    logic                     m_eth_axi_payload_tlast_internal;
    logic [TDATAW-1 : 0]      m_eth_axi_payload_tkeep_internal;
    logic [USER_WIDTH-1 : 0]  m_eth_axi_payload_tuser_internal;   
    logic [ID_WIDTH-1 : 0]    m_eth_axi_payload_tid_internal;
    logic [DEST_WIDTH-1 : 0]  m_eth_axi_payload_tdest_internal;
    logic                     m_eth_axi_payload_tready_internal;
    logic                     m_eth_axi_payload_tready_e;
    
    assign s_eth_hdr_ready = s_eth_hdr_ready_r;
    
    assign s_eth_axi_payload_tready = (m_eth_axi_payload_tready_internal && valid) << grant_index;
    
    assign m_eth_hdr_valid = m_eth_hdr_valid_r;
    assign m_eth_dest_mac  = m_eth_dest_mac_r;
    assign m_eth_src_mac   = m_eth_src_mac_r;
    assign m_eth_type      = m_eth_type_r;
    
    //Select incoming packets
	logic                     selected_tvalid;
	logic                     selected_tready;
    logic [DATAW-1 : 0]       selected_tdata;
    logic [TDATAW-1 : 0]      selected_tkeep;  
    logic [USER_WIDTH-1 : 0]  selected_tuser;   
    logic [ID_WIDTH-1 : 0]    selected_tid;
    logic [DEST_WIDTH-1 : 0]  selected_tdest;
    logic                     selected_tlast;
    
	assign selected_tvalid  = s_eth_axi_payload_tvalid[grant_index];
    assign selected_tready  = s_eth_axi_payload_tready[grant_index];
    assign selected_tdata   = s_eth_axi_payload_tdata[grant_index*DATAW +: DATAW];
    assign selected_tkeep   = s_eth_axi_payload_tkeep[grant_index*TDATAW +: TDATAW];  
    assign selected_tuser   = s_eth_axi_payload_tuser[grant_index*USER_WIDTH +: USER_WIDTH];   
    assign selected_tid     = s_eth_axi_payload_tid[grant_index*ID_WIDTH +: ID_WIDTH];
    assign selected_tdest   = s_eth_axi_payload_tdest[grant_index*DEST_WIDTH +: DEST_WIDTH];
    assign selected_tlast   = s_eth_axi_payload_tlast[grant_index];
    
    eth_stream_arbiter#(
    
        .NUM_REQS(2),
        .ARB_TYPE(ARB_TYPE),
        .ARB_BLOCK(1),
        .ARB_BLOCK_ACK(1)
    
    ) arbiter (
    
        .clk(clk),
        .reset(reset),
        
        .valid_req(valid_req),
        .acknowledge(acknowledge),
        
        .grant(grant),
        .valid(valid),
        .grant_index(grant_index)
    
    );
    
    assign valid_req   = s_eth_hdr_valid & ~grant;
    assign acknowledge = grant & s_eth_axi_payload_tvalid & s_eth_axi_payload_tready & s_eth_axi_payload_tlast;
    
    
    always_comb begin
    
        frame_n = frame_r;
        
        s_eth_hdr_ready_n = 0;
        m_eth_hdr_valid_n = m_eth_hdr_valid_r && !m_eth_hdr_ready;
        m_eth_dest_mac_n  = m_eth_dest_mac_r;
        m_eth_src_mac_n   = m_eth_src_mac_r;
        m_eth_type_n      = m_eth_type_r;
        
        if(s_eth_axi_payload_tvalid[grant_index] && s_eth_axi_payload_tready[grant_index]) begin
        
            if(s_eth_axi_payload_tlast[grant_index])
                frame_n = 1'b0;
        
        end
        
        if (!frame_r && valid && (m_eth_hdr_ready || !m_eth_hdr_valid)) begin
        
            frame_n = 1'b1;
            
            s_eth_hdr_ready_n = grant;
            m_eth_hdr_valid_n = 1'b1;
            m_eth_dest_mac_n  = s_eth_dest_mac[grant_index*48 +: 48];
            m_eth_src_mac_n   = s_eth_src_mac[grant_index*48 +: 48];
            m_eth_type_n      = s_eth_type[grant_index*16 +: 16];
        
        end
        

        
        //output the selected data
        m_eth_axi_payload_tdata_internal  = selected_tdata;
        m_eth_axi_payload_tkeep_internal  = selected_tkeep;
        m_eth_axi_payload_tvalid_internal = selected_tvalid && m_eth_axi_payload_tready_internal && valid;
        m_eth_axi_payload_tlast_internal  = selected_tlast;
        m_eth_axi_payload_tid_internal    = selected_tid;
        m_eth_axi_payload_tdest_internal  = selected_tdest;
        m_eth_axi_payload_tuser_internal  = selected_tuser;

    
    end
    
    always @(posedge clk) begin
        
            frame_r <= frame_n;
        
            s_eth_hdr_ready_r <= s_eth_hdr_ready_n;
        
            m_eth_hdr_valid_r <= m_eth_hdr_valid_n;
            m_eth_dest_mac_r  <= m_eth_dest_mac_n;
            m_eth_src_mac_r   <= m_eth_src_mac_n;
            m_eth_type_r      <= m_eth_type_n;
        
            if (reset) begin
            
                frame_r <= 1'b0;
                s_eth_hdr_ready_r <= 0;
                m_eth_hdr_valid_r <= 0;
                
            end
            
    end
    
    logic [DATAW-1  : 0]      m_eth_axi_payload_tdata_r;
    logic                     m_eth_axi_payload_tvalid_r, m_eth_axi_payload_tvalid_n;
    logic                     m_eth_axi_payload_tlast_r;
    logic [TDATAW-1 : 0]      m_eth_axi_payload_tkeep_r;
    logic [USER_WIDTH-1 : 0]  m_eth_axi_payload_tuser_r;   
    logic [ID_WIDTH-1 : 0]    m_eth_axi_payload_tid_r;
    logic [DEST_WIDTH-1 : 0]  m_eth_axi_payload_tdest_r;
    
    logic [DATAW-1  : 0]      m_eth_axi_payload_tdata_temp;
    logic                     m_eth_axi_payload_tvalid_temp_r, m_eth_axi_payload_tvalid_temp_n;
    logic                     m_eth_axi_payload_tlast_temp;
    logic [TDATAW-1 : 0]      m_eth_axi_payload_tkeep_temp;
    logic [USER_WIDTH-1 : 0]  m_eth_axi_payload_tuser_temp;   
    logic [ID_WIDTH-1 : 0]    m_eth_axi_payload_tid_temp;
    logic [DEST_WIDTH-1 : 0]  m_eth_axi_payload_tdest_temp;
    
    //Datapath control signals
    logic str_axi_internal_to_out;
    logic str_axi_internal_to_temp;
    logic str_axi_temp_to_out;
    
    assign m_eth_axi_payload_tdata  = m_eth_axi_payload_tdata_r;
    assign m_eth_axi_payload_tvalid = m_eth_axi_payload_tvalid_r;
    assign m_eth_axi_payload_tlast  = m_eth_axi_payload_tlast_r;
    assign m_eth_axi_payload_tkeep  = KEEP_EN ? m_eth_axi_payload_tkeep_r : 0;
    assign m_eth_axi_payload_tuser  = USER_EN ? m_eth_axi_payload_tuser_r : 0;
    assign m_eth_axi_payload_tid    = ID_EN   ? m_eth_axi_payload_tid_r   : 0;
    assign m_eth_axi_payload_tdest  = DEST_EN ? m_eth_axi_payload_tdest_r : 0;
    
    assign m_eth_axi_payload_tready_e = m_eth_hdr_ready || (!m_eth_axi_payload_tvalid_temp_r && !m_eth_axi_payload_tvalid_r);
    
    
    always_comb begin
        
            m_eth_axi_payload_tvalid_n      = m_eth_axi_payload_tvalid_r;
            m_eth_axi_payload_tvalid_temp_n = m_eth_axi_payload_tvalid_temp_r;
        
            str_axi_internal_to_out  = 1'b0;
            str_axi_internal_to_temp = 1'b0;
            str_axi_temp_to_out      = 1'b0;
        
            if (m_eth_axi_payload_tready_internal) begin
            
                if (m_eth_axi_payload_tready || !m_eth_axi_payload_tvalid_r) begin
                
                    m_eth_axi_payload_tvalid_n  = m_eth_axi_payload_tvalid_internal;
                    str_axi_internal_to_out     = 1'b1;
                    
                end else begin
                
                    m_eth_axi_payload_tvalid_temp_n = m_eth_axi_payload_tvalid_internal;
                    str_axi_internal_to_temp        = 1'b1;
                    
                end
            end else if (m_eth_axi_payload_tready) begin
            
                m_eth_axi_payload_tvalid_n      = m_eth_axi_payload_tvalid_temp_r;
                m_eth_axi_payload_tvalid_temp_n = 1'b0;
                str_axi_temp_to_out             = 1'b1;
                
            end
               
    end
    
    always@(posedge clk) begin
    
        m_eth_axi_payload_tvalid_r        <= m_eth_axi_payload_tvalid_n;
        m_eth_axi_payload_tready_internal <= m_eth_axi_payload_tready_e;
        m_eth_axi_payload_tvalid_temp_r   <= m_eth_axi_payload_tvalid_temp_n;
        
        if(str_axi_internal_to_out) begin
        
            m_eth_axi_payload_tdata_r <= m_eth_axi_payload_tdata_internal;
            m_eth_axi_payload_tkeep_r <= m_eth_axi_payload_tkeep_internal;
            m_eth_axi_payload_tlast_r <= m_eth_axi_payload_tlast_internal;
            m_eth_axi_payload_tid_r   <= m_eth_axi_payload_tid_internal;
            m_eth_axi_payload_tdest_r <= m_eth_axi_payload_tdest_internal;
            m_eth_axi_payload_tuser_r <= m_eth_axi_payload_tuser_internal;
        
        end else if(str_axi_temp_to_out) begin
        
            m_eth_axi_payload_tdata_r <= m_eth_axi_payload_tdata_temp;
            m_eth_axi_payload_tkeep_r <= m_eth_axi_payload_tkeep_temp;
            m_eth_axi_payload_tlast_r <= m_eth_axi_payload_tlast_temp;
            m_eth_axi_payload_tid_r   <= m_eth_axi_payload_tid_temp;
            m_eth_axi_payload_tdest_r <= m_eth_axi_payload_tdest_temp;
            m_eth_axi_payload_tuser_r <= m_eth_axi_payload_tuser_temp;
        
        end
        
        
        if(str_axi_temp_to_out) begin
        
            m_eth_axi_payload_tdata_temp <= m_eth_axi_payload_tdata_internal;
            m_eth_axi_payload_tkeep_temp <= m_eth_axi_payload_tkeep_internal;
            m_eth_axi_payload_tlast_temp <= m_eth_axi_payload_tlast_internal;
            m_eth_axi_payload_tid_temp   <= m_eth_axi_payload_tid_internal;
            m_eth_axi_payload_tdest_temp <= m_eth_axi_payload_tdest_internal;
            m_eth_axi_payload_tuser_temp <= m_eth_axi_payload_tuser_internal;
        
        end
        
        if(reset) begin
        
            m_eth_axi_payload_tvalid_r        <= 1'b0;
            m_eth_axi_payload_tready_internal <= 1'b0;
            m_eth_axi_payload_tvalid_temp_r   <= 1'b0;
            
        end
        
    
    end
    
endmodule
