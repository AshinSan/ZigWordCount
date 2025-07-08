const std = @import("std");
const builtin = @import("builtin");
const Flags = @import("flags.zig").Flags;
const print = @import("print.zig");

const zwc = @import("zig_word_count.zig").zwc;

const version = "0.0.11";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var file_path: ?[]const u8 = null;
    var i: usize = 1;

    var flags = Flags.create();

    while (i < args.len) : (i += 1) {
        const arg: []u8 = args[i];
        if (arg[0] == '-' and arg[1] != '-') {
            for (arg) |char| {
                switch (char) {
                    '-' => continue,
                    'h' => {
                        try printHelp();
                        return;
                    },
                    'l' => flags.line = true,
                    'w' => flags.word = true,
                    'c' => flags.char = true,
                    else => {
                        try print.println("zwc: invalid option -- '{c}'", .{char});
                        try print.err("Try 'zwc --help' or 'zwc -h' for more information.", .{});
                        std.process.exit(1);
                    },
                }
            }
        } else if (std.mem.eql(u8, arg[0..2], "--")) {
            if (std.mem.eql(u8, arg, "--help")) {
                try printHelp();
                return;
            } else if (std.mem.eql(u8, arg, "--version")) {
                try print.println("zwc version {s}", .{version});
                return;
            } else if (std.mem.eql(u8, arg, "--line")) {
                flags.line = true;
            } else if (std.mem.eql(u8, arg, "--word")) {
                flags.word = true;
            } else if (std.mem.eql(u8, arg, "--char") or std.mem.eql(u8, arg, "--character")) {
                flags.char = true;
            } else {
                try print.println("zwc: invalid option -- '{s}'", .{arg});
                try print.err("Try 'zwc --help' or 'zwc -h' for more information.", .{});
                std.process.exit(1);
            }
        } else if (file_path == null) {
            file_path = arg;
        } else {
            try print.err("Too many positional arguments.\n", .{});
            std.process.exit(1);
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
        \\-h, --help                    show this.
        \\-l, --line                    only show amount of lines
        \\-w, --word                    only show amount of words
        \\-c, --char, --character       only show amount of characters
        \\
        \\    --version                 show version
        \\
        \\You can combine -l -w -c into -lwc -clw to show several (show all is default)
        \\
        \\Non existing valid arguments will cause an error.  
        \\
        \\If passing an argument without any attempt of a filepath your terminal will 
        \\grab your input until you send the EOF command. 
    , .{});
}
