`timescale 1ns / 1ps


module arb_cache#(

    parameter CACHE_ADDRW = 4

)(

    input  logic clk,
    input  logic reset,
    input  logic clear_cache,
    
    //Query Request Signals
    input  logic           query_req_valid,
    input  logic [31 : 0]  query_req_ip,
    output logic           query_req_ready,
    
    //Query Response Signals
    input  logic           query_rsp_ready,
    output logic           query_rsp_valid,
    output logic           query_rsp_err,
    output logic [47 : 0]  query_rsp_mac,
    
    //Write Request Signals
    input  logic           write_req_valid,
    input  logic [31 : 0]  write_req_ip,
    input  logic [47 : 0]  write_req_mac,
    output logic           write_req_ready
    
);

    logic mem_write;
    logic store_query;
    logic store_write;
    
    logic query_ip_valid_r, query_ip_valid_n;
    logic write_ip_valid_r, write_ip_valid_n;
    logic clear_cache_r, clear_cache_n;
    
    logic [31 : 0] query_ip_r;
    logic [31 : 0] write_ip_r;
    logic [47 : 0] write_mac_r;
    
    logic [CACHE_ADDRW-1 : 0] wr_ptr_r, wr_ptr_n;
    logic [CACHE_ADDRW-1 : 0] rd_ptr_r, rd_ptr_n;
    
    logic query_req_ready_r, query_req_ready_n; 
    logic query_rsp_valid_r, query_rsp_valid_n; 
    logic query_rsp_err_r, query_rsp_err_n; 
    logic write_req_ready_r, write_req_ready_n;
    logic [47 : 0]  query_rsp_mac_r;
    
    
    logic [31 : 0] query_req_hash;
    logic [31 : 0] write_req_hash;
    
    assign query_req_ready = query_req_ready_r;
    assign query_rsp_valid = query_rsp_valid_r;
    assign query_rsp_err   = query_rsp_err_r;
    assign query_rsp_mac   = query_rsp_mac_r;
    assign write_req_ready = write_req_ready_r;
    
    
    //IP and MAC addresses stores
    logic [32 : 0] rdata_ip;       //read IP address + valid bit
    logic [32 : 0] wdata_ip;       //write IP address + valid bit
    
    logic [47 : 0] rdata_mac;       //read MAC address
    logic [47 : 0] wdata_mac;       //write MAC address
    
    
    eth_dp_ram#(
        
        .DATAW(33),
        .SIZE(2**CACHE_ADDRW),
        .INIT_ENABLE(1)
        
    )IP_store(
        
        .clk(clk),
        .wren(mem_write),
        .raddr(rd_ptr_r),
        .waddr(wr_ptr_r),
        .wdata(wdata_ip),
        .rdata(rdata_ip)
    
    );
    
    
    eth_dp_ram#(
        
        .DATAW(48),
        .SIZE(2**CACHE_ADDRW),
        .INIT_ENABLE(1)
        
    )MAC_store(
        
        .clk(clk),
        .wren(mem_write),
        .raddr(rd_ptr_r),
        .waddr(wr_ptr_r),
        .wdata(wdata_mac),
        .rdata(rdata_mac)
    
    );
    
    assign wdata_ip  = {!clear_cache_r, write_ip_r};
    assign wdata_mac = write_mac_r;
    
    lfsr#(
    
        .POLY_EQU(32'h4c11db7),
        .LSFRW(32),
        .LSFR_Config("G"),
        .LSFR_FEED_FORWARD(0),
        .REVERSE(1),
        .DATAW(32)
    
    )rd_hash(
    
        .data_in(query_req_ip),
        .state_in(32'hffffffff),
        .data_out(),
        .state_out(query_req_hash)
    
    );
    
    lfsr#(
    
        .POLY_EQU(32'h4c11db7),
        .LSFRW(32),
        .LSFR_Config("G"),
        .LSFR_FEED_FORWARD(0),
        .REVERSE(1),
        .DATAW(32)
    
    )wr_hash(
    
        .data_in(write_req_ip),
        .state_in(32'hffffffff),
        .data_out(),
        .state_out(write_req_hash)
    
    );
    
    
    always @(*)  begin
    
        mem_write = 1'b0;
        store_query = 1'b0;
        store_write = 1'b0;
        
        wr_ptr_n = wr_ptr_r;
        rd_ptr_n = rd_ptr_r;
        
        clear_cache_n = clear_cache_r | clear_cache;
        
        query_ip_valid_n  = query_ip_valid_r;
        query_req_ready_n = (~query_ip_valid_r || ~query_req_valid || query_rsp_ready) && !clear_cache;
        query_rsp_valid_n = query_rsp_valid_r & ~query_rsp_ready;
        query_rsp_err_n   = query_rsp_err_r; 
        
        if(query_ip_valid_r && (~query_req_valid || query_rsp_ready)) begin
        
            query_rsp_valid_n = 1;
            query_ip_valid_n  = 0;
            
            if(rdata_ip[32] && rdata_ip[31:0] == query_ip_r) 
                query_rsp_err_n = 0;
            else 
                query_rsp_err_n = 1;
        
        end
        
        if(query_req_valid && query_req_ready && (~query_ip_valid_r || ~query_req_valid || query_rsp_ready)) begin
        
            store_query = 1;
            query_ip_valid_n = 1;
            rd_ptr_n = query_req_hash[CACHE_ADDRW-1 : 0];
        
        end
        
        write_ip_valid_n  = write_ip_valid_r;
        write_req_ready_n = !clear_cache_n;
        
        if(write_ip_valid_r) begin
        
            write_ip_valid_n = 0;
            mem_write        = 1;
        
        end
        
        if(write_req_valid && write_req_ready) begin
        
            store_write      = 1;
            write_ip_valid_n = 1;
            wr_ptr_n         = write_req_hash[CACHE_ADDRW-1 : 0];
        
        end
        
        if(clear_cache) begin
        
            clear_cache_n = 1'b1;
            wr_ptr_n      = 0;
        
        end else if(clear_cache_r) begin
        
            wr_ptr_n      = wr_ptr_r + 1;
            clear_cache_n = wr_ptr_n != 0;
            mem_write     = 1;
        
        end
        
    
    end
    
    always@(posedge clk) begin
    
        if(reset) begin
        
            query_ip_valid_r  <= 1'b0;
            query_req_ready_r <= 1'b0;
            query_rsp_valid_r <= 1'b0;
            write_ip_valid_r  <= 1'b0;
            write_req_ready_r <= 1'b0;
            clear_cache_r     <= 1'b0;
            wr_ptr_r          <= 1'b0;
        
        end else begin
        
            query_ip_valid_r  <= query_ip_valid_n;
            query_req_ready_r <= query_req_ready_n;
            query_rsp_valid_r <= query_rsp_valid_n;
            write_ip_valid_r  <= write_ip_valid_n;
            write_req_ready_r <= write_req_ready_n;
            clear_cache_r     <= clear_cache_n;
            wr_ptr_r          <= wr_ptr_n;
        
        end
        
        query_rsp_err_r <= query_rsp_err_n;
        
        if(store_query) begin
        
            query_ip_r <= query_req_ip;
        
        end
        
        if(store_write) begin
        
            write_ip_r  <= write_req_ip;
            write_mac_r <= write_req_mac;
        
        end
        
        rd_ptr_r <= rd_ptr_n;
        
        query_rsp_mac_r <= rdata_mac;
    
    end

endmodule

