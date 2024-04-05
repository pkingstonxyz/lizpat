const std = @import("std");
const Allocator = std.mem.Allocator;

const SType = enum {
    identifier,
    cell,
};
const Sexp = union(SType) {
    identifier: usize,
    cell: struct {
        car: *Sexp,
        cdr: *Sexp,
    },
};

const TType = enum {
    leftParen,
    rightParen,
    eof,
    unexpectedChar,
};

const Token = struct {
    type: TType,
    payload: []u8,
};

const Scanner = struct {
    start: usize,
    current: usize,
    line: usize,
    source: []u8,
    pub fn create(newSource: []u8) Scanner {
        return Scanner{
            .source = newSource,
            .start = 0,
            .current = 0,
            .line = 1,
        };
    }
    pub fn reinit(scanner: *Scanner, newSource: []u8) void {
        scanner.*.start = 0;
        scanner.*.current = 0;
        scanner.*.line = 1;
        scanner.*.source = newSource;
    }
    pub fn is_at_end(scanner: *Scanner) bool {
        return scanner.*.current >= scanner.*.source.len;
    }
    pub fn advance(scanner: *Scanner) u8 {
        scanner.*.current += 1;
        return scanner.*.source[scanner.*.current - 1];
    }
    pub fn peek(scanner: *Scanner) u8 {
        return scanner.*.source[scanner.*.current];
    }
    pub fn get_payload(scanner: *Scanner) []u8 { //Grabs a chunk
        return scanner.*.source[scanner.*.start..scanner.*.current];
    }
    pub fn handle_whitespace_and_comments(scanner: *Scanner) void {
        while (!Scanner.is_at_end(scanner)) {
            const c = Scanner.peek(scanner);
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = Scanner.advance(scanner);
                },
                '\n' => {
                    scanner.*.line += 1;
                    _ = Scanner.advance(scanner);
                },
                ';' => { //Ignore everything after a semicolon
                    while (!Scanner.is_at_end(scanner) and Scanner.peek(scanner) != '\n') {
                        _ = Scanner.advance(scanner);
                    }
                },
                else => return,
            }
        }
    }
    pub fn next(scanner: *Scanner) Token {
        Scanner.handle_whitespace_and_comments(scanner);
        scanner.*.start = scanner.*.current; //Move to the next chunk

        if (Scanner.is_at_end(scanner)) return Token{
            .type = TType.eof,
            .payload = Scanner.get_payload(scanner),
        };

        const c: u8 = Scanner.advance(scanner);

        switch (c) {
            '(' => return Token{
                .type = TType.leftParen,
                .payload = Scanner.get_payload(scanner),
            },
            ')' => return Token{
                .type = TType.rightParen,
                .payload = Scanner.get_payload(scanner),
            },
            else => return Token{
                .type = TType.unexpectedChar,
                .payload = undefined,
            },
        }
    }
};

pub fn read(allocator: Allocator, scanner: *Scanner) !void {
    _ = allocator;
    //_ = allocator;
    //_ = string;
    //const word = "hello";
    //const a = Sexp{ .atom = &word };
    //const d = Sexp{ .atom = &word };
    //const cell = Sexp{ .cell = .{
    //    .car = &a,
    //    .cdr = &d,
    //} };
    //_ = cell;
    //_ = sexp;

    //
    //A dummy read function that tests if I understand how zig arrays/slices work
    //
    //const sexp = try allocator.alloc(Sexp, @sizeOf(Sexp));
    //const sexp = try allocator.create(Sexp);
    //if (string.len == 0) { //Base case (end of string)
    //    return sexp;
    //} else {
    //    const char = string[0];
    //    std.debug.print("{c}\n", .{char});
    //    const next = try read(allocator, string[1..]);
    //    return next;
    //}
    //const typeo = @typeName(@TypeOf(sexp));
    //std.debug.print("{s}\n", .{typeo});
    //std.debug.print("Why did we reach here? String is: {s}\n", .{string});
    //return sexp;
    while (!Scanner.is_at_end(scanner)) {
        const nextTok = Scanner.next(scanner);
        std.debug.print("Type: {s} | Payload: {s}\n", .{ @tagName(nextTok.type), nextTok.payload });
    }
}

pub fn eval(exp: Sexp) Sexp {
    return exp;
}

pub fn print(exp: Sexp) !void {
    _ = exp;
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
            try read(allocator, &scanner);
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
