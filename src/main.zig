const std = @import("std");

const Logger = @import("logger.zig").Logger;

const Flags = @import("flags.zig").Flags;

const fileGetter = @import("file.zig").fileGetter;

const zwc = @import("zig_word_count.zig").zwc;

pub fn main() !void {
    var timer = try std.time.Timer.start();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var flags = Flags.create();

    var logger = Logger.create(.{});

    const paths = try flags.checkArguments(args, logger, allocator);
    defer paths.deinit();

    logger.verbose_mode = flags.verbose;

    flags.setDefaultIfFalse();

    var files = try fileGetter(paths, logger, allocator);
    defer files.deinit();

    for (files.file.items, files.final_path.items) |fs, path| {
        const reader = fs.reader();
        defer fs.close();

        if (files.final_path.items.len > 1) {
            try logger.info("Showing result of: {s}\n", .{path});
        }
        zwc(reader, logger, flags, allocator) catch |err| switch (err) {
            error.IsDir => {},
            else => try logger.err("{any}", .{err}),
        };
    }
    try logger.verbose("Execution time: {}ms\n", .{timer.read() / std.time.ns_per_ms});
}
