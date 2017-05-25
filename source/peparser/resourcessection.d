import std.stdio, std.utf, std.conv;

import types, utils;

ResourcesHeader readResourcesHeader(File f)
{
    auto addr = f.tell;

    RESOURCES_SECTION resource;
    f.rawRead(resource.Signature);
    f.read(resource.ReaderCount);
    f.read(resource.ReaderTypeLength);

    resource.ReaderType.length=resource.ReaderTypeLength;
    f.rawRead(resource.ReaderType);
    f.read(resource.Version);
    f.read(resource.ResourceCount);
    f.read(resource.ResourceTypeCount);

    writeln(resource.ReaderType);


    foreach(i;0..resource.ResourceTypeCount) {
        resource.ResourceTypes ~= f.readBlob.toChars;
    }

    // 8byteパディング
    while (true) {
        while(f.tell%4!=0) {
            f.seek(f.tell+1);
        }
        {
            auto p = f.tell;
            auto c = cast(char)f.readBYTE;
            if (!(c == 'P' || c == 'A' || c=='D')) {
                f.seek(p);
                break;
            }
        }
    }

    // ハッシュは飛ばすことにした
    auto skips = DWORD.sizeof * resource.ResourceCount;
    f.seek(f.tell+skips); 
    
    foreach(i;0..resource.ResourceCount) {
        resource.ResourceNameOffsets ~= f.readDWORD;
    }
    f.read(resource.DataSectionOffset);

    auto base = f.tell;
    ResourceInfo[] resourceInfos;
    foreach(i;0..resource.ResourceCount) {
        f.seek(base+resource.ResourceNameOffsets[i]);

        // utf16の文字列を読んでchar[]に変換する
        ResourceInfo info;
        wstring a = f.readString.toUTF16;
        info.Name = a.to!string.dup;
        f.read(info.Offset);

        resourceInfos ~= info;
    }

    auto physicalAddr = addr + resource.DataSectionOffset;

    return new ResourcesHeader(resource, physicalAddr, resourceInfos);
}

struct ResourceInfo
{
    char[] Name;
    DWORD Offset;
}

class ResourcesHeader
{
    RESOURCES_SECTION
 resource;
    UINT64 physicalAddr;
    ResourceInfo[] ResourceInfos;

    this(RESOURCES_SECTION
 resource, UINT64 physicalAddr, ResourceInfo[] resourceInfos) {
        this.resource = resource;
        this.physicalAddr = physicalAddr;
        this.ResourceInfos = resourceInfos;
    }

    alias resource this;
}

struct RESOURCES_SECTION
{
    char[4] Signature;
    DWORD ReaderCount;
    DWORD ReaderTypeLength;
    char[] ReaderType;
    DWORD Version;
    DWORD ResourceCount;
    DWORD ResourceTypeCount;
    char[][] ResourceTypes;
    DWORD[] ResourceNameOffsets;
    DWORD DataSectionOffset;
}

struct Resource
{
    char[] Name;
    char[] Value;
}

Resource[] readResources(File f, ResourcesHeader h)
{
    auto addr = h.physicalAddr;
    Resource[] resources;

    foreach(info;h.ResourceInfos) {
        f.seek(addr + info.Offset);
        auto t = f.read7BitEncodedInteger; // リソースタイプ？
        auto l = f.read7BitEncodedInteger;

        Resource res;
        res.Name = info.Name;
        res.Value.length = cast(uint)l;
        f.rawRead(res.Value);
        resources ~= res;
    }
    return resources;

}
