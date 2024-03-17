const std = @import("std");
const fs = std.fs;
const print = std.debug.print;
const is_zig_11 = @import("builtin").zig_version.minor == 11;
const Parser = @import("Parser.zig");

const TEMP = Parser.TEMP;
const filename = "./data/input.csv";

test "process_file" {
    try process_file("./data/test.csv");
}

pub fn process_file(path: ?[]const u8) !void {
    const file = try fs.cwd().openFile(if (path) |v| v else filename, .{ .mode = fs.File.OpenMode.read_only });
    defer file.close();

    const md = try file.metadata();
    const buffer_len = md.size(); // ignore trailing '\n'

    const buffer = try std.os.mmap(null, buffer_len, std.os.PROT.READ, std.os.MAP.PRIVATE, file.handle, 0);
    defer std.os.munmap(buffer);

    _ = try process_file_buffer(buffer, buffer_len);
}

const Stats = struct {
    min: TEMP = 1000,
    max: TEMP = -1000,
    sum: TEMP = 0,
    cnt: TEMP = 0,
};

const VECTOR_SIZE = if (std.simd.suggestVectorSize(TEMP)) |v| v else 0;

// Processes values of a city
const CityWorkingSet = struct {
    const Self = @This();

    //readings: @Vector(VECTOR_SIZE, TEMP) = @splat(@as(TEMP, 0)),
    //count: u32 = 0,
    stats: Stats = Stats{ .min = 1000, .max = -1000, .sum = 0, .cnt = 0 },

    pub fn add(self: *Self, value: TEMP) void {
        self.stats.cnt += 1;
        self.stats.min = @min(self.stats.min, value);
        self.stats.max = @max(self.stats.max, value);
        self.stats.sum += value;

        // self.update_stats(false);
        // self.readings[self.count] = value;
        // self.count += 1;
    }

    // fn update_stats(self: *Self, force: bool) void {
    //     if (self.count == VECTOR_SIZE or force and self.count > 0) {
    //         self.stats.cnt += self.count;
    //         self.stats.min = @min(self.stats.min, @reduce(.Min, self.readings));
    //         self.stats.max = @max(self.stats.max, @reduce(.Max, self.readings));
    //         self.stats.sum += @reduce(.Add, self.readings);

    //         //std.debug.print("{} min: {}\n", .{ self.readings, self.stats.min });

    //         self.readings = @splat(@as(TEMP, 0));
    //         self.count = 0;
    //     }
    // }

    pub fn get_stats(self: *Self) Stats {
        //self.update_stats(true);
        return self.stats;
    }
};

const ChunkState = struct {
    const Self = @This();

    cities: std.StringHashMap(CityWorkingSet),
    chunk: []const u8,

    pub fn init(chunk: []const u8, allocator: std.mem.Allocator) !Self {
        return Self{ .chunk = chunk, .cities = std.StringHashMap(CityWorkingSet).init(allocator) };
    }

    pub fn deinit(self: *Self) void {
        self.cities.deinit();
    }
};

