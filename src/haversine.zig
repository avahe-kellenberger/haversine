const std = @import("std");
const sin = std.math.sin;
const cos = std.math.cos;
const asin = std.math.asin;

const earth_radius = 6372.8;

fn degreesToRadians(degrees: f64) f64 {
    return 0.01745329251994329577 * degrees;
}

fn square(x: f64) f64 {
    return x * x;
}

pub fn referenceHaversine(x0: f64, y0: f64, x1: f64, y1: f64) f64 {
    const d_lat = degreesToRadians(y1 - y0);
    const d_lon = degreesToRadians(x1 - x0);

    const lat_1 = degreesToRadians(y0);
    const lat_2 = degreesToRadians(y1);

    const a: f64 = square(sin(d_lat / 2.0)) + cos(lat_1) * cos(lat_2) * square(sin(d_lon / 2.0));
    const c: f64 = 2.0 * asin(std.math.sqrt(a));

    return earth_radius * c;
}
