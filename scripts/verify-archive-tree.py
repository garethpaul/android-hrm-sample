#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import os
import stat
import subprocess
import sys
from pathlib import Path


ERROR = "Archive contents do not exactly match the reviewed Git tree."


def fail() -> None:
    print(ERROR, file=sys.stderr)
    raise SystemExit(1)


def git(repository: Path, *arguments: str) -> bytes:
    return subprocess.check_output(
        ["/usr/bin/git", "-C", str(repository), *arguments],
        stderr=subprocess.DEVNULL,
    )


def blob_id(data: bytes, object_format: str) -> str:
    digest = hashlib.new(object_format)
    digest.update(f"blob {len(data)}\0".encode())
    digest.update(data)
    return digest.hexdigest()


def expected_entries(repository: Path, commit: str) -> dict[str, tuple[str, str]]:
    entries: dict[str, tuple[str, str]] = {}
    output = git(repository, "ls-tree", "-r", "-z", commit)
    for record in output.split(b"\0"):
        if not record:
            continue
        metadata, raw_path = record.split(b"\t", 1)
        mode, object_type, object_id = metadata.decode("ascii").split(" ")
        if object_type != "blob":
            fail()
        path = os.fsdecode(raw_path)
        if path.startswith("/") or ".." in Path(path).parts or path in entries:
            fail()
        entries[path] = (mode, object_id)
    return entries


def actual_entries(root: Path, object_format: str) -> dict[str, tuple[str, str]]:
    entries: dict[str, tuple[str, str]] = {}
    for directory, names, filenames in os.walk(root, topdown=True, followlinks=False):
        directory_path = Path(directory)
        for name in list(names):
            path = directory_path / name
            if path.is_symlink():
                names.remove(name)
                filenames.append(name)
        for name in filenames:
            path = directory_path / name
            relative = os.fsdecode(os.path.relpath(path, root))
            metadata = path.lstat()
            if stat.S_ISLNK(metadata.st_mode):
                mode = "120000"
                data = os.fsencode(os.readlink(path))
            elif stat.S_ISREG(metadata.st_mode):
                mode = "100755" if metadata.st_mode & stat.S_IXUSR else "100644"
                data = path.read_bytes()
            else:
                fail()
            entries[relative] = (mode, blob_id(data, object_format))
    return entries


def main() -> None:
    if len(sys.argv) != 4:
        fail()
    repository = Path(sys.argv[1]).resolve(strict=True)
    commit = sys.argv[2]
    extracted = Path(sys.argv[3]).resolve(strict=True)
    object_format = git(repository, "rev-parse", "--show-object-format").decode().strip()
    if object_format not in {"sha1", "sha256"}:
        fail()
    if expected_entries(repository, commit) != actual_entries(extracted, object_format):
        fail()
    print("Archive manifest matches the reviewed Git tree.")


if __name__ == "__main__":
    main()
