const std = @import("std");
const time = std.time;

const parseInt = std.fmt.parseInt;
const haversine = @import("haversine.zig").referenceHaversine;

const generate = @import("generator.zig").generate;
const parse = @import("parser.zig").parse;

const help_text =
    \\ Usage: haversive [command] [options]
    \\ Commands:
    \\
    \\   generate num_points
    \\   parse file_path
    \\
;

pub fn main() !void {
    // Parse CLI args
    const args = std.os.argv;
    if (args.len < 3) {
        return try std.io.getStdOut().writeAll(help_text);
    }

    const command = std.mem.sliceTo(args[1], 0);

    if (std.mem.eql(u8, command, "generate")) {
        const num_pairs = try parseInt(u64, std.mem.sliceTo(args[2], 0), 10);
        const seed = if (args.len >= 4) try parseInt(u64, std.mem.sliceTo(args[3], 0), 10) else 0;
        try generate(num_pairs, seed);
    } else if (std.mem.eql(u8, command, "parse")) {
        try parse(std.mem.sliceTo(args[2], 0));
    } else {
        return try std.io.getStdOut().writeAll(help_text);
    }
}
