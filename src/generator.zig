const std = @import("std");
const clamp = std.math.clamp;
const parseInt = std.fmt.parseInt;
const haversine = @import("haversine.zig").referenceHaversine;

const file_name = "points.json";

pub fn generate(num_pairs: u64, seed: u64) !void {
    std.log.info("Generating {} points", .{num_pairs});

    {
        const max_num_pairs = 1 << 34;
        if (num_pairs > max_num_pairs) {
            std.log.warn("Max number of pairs exceeded, using maximum value instead: {}", .{max_num_pairs});
        }
    }

    var prng = std.Random.DefaultPrng.init(seed);
    const rand = prng.random();

    // Create our file
    const file = try std.fs.cwd().createFile(file_name, .{ .read = true });
    defer file.close();

    const writer = file.writer();
    try writer.writeAll("{\"pairs\":[\n");

    const cluster_count_max: u64 = 1 + (num_pairs / 64);
    var cluster_count_left: u64 = 0;

    const max_allowed_x: f64 = 180;
    const max_allowed_y: f64 = 90;

    var x_center: f64 = 0;
    var y_center: f64 = 0;
    var x_radius: f64 = max_allowed_x;
    var y_radius: f64 = max_allowed_y;

    var sum: f64 = 0.0;
    const sum_coef: f64 = 1.0 / @as(f64, @floatFromInt(num_pairs));

    for (0..num_pairs) |i| {
        if (cluster_count_left == 0) {
            cluster_count_left = cluster_count_max;
            x_center = randomInRange(rand, -max_allowed_x, max_allowed_x);
            y_center = randomInRange(rand, -max_allowed_y, max_allowed_y);
            x_radius = randomInRange(rand, 0, max_allowed_x);
            y_radius = randomInRange(rand, 0, max_allowed_y);

            cluster_count_left -= 1;
        }

        const x0 = randomDegree(rand, x_center, x_radius, max_allowed_x);
        const y0 = randomDegree(rand, y_center, y_radius, max_allowed_y);
        const x1 = randomDegree(rand, x_center, x_radius, max_allowed_x);
        const y1 = randomDegree(rand, y_center, y_radius, max_allowed_y);

        const dist = haversine(x0, y0, x1, y1);
        sum += sum_coef * dist;

        const separator = if (i == num_pairs - 1) "\n" else ",\n";

        try std.fmt.format(
            writer,
            "{{\"x0\":{d},\"y0\":{d},\"x1\":{d},\"y1\":{d}}}{s}",
            .{ x0, y0, x1, y1, separator },
        );
    }

    try file.writeAll("]}\n");

    std.log.info("Generated {} points - writing to {s}...", .{ num_pairs, file_name });

    std.log.info("Done.", .{});

    std.log.info("Seed: {}", .{seed});
    std.log.info("Pair count: {}", .{num_pairs});
    std.log.info("Expected sum: {d}", .{sum});
}

fn randomDegree(rand: std.Random, center: f64, radius: f64, max_allowed: f64) f64 {
    return randomInRange(
        rand,
        clamp(center - radius, -max_allowed, max_allowed),
        clamp(center + radius, -max_allowed, max_allowed),
    );
}

fn randomInRange(rand: std.Random, min_val: f64, max_val: f64) f64 {
    const t = @as(f64, @floatFromInt(rand.int(u64))) / @as(f64, @floatFromInt(std.math.maxInt(u64)));
    return (1.0 - t) * min_val + t * max_val;
}
