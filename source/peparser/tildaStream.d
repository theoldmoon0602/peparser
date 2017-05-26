import std.stdio, core.bitop;

import types, utils;

TildaStream readTildaStream(File f) {
    TildaStream stream;

    with (stream) {
        f.read(Reserved);
        f.read(MajorVersion);
        f.read(MinorVersion);
        f.read(HeapSizes);
        f.read(Reserved2);
        f.read(Valid);
        f.read(Sorted);

        for(auto i = 0; i < RowSizes.length; i++) {
            if (hasTable(i)) {
                Rows ~= f.readDWORD;
            }
            else {
                Rows ~= 0;
            }
        }
    }

    return stream;
}

struct TildaStream
{  
    enum RowSizes = [10,6,14,2,6,2,14,2,6,4,6,6,6,4,6,8,6,2,4,2,6,4,2,6,6,6,2,2,8,6,8,4,22,4,12,20,6,14,8,14,12,4];

    DWORD Reserved;
    BYTE MajorVersion;
    BYTE MinorVersion;
    BYTE HeapSizes;
    BYTE Reserved2;
    UINT64 Valid;
    UINT64 Sorted;
    DWORD[] Rows;

    bool hasTable(int i) {
        return (Valid & (1UL << i)) != 0;
    }
    DWORD tableSize(int i) {
        return Rows[i] * RowSizes[i];
    }
}