const std = @import("std");

pub fn println(comptime fmt: []const u8, args: anytype) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(fmt, args);
    try stdout.print("\n", .{});
}

pub fn print(comptime fmt: []const u8, args: anytype) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(fmt, args);
}

pub fn err(comptime fmt: ?[]const u8, args: anytype) !void {
    const stderr = std.io.getStdErr().writer();
    if (fmt != null) {
        try stderr.print("{?s} {}\n", .{ fmt, args });
        return;
    }
    try stderr.print("Error: {}\n", .{args});
}

pub fn writeAll(fmt: []const u8) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll(fmt);
}
