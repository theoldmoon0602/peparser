import std.stdio, std.conv, std.algorithm, std.ascii;

import types, utils;


alias readSectionHeader = readT!SectionHeader;

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
    // FLAGが立っているかどうかを表すメソッド（使わない）
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
