`timescale 1ns / 1ps


interface arp_if#(parameter DATAW = 8, parameter TDATAW = DATAW/8)();

    logic clk;
    logic reset;
    
    logic [47 : 0]       local_mac;
    logic [31 : 0]       local_ip;
    logic [31 : 0]       gateway_ip;
    logic [31 : 0]       subnet_mask;
    logic                clear_cache;
    
    logic                s_eth_hdr_valid;
    logic [15 : 0]       s_eth_type;
    logic [47 : 0]       s_eth_dest_mac;
    logic [47 : 0]       s_eth_src_mac;
    logic [DATAW-1 : 0]  s_eth_axi_payload_tdata;
    logic [TDATAW-1 : 0] s_eth_axi_payload_tkeep;
    logic                s_eth_axi_payload_tvalid;
    logic                s_eth_axi_payload_tlast;  
    logic                s_eth_axi_payload_tuser;   
    logic                s_eth_hdr_ready;
    logic                s_eth_axi_payload_tready;
    
    logic                m_eth_hdr_valid;
    logic [15 : 0]       m_eth_type;
    logic [47 : 0]       m_eth_dest_mac;
    logic [47 : 0]       m_eth_src_mac;
    logic [DATAW-1 : 0]  m_eth_axi_payload_tdata;
    logic [TDATAW-1 : 0] m_eth_axi_payload_tkeep;
    logic                m_eth_axi_payload_tvalid;
    logic                m_eth_axi_payload_tlast;  
    logic                m_eth_axi_payload_tuser;   
    logic                m_eth_hdr_ready;
    logic                m_eth_axi_payload_tready;
    
    logic                arp_req_valid;
    logic [31 : 0]       arp_req_ip;
    logic                arp_rsp_ready;
    logic                arp_req_ready;
    logic                arp_rsp_valid;
    logic                arp_rsp_err;
    logic [47 : 0]       arp_rsp_mac;
    
    modport master(
    
        output  clk,
        output  reset,
        
        output  local_mac,
        output  local_ip,
        output  gateway_ip,
        output  subnet_mask,
        output  clear_cache,
        
        output  s_eth_hdr_valid,
        output  s_eth_dest_mac,
        output  s_eth_src_mac,
        output  s_eth_type,
        output  s_eth_axi_payload_tdata,
        output  s_eth_axi_payload_tkeep,
        output  s_eth_axi_payload_tvalid,
        output  s_eth_axi_payload_tlast,   
        output  s_eth_axi_payload_tuser,   
        input   s_eth_hdr_ready,
        input   s_eth_axi_payload_tready,
        
        output m_eth_hdr_ready,
        output m_eth_axi_payload_tready,
        input  m_eth_hdr_valid,
        input  m_eth_dest_mac,
        input  m_eth_src_mac,
        input  m_eth_type,
        input  m_eth_axi_payload_tdata,
        input  m_eth_axi_payload_tkeep,
        input  m_eth_axi_payload_tvalid,
        input  m_eth_axi_payload_tlast,   
        input  m_eth_axi_payload_tuser,
        
        output arp_req_valid,
        output arp_req_ip,
        output arp_rsp_ready,
        input  arp_req_ready,
        input  arp_rsp_valid,
        input  arp_rsp_err,
        input  arp_rsp_mac
    
    );
    

endinterface

program arp_driver(arp_if aif);

    initial begin
        
        aif.clear_cache   = 1'b0;
        aif.arp_req_valid = 1'b0;
        aif.arp_req_ip    = 0;
        aif.arp_rsp_ready = 1'b1;
        
        aif.m_eth_hdr_ready          = 1'b1;
        aif.m_eth_axi_payload_tready = 1'b1;
        
        aif.reset = 1'b0;
        @(posedge aif.clk);
        aif.reset = 1'b1;
        @(posedge aif.clk);
        aif.reset = 1'b0;
                
        @(posedge aif.clk);
        wait(aif.s_eth_hdr_ready);
        aif.local_mac   = 48'hDAD1D2D3D4D5;
        aif.local_ip    = 32'hC0A80165;
        aif.gateway_ip  = 32'hC0A80101;
        aif.subnet_mask = 32'hFFFFFF00;
        
        aif.s_eth_hdr_valid = 1'b1;
        aif.s_eth_type      = 16'h0806;
        aif.s_eth_dest_mac  = 48'hffffffffffff;
        aif.s_eth_src_mac   = 48'h5A5152535455;
        
        @(posedge aif.clk);
        wait(aif.s_eth_axi_payload_tready);
        aif.s_eth_hdr_valid          = 1'b0;
        aif.s_eth_axi_payload_tvalid = 1'b1;
        aif.s_eth_axi_payload_tuser  = 1'b0;
        aif.s_eth_axi_payload_tdata  = 0;
        aif.s_eth_axi_payload_tkeep  = 1'b1;
        aif.s_eth_axi_payload_tlast  = 1'b0;
        
        @(posedge aif.clk);
        //HTYPE
        aif.s_eth_axi_payload_tdata  = 1;
        aif.s_eth_axi_payload_tuser  = 1'b0;
        
        @(posedge aif.clk);
        //PTYPR
        aif.s_eth_axi_payload_tdata  = 8'h08;
        
        @(posedge aif.clk);
        //PTYPR
        aif.s_eth_axi_payload_tdata  = 0;
        
        @(posedge aif.clk);
        //HLEN
        aif.s_eth_axi_payload_tdata  = 8'h06;
        
        @(posedge aif.clk);
        //PLEN
        aif.s_eth_axi_payload_tdata  = 8'h04;
        
        @(posedge aif.clk);
        //OPER
        aif.s_eth_axi_payload_tdata  = 8'h00;
        
        @(posedge aif.clk);
        //OPER
        aif.s_eth_axi_payload_tdata  = 8'h01;
        
        @(posedge aif.clk);
        //SHA
        aif.s_eth_axi_payload_tdata  = 8'h5A;
        
        @(posedge aif.clk);
        //SHA
        aif.s_eth_axi_payload_tdata  = 8'h51;
        
        @(posedge aif.clk);
        //SHA
        aif.s_eth_axi_payload_tdata  = 8'h52;
        
        @(posedge aif.clk);
        //SHA
        aif.s_eth_axi_payload_tdata  = 8'h53;
        
        @(posedge aif.clk);
        //SHA
        aif.s_eth_axi_payload_tdata  = 8'h54;
        
        @(posedge aif.clk);
        //SHA
        aif.s_eth_axi_payload_tdata  = 8'h55;
        
        @(posedge aif.clk);
        //SPA
        aif.s_eth_axi_payload_tdata  = 8'hC0;
        
        @(posedge aif.clk);
        //SPA
        aif.s_eth_axi_payload_tdata  = 8'hA8;
        
        @(posedge aif.clk);
        //SPA
        aif.s_eth_axi_payload_tdata  = 8'h01;
        
        @(posedge aif.clk);
        //SPA
        aif.s_eth_axi_payload_tdata  = 8'h64;
        
        @(posedge aif.clk);
        //THA
        aif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge aif.clk);
        //THA
        aif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge aif.clk);
        //THA
        aif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge aif.clk);
        //THA
        aif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge aif.clk);
        //THA
        aif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge aif.clk);
        //THA
        aif.s_eth_axi_payload_tdata  = 8'hff;
        
        @(posedge aif.clk);
        //TPA
        aif.s_eth_axi_payload_tdata  = 8'hC0;
        
        @(posedge aif.clk);
        //TPA
        aif.s_eth_axi_payload_tdata  = 8'hA8;
        
        @(posedge aif.clk);
        //TPA
        aif.s_eth_axi_payload_tdata  = 8'h01;
        
        @(posedge aif.clk);
        //TPA
        aif.s_eth_axi_payload_tdata  = 8'h65;
        aif.s_eth_axi_payload_tlast  = 1'b1;
        
        @(posedge aif.clk);
        aif.s_eth_axi_payload_tvalid = 1'b0;
        aif.s_eth_axi_payload_tlast  = 1'b0;
        
        wait(aif.m_eth_axi_payload_tlast);
        //#300;
        @(posedge aif.clk);
        wait(aif.arp_req_ready);
        $display("ARP Frame Request Start");
        aif.arp_req_valid = 1'b1;
        aif.arp_req_ip    = 32'hC0A80164;
        
        @(posedge aif.clk);
        aif.arp_req_valid = 1'b0;
        wait(aif.arp_rsp_valid);
        $display("ARP MAC : %0h", aif.arp_rsp_mac);
        
        //Uncached ip
        @(posedge aif.clk);
        wait(aif.arp_req_ready);
        aif.arp_req_valid = 1'b1;
        aif.arp_req_ip    = 32'hC0A80167;
        
        @(posedge aif.clk);
        aif.arp_req_valid = 1'b0;
        wait(aif.arp_rsp_valid);
        assert(aif.arp_rsp_err == 1'b1)$display("test passed");
        else $error("fest failed");        
        $finish;
        
    end

endprogram

program arp_monitor(arp_if aif);

    initial begin
    
        forever begin
        
            @(posedge aif.clk);
            if(aif.m_eth_hdr_valid == 1'b1)
            begin
            
                $display("Destination MAC: %0h", aif.m_eth_dest_mac);
                $display("Source MAC: %0h", aif.m_eth_src_mac);
                $display("ETH Type: %0h", aif.m_eth_type);
            
            end
            
            if(aif.m_eth_axi_payload_tvalid)
            begin
                
                $display("Data : %0h", aif.m_eth_axi_payload_tdata);
                $display("Valid Bytes : %0h", aif.m_eth_axi_payload_tvalid);
            
            end
            
            /*if(aif.arp_rsp_valid)
            begin
                
                $display("ARP MAC : %0h", aif.arp_rsp_mac);
            
            end*/
        
        end
    
    end

endprogram

module arb_tb();

    arp_if aif();
    
    arp_driver  drv (aif);
    arp_monitor mon (aif);
    
    initial aif.clk = 0;
    always #5 aif.clk <= ~aif.clk;
    
    ARP#(
    
        //AXI-Stream Data Width
        .DATAW(8),
        .REQ_RET_INT(5),
        .REQ_TIMEOUT(5)
        
    )arp_inst(
    
        .clk(aif.clk),
        .reset(aif.reset),
        
        /*
        *   The Network configuration
        */
        .local_mac(aif.local_mac),
        .local_ip(aif.local_ip),
        .gateway_ip(aif.gateway_ip),
        .subnet_mask(aif.subnet_mask),
        .clear_cache(aif.clear_cache),
        
        /*
        *   The Ethernet frame input 
        */
        .s_eth_hdr_valid(aif.s_eth_hdr_valid),
        .s_eth_dest_mac(aif.s_eth_dest_mac),
        .s_eth_src_mac(aif.s_eth_src_mac),
        .s_eth_type(aif.s_eth_type),
        .s_eth_axi_payload_tdata(aif.s_eth_axi_payload_tdata),
        .s_eth_axi_payload_tkeep(aif.s_eth_axi_payload_tkeep),
        .s_eth_axi_payload_tvalid(aif.s_eth_axi_payload_tvalid),
        .s_eth_axi_payload_tlast(aif.s_eth_axi_payload_tlast),   
        .s_eth_axi_payload_tuser(aif.s_eth_axi_payload_tuser),   
        .s_eth_hdr_ready(aif.s_eth_hdr_ready),
        .s_eth_axi_payload_tready(aif.s_eth_axi_payload_tready),
        
        /*
        *   The Ethernet frame output
        */
        .m_eth_hdr_ready(aif.m_eth_hdr_ready),
        .m_eth_axi_payload_tready(aif.m_eth_axi_payload_tready),
        .m_eth_hdr_valid(aif.m_eth_hdr_valid),
        .m_eth_dest_mac(aif.m_eth_dest_mac),
        .m_eth_src_mac(aif.m_eth_src_mac),
        .m_eth_type(aif.m_eth_type),
        .m_eth_axi_payload_tdata(aif.m_eth_axi_payload_tdata),
        .m_eth_axi_payload_tkeep(aif.m_eth_axi_payload_tkeep),
        .m_eth_axi_payload_tvalid(aif.m_eth_axi_payload_tvalid),
        .m_eth_axi_payload_tlast(aif.m_eth_axi_payload_tlast),   
        .m_eth_axi_payload_tuser(aif.m_eth_axi_payload_tuser),   
        
        /*
        *   The ARP request 
        */
        .arp_req_valid(aif.arp_req_valid),
        .arp_req_ip(aif.arp_req_ip),
        .arp_rsp_ready(aif.arp_rsp_ready),
        .arp_req_ready(aif.arp_req_ready),
        .arp_rsp_valid(aif.arp_rsp_valid),
        .arp_rsp_err(aif.arp_rsp_err),
        .arp_rsp_mac(aif.arp_rsp_mac)
        
    );

endmodule
