import std.stdio;
import types, utils;

MetaData readMetaData(File f)
{
    MetaData data;
    f.rawRead(data.Signature);
    f.read(data.MajorVersion);
    f.read(data.MinorVersion);
    f.read(data.Reserved);
    f.read(data.Length);

    data.Version.length = data.Length;
    data.Padding.length = data.Length%4;
    f.rawRead(data.Version);
    if (data.Padding.length > 0) {
        f.rawRead(data.Padding);
    }
    
    f.read(data.Flags);
    f.read(data.Streams);

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