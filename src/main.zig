const std = @import("std");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const writer = bw.writer();

    try writer.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!

    const stdin = std.io.getStdIn();
    var br = std.io.bufferedReader(stdin.reader());
    var reader = br.reader();
    var running = true;
    while (running) {
        //Init reader stuff
        try writer.print("lizpat> ", .{});
        try bw.flush();
        var msg_buf: [128]u8 = undefined;
        var input = try reader.readUntilDelimiterOrEof(&msg_buf, '\n');
        if (input) |in| {
            try writer.print("Hello, {s}\n", .{in});
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
