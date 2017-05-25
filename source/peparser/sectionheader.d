import std.stdio, std.conv, std.algorithm, std.ascii;

import types;

struct SectionHeader
{
    union MiscT {
        DWORD PhysicalAddress;
        DWORD VirtualSize;
    }
    char[8]  Name;
    MiscT Misc;
    DWORD VirtualAddress;
    DWORD SizeOfRawData;
    DWORD PointerToRawData;
    DWORD PointerToRelocations;
    DWORD PointerToLinenumbers;
    WORD  NumberOfRelocations;
    WORD  NumberOfLinenumbers;
    DWORD Characteristics;

    string toString() {
        return "SectionHeader<" ~ Name.to!string ~ ">" ~ PointerToRawData.to!string ~ flagStrings.to!string;
    }
    bool isExecutable() {
        DWORD IMAGE_SCN_MEM_EXECUTE=0x20000000;
        return (Characteristics&IMAGE_SCN_MEM_EXECUTE) != 0;
    }
    bool isReadable() {
        DWORD IMAGE_SCN_MEM_READ=0x40000000;
        return (Characteristics&IMAGE_SCN_MEM_READ) != 0;
    }
    bool isWritable() {
        DWORD IMAGE_SCN_MEM_WRITE=0x60000000;
        return (Characteristics&IMAGE_SCN_MEM_WRITE) != 0;
    }
    bool isInitialized() {
        DWORD IMAGE_SCN_CNT_INITIALIZED_DATA=0x00000040;
        return (Characteristics&IMAGE_SCN_CNT_INITIALIZED_DATA) != 0;
    }
    bool isUninitialized() {
        DWORD IMAGE_SCN_CNT_UNINITIALIZED_DATA=0x00000080;
        return (Characteristics&IMAGE_SCN_CNT_UNINITIALIZED_DATA) != 0;
    }
    string[] flagStrings() {
        string[] flags;
        if (isExecutable) {
            flags ~= "EXECUTE";
        }
        if (isReadable) {
            flags ~= "READ";
        }
        if (isWritable) {
            flags ~= "WRITE";
        }
        if (isInitialized) {
            flags ~= "Initialized";
        }
        if (isUninitialized) {
            flags ~= "UNinitialized";
        } 
        return flags;
    }
}

SectionHeader readSectionHeader(File f)
{
    SectionHeader header;
    f.rawRead((&header)[0..1]);
    return header;
}

SectionHeader[] readSectionHeaders(File f, WORD numberOfSections)
{
    SectionHeader[] headers;
    headers.reserve(numberOfSections);
    foreach(i; 0..numberOfSections)
    {
        headers ~= readSectionHeader(f);
    }
    return headers;
}

class SectionData{
    BYTE[] values;
    alias values this;

    override string toString() {
        return values.map!(function(a) {
            if ((cast(dchar)a).isPrintable) {
                return a.to!char;
            }
            return '.';
        }).to!string;
    }
}

SectionData readSectionData(File f, SectionHeader header)
{
    SectionData code = new SectionData;
    code.length = header.SizeOfRawData;
    f.seek(header.PointerToRawData);
    f.rawRead(code);

    return code;
}

SectionData[] readSectionDatas(File f, SectionHeader[] headers)
{
    SectionData[] codes;
    codes.reserve(headers.length);

    foreach (h; headers)
    {
        codes ~= readSectionData(f, h);
    }

    return codes;
}