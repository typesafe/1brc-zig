const std = @import("std");
const fs = std.fs;
const Parser = @import("Parser.zig");

pub fn generate_input_file(count: u32, cities_file: []const u8, output_file_path: []const u8) !void {
    const file = try fs.cwd().openFile(cities_file, .{ .mode = fs.File.OpenMode.read_only });
    defer file.close();

    const md = try file.metadata();
    const size = md.size() - 1; // remove '\n' at the end
    const ptr = try std.os.mmap(null, size, std.os.PROT.READ, std.os.MAP.SHARED, file.handle, 0);
    defer std.os.munmap(ptr);

    var cities = std.ArrayList([]const u8).init(std.testing.allocator);
    defer cities.deinit();
    var tempsPerCity = std.StringHashMap(f16).init(std.testing.allocator);
    defer tempsPerCity.deinit();

    var it = std.mem.splitScalar(u8, ptr, '\n');
    _ = it.next(); // header

    while (it.next()) |record| {
        var rit = std.mem.splitScalar(u8, record, ',');

        const city = if (rit.next()) |c| c else unreachable;
        const t = Parser.parseTemp(if (rit.next()) |t| t else unreachable);
        try cities.append(city);
        try tempsPerCity.put(city, (@as(f16, @floatFromInt(t)) / 10));
    }

    const output_file = try fs.cwd().openFile(output_file_path, .{ .mode = fs.File.OpenMode.write_only });
    defer output_file.close();

    var random_city = std.rand.DefaultPrng.init(123);
    var random_temp = std.rand.DefaultPrng.init(123);
    const writer = output_file.writer();

    for (0..count) |_| {
        const city = cities.items[random_city.next() % cities.items.len];

        _ = try writer.print("{s},{d:.1}\n", .{
            city,
            tempsPerCity.get(city).? + (@as(f16, @floatFromInt(random_temp.next() % 100)) / 10),
        });
    }
}

test "generate " {
    try generate_input_file(10_000, "./data/cities.csv", "./data/test.csv");
}
