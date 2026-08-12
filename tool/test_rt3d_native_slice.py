#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import struct

from verify_rt3d_native_slice import GLB, parse_glb


def expect_failure(data: bytes, needle: str) -> None:
    try:
        parse_glb(data)
    except AssertionError as error:
        if needle not in str(error):
            raise AssertionError(f'expected {needle!r}; got {error!r}') from error
        return
    raise AssertionError(f'expected validation failure containing {needle!r}')


def main() -> None:
    data = GLB.read_bytes()
    document = parse_glb(data)
    assert document['asset']['version'] == '2.0'

    bad_magic = b'BAD!' + data[4:]
    expect_failure(bad_magic, 'GLB magic')

    bad_version = bytearray(data)
    struct.pack_into('<I', bad_version, 4, 1)
    expect_failure(bytes(bad_version), 'GLB version')

    bad_length = bytearray(data)
    struct.pack_into('<I', bad_length, 8, len(data) + 4)
    expect_failure(bytes(bad_length), 'header length')

    print('RT3D NATIVE GLB VALIDATOR MUTATION TESTS PASSED')


if __name__ == '__main__':
    main()
