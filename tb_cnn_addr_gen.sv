`timescale 1ns/1ps

module tb_cnn_addr_gen;

    logic clk = 0;
    logic reset_n = 0;
    logic start = 0;

    logic [1:0]  bank_sel  [0:2];
    logic [13:0] bank_addr [0:2];
    logic [7:0]  bank_dout [0:3];

    logic [23:0] pixel_out;
    logic out_valid, busy, done;

    logic [7:0] bank_mem [0:3][0:16383];

    integer checks;
    integer cycles;

    cnn_addr_gen dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .bank_sel(bank_sel),
        .bank_addr(bank_addr),
        .bank_dout(bank_dout),
        .pixel_out(pixel_out),
        .out_valid(out_valid),
        .busy(busy),
        .done(done)
    );

    always #5 clk = ~clk;

    // Four-bank behavioral SRAM.
    always_comb begin
        for (int b = 0; b < 4; b++)
            bank_dout[b] = 8'h00;

        for (int p = 0; p < 3; p++)
            bank_dout[bank_sel[p]] =
                bank_mem[bank_sel[p]][bank_addr[p]];
    end

    task check_column(input integer col);
        begin
            // Set the controller's position for a direct mapping check.
            // This is a testbench-only hierarchical check.
            force dut.col_start = col;
            force dut.row_idx = 8'd5;
            #1;

            if (bank_sel[0] !== (col % 4) ||
                bank_sel[1] !== ((col + 1) % 4) ||
                bank_sel[2] !== ((col + 2) % 4)) begin
                $error("Bank mapping failed at column %0d", col);
                $fatal;
            end

            if (bank_addr[0] !== (5*64 + col/4) ||
                bank_addr[1] !== (5*64 + (col+1)/4) ||
                bank_addr[2] !== (5*64 + (col+2)/4)) begin
                $error("Address mapping failed at column %0d", col);
                $fatal;
            end

            $display(
                "PASS col=%0d banks=%0d,%0d,%0d addresses=%0d,%0d,%0d",
                col,
                bank_sel[0], bank_sel[1], bank_sel[2],
                bank_addr[0], bank_addr[1], bank_addr[2]
            );

            checks = checks + 1;
            release dut.col_start;
            release dut.row_idx;
            @(negedge clk);
        end
    endtask

    initial begin
        checks = 0;
        cycles = 0;

        for (int b = 0; b < 4; b++)
            for (int a = 0; a < 16384; a++)
                bank_mem[b][a] = 8'h00;

        repeat (3) @(negedge clk);
        reset_n = 1;

        // Verify mapping at five consecutive window positions.
        check_column(0);
        check_column(1);
        check_column(2);
        check_column(3);
        check_column(4);

        // Reset controller before the full scan.
        reset_n = 0;
        repeat (2) @(negedge clk);
        reset_n = 1;
        @(negedge clk);

        start = 1;
        @(negedge clk);
        start = 0;

        // Full scan: 254 valid window positions x 256 rows.
        while (!done && cycles < 70000) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

$display("FINAL STATE: row=%0d col=%0d busy=%b done=%b out_valid=%b",
        dut.row_idx, dut.col_start, busy, done, out_valid);

        if (!done) begin
            $fatal(1, "FAIL: scan did not complete");
        end

        $display("PASS: scan completed in %0d cycles", cycles);
        $display("PASS: %0d mapping checks completed", checks);
        $finish;
    end

endmodule

