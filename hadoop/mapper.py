import os
import sys
import os.path as osp

def main():
    fname = (os.environ.get("mapreduce_map_input_file") or os.environ.get("map_input_file") or "unknown")

    prefix = "/input/repo/"
    i = fname.find(prefix)
    if i != -1:
        name = fname[i + len(prefix):]
    else:
        name = osp.basename(fname)

    for _ in sys.stdin:
        print(f"\"{name}\"\t1")

if __name__ == "__main__":
    main()