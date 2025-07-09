const std = @import("std");

pub const Logger = struct {
    verbose_mode: bool = false,
    color_enabled: bool = true,
    writer: ?std.fs.File.Writer = null,

    const Self = @This();

    pub fn create(comptime config: Logger) Logger {
        return config;
    }

    pub fn info(self: Self, comptime fmt: []const u8, args: anytype) !void {
        _ = self.color_enabled;
        const writer = hasWriterBeenPassed(self, std.io.getStdOut());

        try writer.print(fmt, args);
    }
    pub fn err(self: Self, comptime fmt: []const u8, args: anytype) !void {
        _ = self.color_enabled;
        const writer = hasWriterBeenPassed(self, std.io.getStdErr());

        try writer.print("Error: ", .{});
        try writer.print(fmt, args);
    }
    pub fn verbose(self: Self, comptime fmt: []const u8, args: anytype) !void {
        if (!self.verbose_mode) return;
        const writer = hasWriterBeenPassed(self, std.io.getStdErr());

        try writer.print(fmt, args);
    }

    fn hasWriterBeenPassed(self: Self, alt_io: std.fs.File) std.fs.File.Writer {
        return if (self.writer == null) io: {
            break :io alt_io.writer();
        } else writer: {
            break :writer self.writer.?;
        };
    }
};
