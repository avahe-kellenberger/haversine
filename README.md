# Computer, Enhance! Haversine Homework

## Usage

Build:

```sh
$ zig build -Dno-bin=false -freference-trace --release=fast
```

Generate points (1337 here is a SEED):

```sh
$ ./zig-out/bin/haversine generate 10_000_000 1337
```

Process points.json

```sh
$ ./zig-out/bin/haversine parse points.json
```

