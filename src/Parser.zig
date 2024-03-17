const std = @import("std");

pub const TEMP = f32;

// chunk starts after a ',' and can have 5 chars max: -99.9\n
pub inline fn parseTemp(chunk: []const u8, offset: *usize) TEMP {
    var res: i11 = 0;
    var minus = false;
    var decimal = false;
    for (0..6) |_| {
        const c = chunk[offset.*];
        offset.* += 1;
        switch (c) {
            '-' => minus = true,
            '0'...'9' => {
                res *= 10;
                res += c - '0';
            },
            '.' => decimal = true,
            else => break,
        }
    }
    if (!decimal) {
        res *= 10;
    }

    res *= if (minus) -1 else 1;

    return @as(TEMP, @floatFromInt(res));
}

test "parseTemp('99.9')" {
    try std.testing.expectEqual(parseTemp("99.9"), 999);
}

test "parseTemp('-99.9')" {
    try std.testing.expectEqual(parseTemp("-99.9"), -999);
}

test "parseTemp('12.1')" {
    try std.testing.expectEqual(parseTemp("12.1"), 121);
}

test "parseTemp('-12')" {
    try std.testing.expectEqual(parseTemp("-12"), -120);
}

test "parseTemp('9')" {
    try std.testing.expectEqual(parseTemp("9"), 90);
}

test "parseTemp('−2.3')" {
    try std.testing.expectEqual(parseTemp("-2.3"), -23);
}

test "parseTemp('-0.9')" {
    try std.testing.expectEqual(parseTemp("-0.9"), -9);
}

test "parseTemp('-.9')" {
    try std.testing.expectEqual(parseTemp("-.9"), -9);
}
