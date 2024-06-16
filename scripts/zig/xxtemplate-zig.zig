//usr/bin/env zig run "$0" -- "$@"; exit
const std = @import("std");

pub fn main() !void {
    const args = std.process.argsAlloc(std.heap.page_allocator) catch unreachable;
    defer std.process.argsFree(std.heap.page_allocator, args);

    var stdout = std.io.getStdOut().writer();
    for (args) |arg| {
        try stdout.print("{s}\n", .{arg});
    }
}
