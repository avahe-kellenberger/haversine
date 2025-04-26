const std = @import("std");
const parseFloat = std.fmt.parseFloat;
const referenceHaversine = @import("haversine.zig").referenceHaversine;
const Profiler = @import("profiler.zig").Profiler;

const stdout = std.io.getStdOut().writer();

var profiler = Profiler.init();

pub fn parse(file_path: []const u8) !void {
    profiler.start();
    defer profiler.stop_and_print();

    const prof_read_id = profiler.start_block("Read file");

    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const stat = try file.stat();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const file_contents = try file.readToEndAllocOptions(
        alloc,
        stat.size,
        stat.size / (6 * 4),
        @alignOf(u8),
        null,
    );

    defer alloc.free(file_contents);

    profiler.stop_block(prof_read_id, stat.size);

    const prof_process_id = profiler.start_block("Process and sum");

    var line_num: usize = 0;
    var sum: f64 = 0.0;
    var iter = std.mem.splitScalar(u8, file_contents, '\n');
    while (iter.next()) |line| {
        defer line_num += 1;

        // First line
        if (line_num == 0) continue;

        // Last line
        if (line[0] == ']') break;

        const dist = try parseLine(line);
        sum += dist;
    }

    profiler.stop_block(prof_process_id, stat.size);

    const prof_print_id = profiler.start_block("Print info");
    const pair_count = line_num - 2;
    try stdout.print("Total lines: {}\n", .{line_num});
    try stdout.print("Pair count: {}\n", .{pair_count});
    try stdout.print("Haversine sum: {d}\n", .{sum / @as(f64, @floatFromInt(pair_count))});
    profiler.stop_block(prof_print_id, 0);
}

const Range = struct {
    start: u64 = 0,
    end: u64 = 0,
};

fn parseLine(line: []const u8) !f64 {
    var x0: f64 = undefined;
    var x1: f64 = undefined;
    var y0: f64 = undefined;
    var y1: f64 = undefined;

    var pos: u64 = 0;
    var range: Range = undefined;

    {
        range = findValueRange(line, pos);
        x0 = try parseFloat(f64, line[range.start..range.end]);
        pos = range.end + 1;
    }

    {
        range = findValueRange(line, pos);
        y0 = try parseFloat(f64, line[range.start..range.end]);
        pos = range.end + 1;
    }

    {
        range = findValueRange(line, pos);
        x1 = try parseFloat(f64, line[range.start..range.end]);
        pos = range.end + 1;
    }

    {
        range = findValueRange(line, pos);
        y1 = try parseFloat(f64, line[range.start..range.end]);
        pos = range.end + 1;
    }

    return referenceHaversine(x0, y0, x1, y1);
}

fn findValueRange(line: []const u8, start: u64) Range {
    var result: Range = .{};
    for (start..line.len) |i| {
        switch (line[i]) {
            ':' => result.start = i + 1,
            ',', '}' => {
                result.end = i;
                break;
            },
            else => continue,
        }
    }

    if (result.end == 0) std.debug.panic("Failed to find value range at pos {}:\n{s}", .{ start, line });
    return result;
}
