const std = @import("std");
const Flags = @import("flags.zig").Flags;
const print = @import("print.zig");

const testing = std.testing;

const File = std.fs.File;

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

const help =
    \\Zig Word Count
    \\
    \\Usage: zwc [FILE] [OPTION]
    \\
    \\CLI utility to count the amount of Lines, Words, and Characters in a file.
    \\
    \\Arguments:
    \\-h                    show this.
    \\-l                    only show amount of lines
    \\-w                    only show amount of words
    \\-c                    only show amount of characters
    \\
    \\-v                    show verbose mode (placeholder)
    \\
    \\You can combine -l -w -c into -lwc -clw to show several (show all is default)
    \\
    \\Non existing valid arguments will be ignored.
;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try print.println("Type: zwc -h for help", .{});
        return;
    }

    var file_path: ?[]const u8 = null;
    var i: usize = 1;

    var flags = Flags.create();

    while (i < args.len) : (i += 1) {
        const arg = args[i];
        if (arg[0] == '-') {
            for (arg) |char| {
                switch (char) {
                    'h' => {
                        try print.println("{s}\n\n", .{help});
                        return;
                    },
                    'v' => flags.verbose = true,
                    'l' => flags.line = true,
                    'w' => flags.word = true,
                    'c' => flags.char = true,
                    else => {},
                }
            }
        } else if (file_path == null) {
            file_path = arg;
        } else {
            try print.println("Too many positional arguments.\n", .{});
        }
    }

    flags.setDefaultIfFalse();

    if (file_path == null) {
        try print.err("Missing file path.\n", .{});
        return;
    }

    const cwd = std.fs.cwd();
    const file = cwd.openFile(file_path.?, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            try print.err("File doesn't exist.", .{err});
            return;
        },
        else => {
            try print.err(null, .{err});
            return;
        },
    };
    defer file.close();

    try zwc(file, allocator, flags);
}

fn zwc(file: File, allocator: std.mem.Allocator, flags: Flags) !void {
    const reader = file.reader();

    var line_count: usize = 0;
    var word_count: usize = 0;
    var char_count: usize = 0;

    while (true) {
        var buffer = Buffer.init(allocator);
        defer buffer.deinit();

        readLineDynamic(reader, &buffer, '\n') catch |err| switch (err) {
            error.IsDir => {
                try print.err("That is a directory. Please choose a file.", .{err});
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
