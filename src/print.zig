const std = @import("std");

pub fn println(comptime fmt: []const u8, args: anytype) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(fmt, args);
    try stdout.print("\n", .{});
}

pub fn err(comptime fmt: ?[]const u8, args: anytype) !void {
    const stderr = std.io.getStdErr().writer();
    if (fmt) |format| {
        try stderr.print("{s}", .{format});
        return;
    }
    try stderr.print("Error: {}\n", .{args});
}

pub fn verboseStderr(comptime fmt: []const u8, args: anytype) !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print(fmt, args);
}
