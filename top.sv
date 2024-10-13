module top #(
    parameter CLK_FRE   = 50,
    parameter UART_RATE = 115200,
    parameter TEST_NUM  = 99
) (
    input sys_clk,
    output [TEST_NUM-1:0] uart_tx
);

    parameter TEST_NUM_WIDTH = $clog2(TEST_NUM);

    logic [0:3][7:0] name[TEST_NUM] = {"R19 ",
                                       "T11 ",
                                       "T10 ",
                                       "T12 ",
                                       "U12 ",
                                       "U13 ",
                                       "V13 ",
                                       "V12 ",
                                       "W13 ",
                                       "T14 ",
                                       "T15 ",
                                       "P14 ",
                                       "R14 ",
                                       "Y16 ",
                                       "Y17 ",
                                       "W14 ",
                                       "Y14 ",
                                       "T16 ",
                                       "U17 ",
                                       "V15 ",
                                       "W15 ",
                                       "U14 ",
                                       "U15 ",
                                       "U18 ",
                                       "U19 ",
                                       "P19 ",
                                       "N20 ",
                                       "P20 ",
                                       "T20 ",
                                       "U20 ",
                                       "V20 ",
                                       "W20 ",
                                       "Y18 ",
                                       "Y19 ",
                                       "V16 ",
                                       "W16 ",
                                       "R16 ",
                                       "R17 ",
                                       "T17 ",
                                       "R18 ",
                                       "V17 ",
                                       "V18 ",
                                       "W18 ",
                                       "W19 ",
                                       "N17 ",
                                       "P18 ",
                                       "P15 ",
                                       "P16 ",
                                       "T19 ",
                                       "G14 ",
                                       "C20 ",
                                       "B20 ",
                                       "B19 ",
                                       "A20 ",
                                       "E17 ",
                                       "D18 ",
                                       "D19 ",
                                       "D20 ",
                                       "E18 ",
                                       "E19 ",
                                       "F16 ",
                                       "F17 ",
                                       "M19 ",
                                       "M20 ",
                                       "M17 ",
                                       "M18 ",
                                       "L19 ",
                                       "L20 ",
                                       "K19 ",
                                       "J19 ",
                                       "L16 ",
                                       "L17 ",
                                       "K17 ",
                                       "K18 ",
                                       "H16 ",
                                       "H17 ",
                                       "J18 ",
                                       "H18 ",
                                       "F19 ",
                                       "F20 ",
                                       "G17 ",
                                       "G18 ",
                                       "J20 ",
                                       "H20 ",
                                       "G19 ",
                                       "G20 ",
                                       "H15 ",
                                       "G15 ",
                                       "K14 ",
                                       "J14 ",
                                       "N15 ",
                                       "N16 ",
                                       "L14 ",
                                       "L15 ",
                                       "M14 ",
                                       "M15 ",
                                       "K16 ",
                                       "J16 ",
                                       "J15 "};

    reg [TEST_NUM_WIDTH-1:0] pin_count;
    reg [1:0] name_count;
    reg send_en;
    wire uart_out, send_busy;
    reg [7:0] send_data;


    always @(posedge sys_clk)
        if (send_busy == 0) begin
            send_en <= 1;
            if (send_en == 0) begin
                send_data[7:0] <= name[pin_count][name_count][7:0];
                if (name_count >= 4 - 1) begin
                    name_count <= 0;
                    if (pin_count >= TEST_NUM - 1) begin
                        pin_count <= 0;
                    end else begin
                        pin_count <= pin_count + 1;
                    end
                end else begin
                    name_count <= name_count + 1;
                end
            end
        end else begin
            send_en <= 0;
        end



    //串口发送底层驱动模块
    uart_tx #(
        .CLK_FRE  (CLK_FRE),
        .UART_RATE(UART_RATE)
    ) uart_tx_m0 (
        .clk(sys_clk),

        .send_en  (send_en),
        .send_busy(send_busy),
        .send_data(send_data),

        .tx_pin(uart_out)
    );


    genvar i;
    generate
        for (i = 0; i <= TEST_NUM - 1; i = i + 1) begin : pin
            pin #(
                .PIN_NUM(i),
                .PIN_NUM_WIDTH(7)
            ) pin_inst0 (
                .clk(sys_clk),
                .uart_in(uart_out),
                .pin_num(pin_count),
                .uart_out(uart_tx[i])
            );
        end
    endgenerate

endmodule

module uart_tx #(
    parameter CLK_FRE   = 50,
    parameter UART_RATE = 115200
) (
    input clk,  // 

    input        send_en,
    output       send_busy,
    input  [7:0] send_data,

    output reg tx_pin = 1
);
    parameter RATE_CNT = (CLK_FRE * 1000_000 / UART_RATE) - 1;
    reg [15:0] clk_cnt;

    enum {
        WAIT,
        START,
        SEND,
        STOP
    } STATE_TX;
    reg [1:0] state;

    assign send_busy = state != WAIT;

    reg [7:0] send_data_r;
    reg [2:0] send_cnt;

    always @(posedge clk)
        case (state)
            WAIT:
            if (send_en) begin
                send_data_r <= send_data;
                send_cnt <= 'd0;

                state <= START;
            end

            START: begin
                tx_pin <= 0;

                if (clk_cnt >= RATE_CNT) begin
                    clk_cnt <= 0;
                    state   <= SEND;
                end else clk_cnt <= clk_cnt + 1;
            end

            SEND: begin
                tx_pin <= send_data_r[send_cnt];

                if (clk_cnt >= RATE_CNT) begin
                    clk_cnt <= 0;
                    send_cnt <= send_cnt + 1;
                    state <= (send_cnt >= 7) ? STOP : SEND;
                end else clk_cnt <= clk_cnt + 1;
            end

            STOP: begin
                tx_pin <= 1;

                if (clk_cnt >= RATE_CNT) begin
                    clk_cnt <= 0;
                    state   <= WAIT;
                end else clk_cnt <= clk_cnt + 1;
            end
        endcase
endmodule

module pin #(
    parameter PIN_NUM = 0,
    parameter PIN_NUM_WIDTH = 7
) (
    input clk,
    uart_in,
    input [PIN_NUM_WIDTH-1:0] pin_num,
    output reg uart_out
);
    always @(posedge clk) begin
        if (pin_num == PIN_NUM) uart_out <= uart_in;
        else uart_out <= 1;
    end

endmodule
