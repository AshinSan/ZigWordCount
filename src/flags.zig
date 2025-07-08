const std = @import("std");
const testing = std.testing;

pub const Flags = struct {
    line: bool,
    word: bool,
    char: bool,

    const Self = @This();

    pub fn create() Flags {
        return .{
            .line = false,
            .word = false,
            .char = false,
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
