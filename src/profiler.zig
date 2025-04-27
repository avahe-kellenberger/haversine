const std = @import("std");
const cpu = @import("cpu.zig");

const stdout = std.io.getStdOut().writer();

fn print(comptime format: []const u8, args: anytype) void {
    stdout.print(format, args) catch {};
}

inline fn float(i: u64) f64 {
    return @as(f64, @floatFromInt(i));
}

const Anchor = struct {
    pub const Self = @This();
    // Start
    tsc_start: u64 = 0,
    // Elapsed
    tsc_elapsed: u64 = 0,
    page_faults: u64 = 0,
    processed_byte_count: u64 = 0,
    label: []const u8 = "",

    fn print_info(self: *Self, total_cpu_elapsed: u64, timer_freq: u64) void {
        const percent: f64 = 100.0 * float(self.tsc_elapsed) / float(total_cpu_elapsed);
        const ms = 1000.0 * float(self.tsc_elapsed) / float(timer_freq);
        print("\n  {s}: {d:.2}ms - {} ({d:.2}%)", .{ self.label, ms, self.tsc_elapsed, percent });

        if (self.processed_byte_count > 0) {
            const megabyte: f64 = 1024.0 * 1024.0;
            const gigabyte: f64 = megabyte * 1024.0;

            const seconds: f64 = float(self.tsc_elapsed) / float(timer_freq);
            const bytes_per_sec = float(self.processed_byte_count) / seconds;
            const megabytes = float(self.processed_byte_count) / megabyte;
            const gigabytes_per_sec = bytes_per_sec / gigabyte;

            print("\n  {d:.4} MB at {d:.4} GB/s", .{ megabytes, gigabytes_per_sec });
        }

        if (self.page_faults > 0) {
            const processed_kb = float(self.processed_byte_count) / 1000.0;
            const kb_per_fault: f64 = processed_kb / float(self.page_faults);
            print("\n  Page faults: {} ({d:.2}k per fault)", .{ self.page_faults, kb_per_fault });
        }

        print("\n", .{});
    }
};

pub const Profiler = struct {
    pub const Self = @This();

    tsc_start: u64 = 0,
    tsc_end: u64 = 0,
    page_faults: u64 = 0,
    anchors: [4096]Anchor = undefined,
    next_anchor_index: u64 = 0,

    pub fn init() Self {
        return .{};
    }

    /// Starts the profiler timer.
    pub fn start(self: *Self) void {
        self.tsc_start = cpu.readCpuTimer();
    }

    /// Starts profiling a block of a code.
    /// Returns the block id.
    pub fn start_block(self: *Self, label: []const u8) u64 {
        var anchor = &self.anchors[self.next_anchor_index];
        anchor.label = label;
        anchor.tsc_start = cpu.readCpuTimer();
        anchor.page_faults = cpu.readOsPageFaultCount();
        defer self.next_anchor_index += 1;
        return self.next_anchor_index;
    }

    pub fn stop_block(self: *Self, block_id: u64, processed_byte_count: u64) void {
        var anchor = &self.anchors[block_id];
        anchor.tsc_elapsed = cpu.readCpuTimer() - anchor.tsc_start;
        anchor.page_faults = cpu.readOsPageFaultCount() - anchor.page_faults;
        anchor.processed_byte_count = processed_byte_count;
    }

    /// Stops the profiler timer, and prints all block information.
    pub fn stop_and_print(self: *Self) void {
        self.tsc_end = cpu.readCpuTimer();
        const elapsed = self.tsc_end - self.tsc_start;
        const timer_freq = cpu.estimate_cpu_timer_freq();
        print("\nTotal: {d}ms - {} (timer freq {})\n", .{
            1000.0 * float(elapsed) / float(timer_freq),
            elapsed,
            timer_freq,
        });

        self.print_blocks(elapsed, timer_freq);
    }

    fn print_blocks(self: *Self, total_cpu_elapsed: u64, timer_freq: u64) void {
        for (0..self.next_anchor_index) |i| {
            var anchor = &self.anchors[i];
            if (anchor.tsc_elapsed == 0) break;
            anchor.print_info(total_cpu_elapsed, timer_freq);
        }
    }
};

test {
    var profiler = Profiler.init();

    profiler.start();

    const id = profiler.start_block("Test");
    for (0..100_000_000) |_| {}
    profiler.stop_block(id, 1_000_000);

    profiler.stop_and_print();
}
