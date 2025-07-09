const std = @import("std");
const builtin = @import("builtin");
const print = @import("print.zig");

const Flags = @import("flags.zig").Flags;

const zwc = @import("zig_word_count.zig").zwc;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var flags = Flags.create();

    const file_path = try flags.checkArguments(args);

    flags.setDefaultIfFalse();

    const cwd = std.fs.cwd();

    const file =
        if (file_path == null) stdin: {
            if (flags.verbose) try print.verboseStderr("Attempting to read from stdin.\n", .{});
            if (std.io.getStdIn().isTty()) {
                switch (builtin.target.os.tag) {
                    .windows => try print.println("Reading from standard input... press Ctrl+Z tp finish.\n", .{}),
                    .linux => try print.println("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                    .macos => try print.println("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                    else => try print.println("Reading from stdin... Unkown OS. Don't know how to send EOF.\n"),
                }
            }
            break :stdin std.io.getStdIn();
        } else fl: {
            if (flags.verbose) try print.verboseStderr("Attempting to open {?s}\n", .{file_path});
            const fl = cwd.openFile(file_path.?, .{ .mode = .read_only }) catch |err| switch (err) {
                error.FileNotFound => {
                    try print.err("No such file in directory", .{});
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
