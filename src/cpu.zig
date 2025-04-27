const std = @import("std");

const os_timer_freq = 1_000_000;

pub fn readOsTimer() u64 {
    var t: std.posix.timeval = undefined;
    std.posix.gettimeofday(&t, null);
    // Uses microseconds, so we multiply "seconds" by 1 million and add the remaining microseconds.
    // See "man gettimeofday" for more info.
    return os_timer_freq * @as(u64, @intCast(t.sec)) + @as(u64, @intCast(t.usec));
}

/// Uses rdtscp to read the cpu timer.
pub inline fn readCpuTimer() u64 {
    var lo: u32 = 0;
    var hi: u32 = 0;
    asm ("rdtscp"
        : [hi] "={edx}" (hi),
          [lo] "={eax}" (lo),
        :
        : "ecx"
    );
    return (@as(u64, hi) << 32) | lo;
}

pub fn estimate_cpu_timer_freq() u64 {
    const millis_to_wait = 100;

    const cpu_start = readCpuTimer();
    const os_start = readOsTimer();
    const os_wait_time: u64 = os_timer_freq * millis_to_wait / 1000;

    var os_end: u64 = 0;
    var os_elapsed: u64 = 0;

    while (os_elapsed < os_wait_time) {
        os_end = readOsTimer();
        os_elapsed = os_end - os_start;
    }

    const cpu_end = readCpuTimer();
    const cpu_elasped = cpu_end - cpu_start;

    var cpu_freq: u64 = 0;
    if (os_elapsed != 0) {
        cpu_freq = os_timer_freq * cpu_elasped / os_elapsed;
    }
    return cpu_freq;
}

pub fn readOsPageFaultCount() u64 {
    const usage = std.posix.getrusage(std.posix.rusage.SELF);
    return @intCast(usage.minflt + usage.majflt);
}

test {
    std.log.warn("readOsTimer: {}", .{readOsTimer()});
    std.log.warn("readCpuTimer: {}", .{readCpuTimer()});
    std.log.warn("readOsPageFaultCount: {}", .{readOsPageFaultCount()});
}
