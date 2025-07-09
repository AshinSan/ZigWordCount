# zwc - Zig Word Count

This is a small project I made to learn Zig and get comfortable with systems programming.

`zwc` is a CLI utility written in Zig to count the number of **lines**, **words**, **characters** in a text file similar to the UNIX `wc` CLI.

## Usage

```sh
zwc [FILE] [OPTION]
```

You can also pass other outputs instead of passing a file

```sh
echo hello world | zwc
```

## Options

- `-h`, `--help`:    Show help messages.
- `-l`, `--list`:    Show only line count.
- `-w`, `--word`:    Show only word count.
- `-c`, `--char`:    Show only character count.
- `-v`, `--verbose`: Verbose Mode.
- `--version`: Shows current version. 

You can combine options:

`zwc input.txt -lwc` or `zwc input.txt -cw --line` etc.

## Example

```sh
zwc input.txt -l -c
```

## Build

```sh
zig build
```

## License

MIT (See [LICENSE](LICENSE) file)