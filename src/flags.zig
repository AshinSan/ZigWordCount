const std = @import("std");
const Logger = @import("logger.zig").Logger;

const testing = std.testing;

const config = @import("config");

pub const Flags = struct {
    line: bool,
    word: bool,
    char: bool,
    verbose: bool,

    const Self = @This();

    pub fn create() Flags {
        return .{
            .line = false,
            .word = false,
            .char = false,
            .verbose = false,
        };
    }

    pub fn setDefaultIfFalse(self: *Self) void {
        if (self.line) return;
        if (self.word) return;
        if (self.char) return;

        self.line = true;
        self.word = true;
        self.char = true;
    }

    pub fn checkArguments(self: *Self, args: [][:0]u8, logger: Logger, allocator: std.mem.Allocator) !std.ArrayList([]const u8) {
        var i: usize = 1;
        var paths = std.ArrayList([]const u8).init(allocator);

        while (i < args.len) : (i += 1) {
            const arg: []u8 = args[i];
            if (arg[0] == '-' and arg[1] != '-') {
                for (arg) |char| {
                    switch (char) {
                        '-' => continue,
                        'h' => {
                            try printHelp(logger);
                            std.process.exit(0);
                        },
                        'l' => self.line = true,
                        'w' => self.word = true,
                        'c' => self.char = true,
                        'v' => self.verbose = true,
                        else => {
                            try logger.err("zwc: invalid option -- '{c}'", .{char});
                            try logger.err("Try 'zwc --help' or 'zwc -h' for more information.", .{});
                            std.process.exit(1);
                        },
                    }
                }
            } else if (std.mem.eql(u8, arg[0..2], "--")) {
                if (std.mem.eql(u8, arg, "--help")) {
                    try printHelp(logger);
                    std.process.exit(0);
                } else if (std.mem.eql(u8, arg, "--version")) {
                    try logger.info("zwc version {s}", .{config.version});
                    std.process.exit(0);
                } else if (std.mem.eql(u8, arg, "--line")) {
                    self.line = true;
                } else if (std.mem.eql(u8, arg, "--word")) {
                    self.word = true;
                } else if (std.mem.eql(u8, arg, "--char") or std.mem.eql(u8, arg, "--character")) {
                    self.char = true;
                } else if (std.mem.eql(u8, arg, "--verbose")) {
                    self.verbose = true;
                } else {
                    try logger.err("zwc: invalid option -- '{s}'", .{arg});
                    try logger.err("Try 'zwc --help' or 'zwc -h' for more information.", .{});
                    std.process.exit(1);
                }
            } else {
                try paths.append(arg);
            }
        }

        return paths;
    }

    fn printHelp(logger: Logger) !void {
        try logger.info(
            \\Zig Word Count
            \\
            \\Usage: zwc [FILE] [OPTION]
            \\
            \\CLI utility to count the amount of Lines, Words, and Characters in a file.
            \\
            \\Arguments:
            \\-h, --help                    show this.
            \\-l, --line                    only show amount of lines.
            \\-w, --word                    only show amount of words.
            \\-c, --char, --character       only show amount of characters.
            \\-v, --verbose                 verbose mode.
            \\
            \\    --version                 show version
            \\
            \\You can combine -l -w -c into -lwc -clw to show several (show all is default).
            \\
            \\Non existing valid arguments will cause an error.  
            \\
            \\If passing an argument without any attempt of a filepath your terminal will 
            \\grab your input until you send the EOF command. 
        , .{});
    }
};

test "flags set default when none given" {
    var flags = Flags.create();
    flags.setDefaultIfFalse();

    try testing.expect(flags.line);
    try testing.expect(flags.word);
    try testing.expect(flags.char);
}

test "flags set correctly from args" {
    var flags = Flags.create();
    flags.line = true;
    flags.word = true;

    flags.setDefaultIfFalse();

    try testing.expect(flags.line);
    try testing.expect(flags.word);
    try testing.expect(!flags.char);
}
