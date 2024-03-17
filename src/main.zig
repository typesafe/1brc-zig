const std = @import("std");
const Input = @import("Input.zig");

pub fn main() !void {
    try Input.process_file("data/input.csv");
}

test "run" {
    try main();
}
