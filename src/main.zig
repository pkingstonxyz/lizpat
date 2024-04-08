const std = @import("std");
const Allocator = std.mem.Allocator;
const scandef = @import("scanner.zig");
const Scanner = scandef.Scanner;
const TType = scandef.TType;

const SType = enum {
    atom,
    cell,
};
const Sexp = union(SType) {
    atom: usize,
    cell: struct {
        car: ?*Sexp,
        cdr: ?*Sexp,
    },
};

pub fn read(allocator: Allocator, scanner: *Scanner) !Sexp {
    const errSexp = Sexp{
        .atom = 0xafafafaf,
    };
    while (true) {
        const tok = Scanner.next(scanner);
        std.debug.print("Type: {s} | Payload: {s}\n", .{ @tagName(tok.type), tok.payload });
        switch (tok.type) {
            //File ended quit reading
            TType.eof => return errSexp,
            //Errors quit reading (this needs to be fleshed out/thought out lmao)
            TType.EunexpectedChar,
            TType.EunterminatedString,
            TType.Einvalidbinary,
            => return errSexp,
            //Open parentheses, read a list
            TType.leftParen => {
                var car = try read(allocator, scanner);
                var cdr = try read(allocator, scanner);
                const s = Sexp{
                    .cell = .{
                        .car = &car,
                        .cdr = &cdr,
                    },
                };
                return s;
            },
            TType.number => {
                const integer: usize = try std.fmt.parseInt(usize, tok.payload, 10);
                return Sexp{ .atom = integer };
            },
            //Keep on trucking
            else => continue,
        }
    }
    try std.debug.print("Something went wrong\n", .{});
    return errSexp;
}

pub fn eval(exp: Sexp) Sexp {
    return exp;
}

pub fn print(sexp: Sexp) !void {
    switch (sexp) {
        SType.atom => {
            const int: usize = sexp.atom;
            std.debug.print("{d}", .{int});
        },
        SType.cell => {
            std.debug.print("(", .{});
            const car = sexp.cell.car;
            const cdr = sexp.cell.cdr;
            if (car) |a| {
                try print(a.*);
            }
            if (cdr) |d| {
                try print(d.*);
            }
            std.debug.print(")\n", .{});
        },
    }
}

pub fn main() !void {
    //
    // Stuff that lets you print
    //

    //std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const writer = bw.writer();

    try writer.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!

    //
    // Input stuff
    //
    const stdin = std.io.getStdIn();
    var br = std.io.bufferedReader(stdin.reader());
    var reader = br.reader();
    //
    //Init scanner
    //
    var scanner: Scanner = Scanner.create("");

    //
    // Stuff that lets me get memory
    //
    var membuffer: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&membuffer);
    const allocator = fba.allocator();

    //
    // Main loop
    //
    var running = true;
    while (running) {
        //Init reader stuff
        try writer.print("lizpat> ", .{});
        try bw.flush();
        var msg_buf: [256]u8 = undefined;
        var input = try reader.readUntilDelimiterOrEof(&msg_buf, '\n');
        if (input) |in| {
            //try writer.print("Hello, {s}\n", .{in});
            scanner.reinit(in);
            const sexp = try read(allocator, &scanner);
            try print(sexp);
        }

        try bw.flush();
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
