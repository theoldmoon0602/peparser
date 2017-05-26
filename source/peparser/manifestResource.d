import std.stdio, std.conv;

import types, utils;

alias readManifestResource=readT!ManifestResource;

struct ManifestResource 
{
    DWORD Offset;
    DWORD Flags;
    WORD NameOffset;
    WORD Implementation;

    bool isInternalResource() {
        return Implementation == 0;
    }

}