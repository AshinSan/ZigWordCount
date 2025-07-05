const std = @import("std");
const Flags = @import("flags.zig").Flags;
const print = @import("print.zig");

const testing = std.testing;

const Buffer = struct {
    str: []u8,
    len: usize,
    allocator: std.mem.Allocator,

    const Self = @This();

    fn init(allocator: std.mem.Allocator) Buffer {
        return .{
            .str = undefined,
            .len = 0,
            .allocator = allocator,
        };
    }

    fn deinit(self: *Self) void {
        self.allocator.free(self.str);
    }
};

pub fn zwc(reader: anytype, allocator: std.mem.Allocator, flags: Flags) !void {
    var line_count: usize = 0;
    var word_count: usize = 0;
    var char_count: usize = 0;

    while (true) {
        var buffer = Buffer.init(allocator);
        defer buffer.deinit();
        readLineDynamic(reader, &buffer, '\n') catch |err| switch (err) {
            error.IsDir => {
                try print.err("That is a directory. Please choose a file.", .{});
                return;
            },
            else => {
                try print.err(null, .{err});
            },
        };

        if (buffer.len == 0) break;

        line_count += 1;
        char_count += buffer.len;

        var words = std.mem.tokenizeScalar(u8, buffer.str[0..buffer.len], ' ');

        while (words.next() != null) {
            word_count += 1;
        }
    }

    if (flags.line) try print.println("> Line count -- {d}", .{line_count});
    if (flags.word) try print.println("> word count -- {d}", .{word_count});
    if (flags.char) try print.println("> char count -- {d}", .{char_count});
}

fn readLineDynamic(reader: anytype, buffer: *Buffer, delimiter: u8) !void {
    buffer.str = try buffer.allocator.alloc(u8, 64); // initial guess
    buffer.len = 0;

    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        if (buffer.len == buffer.str.len) {
            const new_buf = try buffer.allocator.realloc(buffer.str, buffer.str.len * 2);
            buffer.str = new_buf;
        }

        buffer.str[buffer.len] = byte;
        buffer.len += 1;

        if (byte == delimiter) break;
    }
}

test "Is line too big for allocated memory" {
    var text: [127]u8 = undefined;
    @memset(&text, 'a');
    var stream = std.io.fixedBufferStream(&text);
    const reader = stream.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var buffer = Buffer.init(allocator);

    try readLineDynamic(reader, &buffer, '\n');

    try testing.expect(buffer.str.len == 128);
}

test "Does it read until delimiter" {
    var text: [64]u8 = undefined;
    var stream = std.io.fixedBufferStream(&text);
    const writer = stream.writer();

    try writer.print("A storm is aproaching.\n and I'm the storm.\n", .{});

    const reader = stream.reader();

    stream.pos = 0;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var buffer = Buffer.init(allocator);

    try readLineDynamic(reader, &buffer, '\n');

    try testing.expectEqualStrings(text[0..buffer.len], buffer.str[0..buffer.len]);

    stream.pos = 0;

    try readLineDynamic(reader, &buffer, ' ');

    try testing.expectEqualStrings(text[0..buffer.len], buffer.str[0..buffer.len]);
}
