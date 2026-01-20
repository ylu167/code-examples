import sys

def flush(key, total):
    if key is not None:
        print(f"{key}\t{total}")

def main():
    current = None
    total = 0

    for raw in sys.stdin:
        line = raw.rstrip("\n")
        if not line:
            continue
        key, val = line.split("\t", 1)
        if key != current:
            flush(current, total)
            current, total = key, 0
        total += int(val)

    flush(current, total)

if __name__ == "__main__":
    main()