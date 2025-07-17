const std = @import("std");

const Logger = @import("logger.zig").Logger;

const Flags = @import("flags.zig").Flags;

const fileStreamer = @import("file.zig").fileStreamer;

pub fn main() !void {
    var timer = try std.time.Timer.start();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var flags = Flags.create();

    var logger = Logger.create(.{});

    const paths = try flags.checkArguments(allocator, args, logger);
    defer paths.deinit();

    logger.verbose_mode = flags.verbose;

    flags.setDefaultIfFalse();

    const summary = try fileStreamer(allocator, paths.items, logger, flags);

    try summary.printSummary(logger, flags);

    try logger.verbose("Execution time: {}ms\n", .{timer.read() / std.time.ns_per_ms});
}
