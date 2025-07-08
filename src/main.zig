const std = @import("std");
const builtin = @import("builtin");
const Flags = @import("flags.zig").Flags;
const print = @import("print.zig");

const zwc = @import("zig_word_count.zig").zwc;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

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

    const cwd = std.fs.cwd();

    const file =
        if (file_path == null) stdin: {
            if (std.io.getStdIn().isTty()) {
                switch (builtin.target.os.tag) {
                    .windows => try print.err("Reading from standard input... press Ctrl+Z tp finish.\n", .{}),
                    .linux => try print.err("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                    .macos => try print.err("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                    else => try print.err("Reading from stdin... Unkown OS. Don't know how to send EOF.\n"),
                }
            }
            break :stdin std.io.getStdIn();
        } else fl: {
            const fl = cwd.openFile(file_path.?, .{ .mode = .read_only }) catch |err| switch (err) {
                error.FileNotFound => {
                    try print.err("No such file or directory.", .{});
                    return;
                },
                else => {
                    try print.err(null, .{err});
                    return;
                },
            };
            break :fl fl;
        };
    defer file.close();

    const reader = file.reader();

    const stdout = std.io.getStdOut();
    const writer = stdout.writer();

    zwc(reader, writer, allocator, flags) catch |err| switch (err) {
        error.IsDir => try print.err("That's a directoy! Please choose a file", .{}),
        else => try print.err(null, .{err}),
    };
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
        \\
        \\If passing an argument without any attempt of a filepath your terminal will 
        \\grab your input until you send the EOF command. 
    , .{});
}
