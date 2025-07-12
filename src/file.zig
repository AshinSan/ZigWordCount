const std = @import("std");
const builtin = @import("builtin");
const Logger = @import("logger.zig").Logger;

const Allocator = std.mem.Allocator;

const PathType = union(enum) {
    file: bool,
    dir: bool,
};

const AbsolutePath = struct {
    final_path: std.ArrayList([]const u8),
    file: std.ArrayList(std.fs.File),

    const Self = @This();

    pub fn init(allocator: Allocator) AbsolutePath {
        const path = AbsolutePath{
            .final_path = std.ArrayList([]const u8).init(allocator),
            .file = std.ArrayList(std.fs.File).init(allocator),
        };

        return path;
    }

    pub fn deinit(self: *Self) void {
        self.file.deinit();
        self.final_path.deinit();
    }
};

pub fn fileGetter(allocator: Allocator, file_paths: std.ArrayList([]const u8), logger: Logger) !AbsolutePath {
    var files = AbsolutePath.init(allocator);

    if (file_paths.items.len == 0) {
        try logger.verbose("Attempting to read from stdin.\n", .{});
        if (std.io.getStdIn().isTty()) {
            switch (builtin.target.os.tag) {
                .windows => try logger.info("Reading from standard input... press Ctrl+Z tp finish.\n", .{}),
                .linux => try logger.info("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                .macos => try logger.info("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                else => try logger.info("Reading from stdin... Unkown OS. Don't know how to send EOF.\n"),
            }
        }

        try files.file.append(std.io.getStdIn());
        try files.final_path.append("Stdin");
        return files;
    }

    for (file_paths.items) |path| {
        try logger.verbose("Attempting to open {s}\n", .{path});

        const cwd = std.fs.cwd();

        const Path_Type = try getPathStatType(cwd, path, logger);

        switch (Path_Type) {
            .file => {
                const fl = try getFile(cwd, path, logger);

                try files.file.append(fl);
                try files.final_path.append(path);
            },
            .dir => {
                var dir = try std.fs.cwd().openDir(path, .{ .iterate = true });
                var iterator = dir.iterate();

                while (try iterator.next()) |entry| {
                    try files.file.append(try getFile(dir, entry.name, logger));

                    const formated_path = try std.fmt.allocPrint(allocator, "{s}{s}", .{ path, entry.name });

                    try files.final_path.append(formated_path);
                }
            },
        }
    }

    return files;
}

fn getFile(dir: std.fs.Dir, path: []const u8, logger: Logger) !std.fs.File {
    const fl = dir.openFile(path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => {
            try logger.err("No file with that name found\n", .{});
            std.process.exit(1);
        },
        else => {
            try logger.err("{any}", .{err});
            std.process.exit(1);
        },
    };

    return fl;
}

fn getPathStatType(dir: std.fs.Dir, path: []const u8, logger: Logger) !PathType {
    const stat = try dir.statFile(path);

    switch (stat.kind) {
        .file => return PathType{ .file = true },
        .directory => return PathType{ .dir = true },
        else => {
            try logger.err("No such file or directory\n", .{});
            std.process.exit(1);
        },
    }
}
