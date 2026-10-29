`timescale 1ns/1ps

module cnn_addr_gen (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,

    output logic [1:0]  bank_sel  [0:2],
    output logic [13:0] bank_addr [0:2],

    input  logic [7:0]  bank_dout [0:3],

    output logic [23:0] pixel_out,
    output logic        out_valid,
    output logic        busy,
    output logic        done
);

    logic [7:0] row_idx;
    logic [7:0] col_start;
    logic       active;

    // Generate addresses for three consecutive columns.
    // Bank mapping: global column modulo 4.
    // Local column: global column divided by 4.
    always_comb begin
        for (int i = 0; i < 3; i++) begin
            bank_sel[i] =
                (int'(col_start) + i) % 4;

            bank_addr[i] =
                (int'(row_idx) * 64) +
                ((int'(col_start) + i) / 4);
        end
    end

    // Reassemble pixels in left-to-right order.
    always_comb begin
        pixel_out = {
            bank_dout[bank_sel[0]],
            bank_dout[bank_sel[1]],
            bank_dout[bank_sel[2]]
        };
    end

    assign busy = active;

    // Address-generation controller.
    // Scan rows for each window position, then advance the column.
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            row_idx   <= 8'd0;
            col_start <= 8'd0;
            active    <= 1'b0;
            out_valid <= 1'b0;
            done      <= 1'b0;
        end
        else begin
            out_valid <= 1'b0;
            done      <= 1'b0;

            if (start && !active) begin
                row_idx   <= 8'd0;
                col_start <= 8'd0;
                active    <= 1'b1;
            end
            else if (active) begin
                out_valid <= 1'b1;

               if (row_idx == 8'd255) begin
			row_idx <= 8'd0;

			if (col_start == 8'd253) begin
				active    <= 1'b0;
				done      <= 1'b1;
				out_valid <= 1'b0;
			end
			else begin
				col_start <= col_start + 1'b1;
			end
		end

                else begin
                    row_idx <= row_idx + 1'b1;
                end
            end
        end
    end

endmodule
