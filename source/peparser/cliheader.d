import std.stdio, std.conv, std.algorithm, std.array, std.utf;

import types, nt, sectionheader, utils;

IMAGE_COR20_HEADER readCOR20HEADER(File f, NTHeader ntheader, SectionHeader[] headers)
{
    auto p = f.tell;
    scope(exit) f.seek(p);

    auto addr = ntheader.imageDataDirectories[14].physicalAddr(headers);
	
    IMAGE_COR20_HEADER header;

    f.seek(addr);
    f.rawRead((&header)[0..1]);

    return header;
}

struct IMAGE_COR20_HEADER
{
    union EntryPointT {
        DWORD               EntryPointToken;
        DWORD               EntryPointRVA;
    };

    DWORD                   cb;              
    WORD                    MajorRuntimeVersion;
    WORD                    MinorRuntimeVersion;
    IMAGE_DATA_DIRECTORY    MetaData;        
    DWORD                   Flags;           

    EntryPointT EntryPoint;
    IMAGE_DATA_DIRECTORY    Resources;
    IMAGE_DATA_DIRECTORY    StrongNameSignature;
    IMAGE_DATA_DIRECTORY    CodeManagerTable;
    IMAGE_DATA_DIRECTORY    VTableFixups;
    IMAGE_DATA_DIRECTORY    ExportAddressTableJumps;
    IMAGE_DATA_DIRECTORY    ManagedNativeHeader;
}

MetaData readMetaData(File f)
{
    MetaData data;
    f.rawRead(data.Signature);
    f.rawRead((&(data.MajorVersion))[0..1]);
    f.rawRead((&(data.MinorVersion))[0..1]);
    f.rawRead((&(data.Reserved))[0..1]);
    f.rawRead((&(data.Length))[0..1]);
    data.Version.length = data.Length;
    data.Padding.length = data.Length%4;
    f.rawRead(data.Version);
    if (data.Padding.length > 0) {
        f.rawRead(data.Padding);
    }
    f.rawRead((&(data.Flags))[0..1]);
    f.rawRead((&(data.Streams))[0..1]);

    return data;
}

struct MetaData
{
    char[4] Signature;
    WORD MajorVersion;
    WORD MinorVersion;
    DWORD Reserved;
    DWORD Length;
    char[] Version;
    BYTE[] Padding;
    WORD Flags;
    WORD Streams;
}

StreamHeader readStreamHeader(File f)
{
    StreamHeader header;
    f.rawRead((&(header.Offset))[0..1]);
    f.rawRead((&(header.Size))[0..1]);
    while (true) {
        char[4] buf;
        f.rawRead(buf);
        header.Name ~= buf;
        if (buf[3] == '\0') {
            break;
        }
    }
    return header;
}

StreamHeader[] readStreamHeaders(File f, int numOfStreams)
{
    StreamHeader[] headers;
    headers.reserve(numOfStreams);

    foreach(i;0..numOfStreams)
    {
        headers ~= readStreamHeader(f);
    }
    return headers;
}

struct StreamHeader
{
    DWORD Offset;
    DWORD Size;
    char[] Name;
}


DotResources readDotResources(File f)
{
    f.seek(f.tell + 4); // なぜか必要
    auto addr = f.tell;

    DotResources head;
    f.rawRead(head.Signature);
    f.rawRead((&head.ReaderCount)[0..1]);
    f.rawRead((&head.ReaderTypeLength)[0..1]);
    head.ReaderType.length=head.ReaderTypeLength;
    f.rawRead(head.ReaderType);
    f.rawRead((&head.Version)[0..1]);
    f.rawRead((&head.ResourceCount)[0..1]);
    f.rawRead((&head.ResourceTypeCount)[0..1]);

    foreach(i;0..head.ResourceTypeCount) {
        head.ResourceTypes ~= f.readBlob.toChars;
    }

    while(f.tell%8!=0) {
        f.seek(f.tell+1);
    }

    auto skips = DWORD.sizeof * head.ResourceCount;
    f.seek(f.tell+skips); // hashes
    
    foreach(i;0..head.ResourceCount) {
        head.ResourceNameOffsets ~= f.readDWORD;
    }
    head.DataSectionOffset = f.readDWORD;


    auto base = f.tell;
    foreach(i;0..head.ResourceCount) {
        f.seek(base+head.ResourceNameOffsets[i]);
        ResourceInfo info;
        wstring a = f.readString.toUTF16;
        writeln(a);
        info.Name = a.to!string.dup;
        info.Offset = f.readDWORD;

        head.ResourceInfos ~= info;
    }

    head.PhysicalOffset = addr + head.DataSectionOffset;

    return head;
}

struct ResourceInfo
{
    char[] Name;
    DWORD Offset;
}

struct DotResources
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
    ULONGLONG PhysicalOffset;
    ResourceInfo[] ResourceInfos;
}





DWORD readDWORD(File f) {
    DWORD[1] buf;
    f.rawRead(buf);
    return buf[0];
}



struct Resource
{
    char[] Name;
    char[] Value;
}

Resource[] readResources(File f, DotResources dot)
{
    auto addr = dot.PhysicalOffset;
    Resource[] resources;

    foreach(info;dot.ResourceInfos) {
        f.seek(addr + info.Offset);
        auto v = f.read7BitEncodedInteger;
        auto l = f.read7BitEncodedInteger;

        Resource res;
        res.Name = info.Name;
        res.Value.length = cast(uint)l;
        f.rawRead(res.Value);
        resources ~= res;
    }
    return resources;

}
