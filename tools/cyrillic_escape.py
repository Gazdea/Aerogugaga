"""Convert Cyrillic in Lua source files to escaped byte sequences.

Usage:
  python tools/cyrillic_escape.py input.lua [output.lua]
"""

import sys


def escape_cyrillic(text: str) -> str:
    result = []
    for char in text:
        cp = ord(char)
        if 0x0400 <= cp <= 0x04FF:
            utf8_bytes = char.encode("utf-8")
            result.append("".join(f"\\{b}" for b in utf8_bytes))
        else:
            result.append(char)
    return "".join(result)


def main():
    if len(sys.argv) < 2:
        print(__doc__.strip())
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else input_path

    with open(input_path, "r", encoding="utf-8") as f:
        content = f.read()

    escaped = escape_cyrillic(content)

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(escaped)

    print(f"Written to {output_path}")


if __name__ == "__main__":
    main()