fn process_file_buffer(buffer: []const u8, buffer_length: u64) ![]ChunkState {
    const thread_count = try std.Thread.getCpuCount() - 1;

    var tp: std.Thread.Pool = undefined;
    try tp.init(.{ .allocator = std.heap.c_allocator });
    var wg = std.Thread.WaitGroup{};

    var t = try std.time.Timer.start();
    const chunks = try get_chunks(thread_count, buffer, buffer_length);

    std.debug.print("get {} chunks: {}\n", .{ thread_count, std.fmt.fmtDuration(t.read()) });

    for (chunks, 0..) |c, i| {
        _ = c;
        wg.start();
        try tp.spawn(process_chunk, .{ chunks, i, &wg });
    }

    t = try std.time.Timer.start();
    std.debug.print("processign chunks...\n", .{});
    tp.waitAndWork(&wg);
    std.debug.print("Finished processing chunks. ({})\n", .{std.fmt.fmtDuration(t.read())});

    t = try std.time.Timer.start();
    var cities = std.ArrayList([]const u8).init(std.heap.c_allocator);
    var readings = std.StringHashMap(Stats).init(std.heap.c_allocator);

    var it = chunks[0].cities.iterator();
    while (it.next()) |c| {
        try cities.append(c.key_ptr.*);
        try readings.put(c.key_ptr.*, Stats{ .min = 1000, .max = -1000, .sum = 0, .cnt = 0 });
    }
    std.debug.print("init readings : {}\n", .{std.fmt.fmtDuration(t.read())});
    // 200 ms for sort...
    t = try std.time.Timer.start();
    std.mem.sortUnstable([]const u8, cities.items, {}, lt);
    std.debug.print("sort : {}\n", .{std.fmt.fmtDuration(t.read())});

    t = try std.time.Timer.start();

    for (chunks) |cs| {
        var cit = cs.cities.iterator();
        while (cit.next()) |c| {
            var curr = if (readings.get(c.key_ptr.*)) |v| v else Stats{};
            const stats = c.value_ptr.get_stats();
            curr.min = @min(curr.min, stats.min);
            curr.max = @max(curr.max, stats.max);
            curr.cnt += stats.cnt;
            curr.sum += stats.sum;
            try readings.put(c.key_ptr.*, curr);
        }
    }
    std.debug.print("cumul : {}\n", .{std.fmt.fmtDuration(t.read())});

    t = try std.time.Timer.start();
    for (cities.items, 0..) |c, i| {
        const stat = readings.get(c).?;
        const avg = stat.sum / stat.cnt;
        std.debug.print("{} {s} = {d:.1} {d:.1} {d:.1}\n", .{ i, c, stat.min, avg, stat.max });
        if (i + 1 != cities.items.len) std.debug.print(", ", .{});
    }
    std.debug.print("}}\n", .{});

    // 3 ms
    std.debug.print("print : {}\n", .{std.fmt.fmtDuration(t.read())});

    return chunks;
}

fn process_chunk(
    chunk_states: []ChunkState,
    chunk_index: usize,
    wg: *std.Thread.WaitGroup,
) void {
    var time = std.time.Timer.start() catch unreachable;

    defer {
        wg.finish();
        std.debug.print("T{}: {}\n", .{ chunk_index, std.fmt.fmtDuration(time.read()) });
    }

    var local_state = try ChunkState.init(chunk_states[chunk_index].chunk, std.heap.c_allocator);

    var chunk = local_state.chunk;
    var pos: usize = 0;
    while (pos < local_state.chunk.len) {
        const comma = std.mem.indexOfScalarPos(u8, chunk, pos, ',') orelse break;
        const city = chunk[pos..comma];
        pos = comma + 1;

        const t = Parser.parseTemp(chunk, &pos);

        const c = local_state.cities.getOrPut(city) catch unreachable;
        if (c.found_existing) {
            //std.debug.print("T {} / init city {s}\n", .{ chunk_index, city });
            var s = c.value_ptr;
            s.add(t);
        } else {
            c.value_ptr.* = CityWorkingSet{ .stats = .{ .min = t, .max = t, .sum = t, .cnt = 1 } };
        }
    }

    // report back
    chunk_states[chunk_index] = local_state;
}

inline fn get_chunks(count: usize, buffer: []const u8, buffer_length: u64) ![]ChunkState {
    const approx_chunk_size = buffer_length / count;
    var chunk_states = try std.heap.c_allocator.alloc(ChunkState, count);

    var offset: usize = 0;

    for (0..count) |i| {
        var next_offset = approx_chunk_size * (i + 1);
        while (buffer.len > next_offset and buffer[next_offset] != '\n') {
            next_offset += 1;
        }

        if (buffer.len > next_offset) {
            next_offset += 1;
        }

        chunk_states[i] = try ChunkState.init(buffer[offset..next_offset], std.heap.c_allocator);
        offset = next_offset;
    }

    return chunk_states;
}

fn lt(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.order(u8, a, b) == std.math.Order.lt;
}
