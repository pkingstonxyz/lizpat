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
    //The allmighty parens
    leftParen,
    rightParen,
    //literals
    string,
    binary, //treated as integer literals
    hex,
    number, //treated as a double (for now)
    //File stuff
    eof,
    //errors
    EunexpectedChar,
    EunterminatedString,
    Einvalidbinary,
    Einvalidhex,
    Einvalidnumber,
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
    pub fn peek_next(scanner: *Scanner) u8 {
        if (Scanner.is_at_end(scanner)) return 0;
        return scanner.*.source[scanner.*.current + 1];
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
    pub fn grab_number(scanner: *Scanner) Token {
        if (Scanner.is_at_end(scanner)) {
            return Token{
                .type = TType.number,
                .payload = Scanner.get_payload(scanner),
            };
        }
        while (!Scanner.is_at_end(scanner) and Scanner.peek(scanner) >= '0' and Scanner.peek(scanner) <= '9') {
            _ = Scanner.advance(scanner);
        }
        if (!Scanner.is_at_end(scanner) and Scanner.peek(scanner) == '.' and
            Scanner.peek_next(scanner) >= '0' and Scanner.peek_next(scanner) <= '9')
        {
            //Grab the .
            _ = Scanner.advance(scanner);
            while (!Scanner.is_at_end(scanner) and Scanner.peek(scanner) >= '0' and Scanner.peek(scanner) <= '9') {
                _ = Scanner.advance(scanner);
            }
        }
        return Token{
            .type = TType.number,
            .payload = Scanner.get_payload(scanner),
        };
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
            //Parentheses
            '(' => return Token{
                .type = TType.leftParen,
                .payload = Scanner.get_payload(scanner),
            },
            ')' => return Token{
                .type = TType.rightParen,
                .payload = Scanner.get_payload(scanner),
            },
            //Strings
            '"' => {
                while (!Scanner.is_at_end(scanner) and Scanner.peek(scanner) != '"') {
                    if (Scanner.peek(scanner) == '\n') scanner.*.line += 1;
                    _ = Scanner.advance(scanner);
                }
                if (Scanner.is_at_end(scanner)) return Token{ .type = TType.EunterminatedString, .payload = undefined };
                _ = Scanner.advance(scanner); //Closing quote
                return Token{
                    .type = TType.string,
                    .payload = Scanner.get_payload(scanner),
                };
            },
            //Numbers
            '0' => {
                if (Scanner.is_at_end(scanner)) { //Just a zero
                    return Token{
                        .type = TType.number,
                        .payload = Scanner.get_payload(scanner),
                    };
                }
                const following = Scanner.peek(scanner);
                switch (following) {
                    //Binary
                    'b' => {
                        //Grab the b
                        _ = Scanner.advance(scanner);
                        while (!Scanner.is_at_end(scanner)) {
                            const num = Scanner.peek(scanner);
                            if (num == '0' or num == '1') {
                                _ = Scanner.advance(scanner);
                            } else if (num > '1' and num <= '9') {
                                //Encountering a bad number
                                return Token{
                                    .type = TType.Einvalidbinary,
                                    .payload = undefined,
                                };
                            } else {
                                //We move on (i.e. 0b0hello is tokenized as 0b0 and hello)
                                return Token{
                                    .type = TType.binary,
                                    .payload = Scanner.get_payload(scanner),
                                };
                            }
                        }
                        return Token{
                            .type = TType.binary,
                            .payload = Scanner.get_payload(scanner),
                        };
                    },
                    //Hexadecimal
                    'x' => {
                        //Grab the x
                        _ = Scanner.advance(scanner);
                        while (!Scanner.is_at_end(scanner)) {
                            const num = Scanner.peek(scanner);
                            if ((num >= '0' and num <= '9') or
                                (num >= 'a' and num <= 'f') or
                                (num >= 'A' and num <= 'F'))
                            {
                                _ = Scanner.advance(scanner);
                            } else {
                                //We move on (i.e. 0x0hello is tokenized as 0x0 and hello)
                                return Token{
                                    .type = TType.hex,
                                    .payload = Scanner.get_payload(scanner),
                                };
                            }
                        }
                        return Token{
                            .type = TType.hex,
                            .payload = Scanner.get_payload(scanner),
                        };
                    },
                    //A standard number (numbers can be prefixed by as many 0s as you want)
                    '0'...'9', '.' => {
                        return Scanner.grab_number(scanner);
                    },
                    else => {
                        return Token{ .type = TType.number, .payload = Scanner.get_payload(scanner) };
                    },
                }
            },
            '1'...'9' => {
                return Scanner.grab_number(scanner);
            },
            else => return Token{
                .type = TType.EunexpectedChar,
                .payload = undefined,
            },
        }
    }
};

pub fn read(allocator: Allocator, scanner: *Scanner) !void {
    _ = allocator;
    while (true) {
        const tok = Scanner.next(scanner);
        std.debug.print("Type: {s} | Payload: {s}\n", .{ @tagName(tok.type), tok.payload });
        switch (tok.type) {
            //File ended quit reading
            TType.eof => return,
            //Errors quit reading (this needs to be fleshed out lmao)
            TType.EunexpectedChar,
            TType.EunterminatedString,
            TType.Einvalidbinary,
            => return,
            //Keep on trucking
            else => continue,
        }
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
