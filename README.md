# zwc - Zig Word Count

a small project I did for learning Zig, and programming in general.

`zwc` is a CLI utility written in Zig to count the number of
**lines**, **words**, **characters** in a text file similar to
the UNIX `wc` CLI.

## Usage

```sh
zwc [FILE] [OPTION]
```

## Options

- `-h`: Show help messages
- `-l`: Show only line count
- `-w`: Show only word count
- `-c`: Show only character count

Tou can combine options:

`zwc input.txt -lwc` or `zwc input.txt -cw` etc.

## Example

```sh
zwc input.txt -l -c
```

## Build

```sh
zig build
```

## License

MIT (See LICENSE file)