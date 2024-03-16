const std = @import("std");

// Rules: temp = non null double between -99.9 (inclusive) and 99.9 (inclusive), always with one fractional digit
// i11 = 2^11 -> can hold -999 to 999
pub inline fn parseTemp(chunk: []const u8) i11 {
    var res: i11 = 0;
    var minus = false;
    var decimal = false;
    for (chunk) |c| {
        switch (c) {
            '-' => minus = true,
            '0'...'9' => {
                res *= 10;
                res += c - '0';
            },
            '.' => decimal = true,
            else => {}, // TODO: use unreachable when the input file has been cleaned up
        }
    }
    if (!decimal) {
        res *= 10;
    }

    res *= if (minus) -1 else 1;

    return res;
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
