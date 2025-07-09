const std = @import("std");
const builtin = @import("builtin");

const Logger = @import("logger.zig").Logger;

const Flags = @import("flags.zig").Flags;

const zwc = @import("zig_word_count.zig").zwc;

pub fn main() !void {
    var timer = try std.time.Timer.start();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var flags = Flags.create();

    var logger = Logger.create(.{});

    const file_path = try flags.checkArguments(args, logger);

    logger.verbose_mode = flags.verbose;

    flags.setDefaultIfFalse();

    const cwd = std.fs.cwd();

    const file =
        if (file_path == null) stdin: {
            try logger.verbose("Attempting to read from stdin.\n", .{});
            if (std.io.getStdIn().isTty()) {
                switch (builtin.target.os.tag) {
                    .windows => try logger.info("Reading from standard input... press Ctrl+Z tp finish.\n", .{}),
                    .linux => try logger.info("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                    .macos => try logger.info("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                    else => try logger.info("Reading from stdin... Unkown OS. Don't know how to send EOF.\n"),
                }
            }
            break :stdin std.io.getStdIn();
        } else fl: {
            try logger.verbose("Attempting to open {?s}\n", .{file_path});
            const fl = cwd.openFile(file_path.?, .{ .mode = .read_only }) catch |err| switch (err) {
                error.FileNotFound => {
                    try logger.err("No such file in directory", .{});
                    return;
                },
                else => {
                    try logger.err("{any}", .{err});
                    return;
                },
            };
            break :fl fl;
        };
    defer file.close();

    const reader = file.reader();

    zwc(reader, allocator, logger, flags) catch |err| switch (err) {
        error.IsDir => try logger.err("That's a directoy! Please choose a file", .{}),
        else => try logger.err("{any}", .{err}),
    };

    try logger.verbose("Execution time: {}ms\n", .{timer.read() / std.time.ns_per_ms});
}
