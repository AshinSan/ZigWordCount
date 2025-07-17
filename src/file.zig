const std = @import("std");
const builtin = @import("builtin");
const Logger = @import("logger.zig").Logger;
const Flags = @import("flags.zig").Flags;

const zwc = @import("zig_word_count.zig");

const Allocator = std.mem.Allocator;

const PathType = enum {
    File,
    Dir,
};

pub fn fileStreamer(allocator: Allocator, file_paths: []const []const u8, logger: Logger, flags: Flags) !zwc.Summary {
    if (file_paths.len == 0) {
        try logger.verbose("Attempting to read from stdin.\n", .{});
        if (std.io.getStdIn().isTty()) {
            switch (builtin.target.os.tag) {
                .windows => try logger.info("Reading from standard input... press Ctrl+Z tp finish.\n", .{}),
                .linux => try logger.info("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                .macos => try logger.info("Reading from standard input... press Ctrl+D tp finish.\n", .{}),
                else => try logger.info("Reading from stdin... Unkown OS. Don't know how to send EOF.\n"),
            }
        }

        const stdin = std.io.getStdIn();
        const reader = stdin.reader();

        return zwc.wordCounter(allocator, reader, logger, flags);
    }

    var summary = zwc.Summary.create();

    for (file_paths) |path| {
        try logger.verbose("Attempting to open {s}\n", .{path});

        const dir = std.fs.cwd();

        const Path_Type = try getPathStatType(dir, path, logger);

        switch (Path_Type) {
            .File => {
                summary.add(try fileProcessor(allocator, dir, path, logger, flags));
            },
            .Dir => {
                summary.merge(try dirProcessor(allocator, dir, path, logger, flags));
            },
        }
    }
    return summary;
}

fn dirProcessor(allocator: Allocator, directory: std.fs.Dir, path: []const u8, logger: Logger, flags: Flags) anyerror!zwc.Summary {
    var dir = try directory.openDir(path, .{ .iterate = true });
    var iterator = dir.iterate();

    var summary = zwc.Summary.create();

    while (try iterator.next()) |entry| {
        const joined_path = try std.fs.path.join(allocator, &[_][]const u8{ path, entry.name });
        defer allocator.free(joined_path);

        const path_type = try getPathStatType(dir, entry.name, logger);
        if (path_type == PathType.Dir) {
            if (flags.recursive) {
                summary.add(try fileStreamer(allocator, &[_][]const u8{joined_path}, logger, flags));
                continue;
            }
            continue;
        }
        summary.add(try fileProcessor(allocator, dir, entry.name, logger, flags));
    }

    return summary;
}

fn fileProcessor(allocator: Allocator, dir: std.fs.Dir, path: []const u8, logger: Logger, flags: Flags) !zwc.Summary {
    var timer = try std.time.Timer.start();
    defer logger.verbose("Execution time: {}ms\n", .{timer.read() / std.time.ns_per_ms}) catch unreachable;

    const fl = try getFile(dir, path, logger);
    defer fl.close();

    const reader = fl.reader();

    try logger.info("Showing result of: {s}\n", .{path});

    return try zwc.wordCounter(allocator, reader, logger, flags);
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
    const stat = dir.statFile(path) catch |err| switch (err) {
        else => {
            try logger.err("Can't find {s}\nNo such file or directory.\n", .{path});
            std.process.exit(1);
        },
    };

    switch (stat.kind) {
        .file => return PathType.File,
        .directory => return PathType.Dir,
        else => unreachable,
    }
}
