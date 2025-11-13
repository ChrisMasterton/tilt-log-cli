# tilt-logs

A tiny Rust CLI to read logs from Docker containers created by Tilt.

## Usage

```
tilt-logs api
tilt-logs backend --follow
tilt-logs mongo --tail 200
tilt-logs --list
tilt-logs api --exact
```

- service: partial match against container name by default
- --follow / -f: stream logs
- --tail N: show last N lines
- --list: list container names
- --exact: require exact container name match

## Build

```
cargo build --release
```

The binary will be in `target/release/tilt-logs`.
