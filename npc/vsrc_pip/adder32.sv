module adder32(
    input  [31 : 0] a,
    input  [31 : 0] b,
    input cin,

    output  [31 : 0] result,
    output cout
);

wire [31 : 0] p = a | b;
wire [31 : 0] g = a & b;
wire [7 : 0] P, G;
wire [31 : 0] c;

carry_4 C3_0(p[3 : 0], g[3 : 0], cin, c[2 : 0], P[0], G[0]);
carry_4 C7_4(p[7 : 4], g[7 : 4], c[3], c[6 : 4], P[1], G[1]);
carry_4 C11_8(p[11 : 8], g[11 : 8], c[7], c[10 : 8], P[2], G[2]);
carry_4 C15_12(p[15 : 12], g[15 : 12], c[11], c[14 : 12], P[3], G[3]);

carry_4_out_4 C_INTER_2_1(P[3 : 0], G[3 : 0], cin, {c[15], c[11], c[7], c[3]});

carry_4 C19_16(p[19 : 16], g[19 : 16], c[15], c[18 : 16], P[4], G[4]);
carry_4 C23_20(p[23 : 20], g[23 : 20], c[19], c[22 : 20], P[5], G[5]);
carry_4 C27_24(p[27 : 24], g[27 : 24], c[23], c[26 : 24], P[6], G[6]);
carry_4 C31_28(p[31 : 28], g[31 : 28], c[27], c[30 : 28], P[7], G[7]);

carry_4_out_4 C_INTER_2_2(P[7 : 4], G[7 : 4], c[15], {c[31], c[27], c[23], c[19]});

assign result = a ^ b ^ {c[30 : 0], cin};
assign cout = c[31];


endmodule


module carry_4(
    input [3 : 0] p,
    input [3 : 0] g,
    input cin,
    
    output [2 : 0] cout,

    output P,
    output G
);

assign P = &p;
assign G = g[3] | p[3] & g[2] | p[3] & p[2] & g[1] | p[3] & p[2] & p[1] & g[0];


assign cout[0] = g[0] | p[0] & cin;
assign cout[1] = g[1] | p[1] & g[0] | p[1] & p[0] & cin;
assign cout[2] = g[2] | p[2] & g[1] | p[2] & p[1] & g[0] | p[2] & p[1] & p[0] & cin;


endmodule



module carry_4_out_4(
    input [3 : 0] p,
    input [3 : 0] g,
    input cin,
    
    output [3 : 0] cout
);

assign cout[0] = g[0] | p[0] & cin;
assign cout[1] = g[1] | p[1] & g[0] | p[1] & p[0] & cin;
assign cout[2] = g[2] | p[2] & g[1] | p[2] & p[1] & g[0] | p[2] & p[1] & p[0] & cin;
assign cout[3] = g[3] | p[3] & g[2] | p[3] & p[2] & g[1] | p[3] & p[2] & p[1] & g[0] | p[3] & p[2] & p[1] & p[0] & cin;

endmodule



