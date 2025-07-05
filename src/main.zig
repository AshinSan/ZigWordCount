const std = @import("std");
const Flags = @import("flags.zig").Flags;
const print = @import("print.zig");

const zwc = @import("zig_word_count.zig").zwc;

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
                        try printHelp();
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
            try print.err("Too many positional arguments.\n", .{});
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

    const reader = file.reader();

    try zwc(reader, allocator, flags);
}

fn printHelp() !void {
    try print.println(
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
    , .{});
}
