import std.stdio, std.conv;

import types;
import sectionheader;
import utils;

/// NTHeaderを読む
NTHeader readNTHeader(File f)
{
    NTHeader header;

    f.read(header.Signature);
    f.read(header.FileHeader);

    header.read_image_optional_header(f);
    return header;
}
/// NT Header
struct NTHeader
{
    enum MAGIC : WORD {
        HDR32=0x10b,
        HDR64=0x20b
    }

    char[4] Signature;
    IMAGE_FILE_HEADER FileHeader;

    IMAGE_OPTIONAL_HEADER32 OptionalHeader32;
    IMAGE_OPTIONAL_HEADER64 OptionalHeader64;

    MAGIC Magic;

    /// 32bitか64bitかがあるのでプロパティにしてる
    @property IMAGE_DATA_DIRECTORY[] imageDataDirectories()
    {
        if (Magic == MAGIC.HDR32) {
            return OptionalHeader32.DataDirectory;
        }
        else {
            return OptionalHeader64.DataDirectory;
        }
    }

    @property ULONGLONG imageBase()
    {
        if (Magic == MAGIC.HDR32) {
            return OptionalHeader32.ImageBase;
        }
        else {
            return OptionalHeader64.ImageBase;
        }
    }

    void read_image_optional_header(File f)
    {
        auto p = f.tell;
        
        f.read(Magic);
        f.seek(p);

        if (Magic == MAGIC.HDR32) {
            f.read(OptionalHeader32);
        }
        else if(Magic == MAGIC.HDR64) {
            f.read(OptionalHeader64);
        }
        throw new Exception("Unknown Maigc Number: " ~ Magic.to!string);
    }
    
}

/// ImageFileHeader structure
struct IMAGE_FILE_HEADER
{
    WORD  Machine;
    WORD  NumberOfSections;
    DWORD TimeDateStamp;
    DWORD PointerToSymbolTable;
    DWORD NumberOfSymbols;
    WORD  SizeOfOptionalHeader;
    WORD  Characteristics;
}

enum int IMAGE_NUMBEROF_DIRECTORY_ENTRIES = 16;
struct IMAGE_OPTIONAL_HEADER32 {


    WORD                 Magic;
    BYTE                 MajorLinkerVersion;
    BYTE                 MinorLinkerVersion;
    DWORD                SizeOfCode;
    DWORD                SizeOfInitializedData;
    DWORD                SizeOfUninitializedData;
    DWORD                AddressOfEntryPoint;
    DWORD                BaseOfCode;
    DWORD                BaseOfData;
    DWORD                ImageBase;
    DWORD                SectionAlignment;
    DWORD                FileAlignment;
    WORD                 MajorOperatingSystemVersion;
    WORD                 MinorOperatingSystemVersion;
    WORD                 MajorImageVersion;
    WORD                 MinorImageVersion;
    WORD                 MajorSubsystemVersion;
    WORD                 MinorSubsystemVersion;
    DWORD                Win32VersionValue;
    DWORD                SizeOfImage;
    DWORD                SizeOfHeaders;
    DWORD                CheckSum;
    WORD                 Subsystem;
    WORD                 DllCharacteristics;
    DWORD                SizeOfStackReserve;
    DWORD                SizeOfStackCommit;
    DWORD                SizeOfHeapReserve;
    DWORD                SizeOfHeapCommit;
    DWORD                LoaderFlags;
    DWORD                NumberOfRvaAndSizes;

    IMAGE_DATA_DIRECTORY[IMAGE_NUMBEROF_DIRECTORY_ENTRIES] DataDirectory;
}

struct IMAGE_OPTIONAL_HEADER64 {
    WORD        Magic;
    BYTE        MajorLinkerVersion;
    BYTE        MinorLinkerVersion;
    DWORD       SizeOfCode;
    DWORD       SizeOfInitializedData;
    DWORD       SizeOfUninitializedData;
    DWORD       AddressOfEntryPoint;
    DWORD       BaseOfCode;
    ULONGLONG   ImageBase;
    DWORD       SectionAlignment;
    DWORD       FileAlignment;
    WORD        MajorOperatingSystemVersion;
    WORD        MinorOperatingSystemVersion;
    WORD        MajorImageVersion;
    WORD        MinorImageVersion;
    WORD        MajorSubsystemVersion;
    WORD        MinorSubsystemVersion;
    DWORD       Win32VersionValue;
    DWORD       SizeOfImage;
    DWORD       SizeOfHeaders;
    DWORD       CheckSum;
    WORD        Subsystem;
    WORD        DllCharacteristics;
    ULONGLONG   SizeOfStackReserve;
    ULONGLONG   SizeOfStackCommit;
    ULONGLONG   SizeOfHeapReserve;
    ULONGLONG   SizeOfHeapCommit;
    DWORD       LoaderFlags;
    DWORD       NumberOfRvaAndSizes;
    IMAGE_DATA_DIRECTORY[IMAGE_NUMBEROF_DIRECTORY_ENTRIES] DataDirectory;
}

struct IMAGE_DATA_DIRECTORY
{
    DWORD VirtualAddress;
    DWORD Size;

    /// VirtualAddress のファイル上での位置を求める
    DWORD physicalAddr(SectionHeader[] sectionHeaders) {
        auto rva = VirtualAddress;
        DWORD addr;
        foreach(section; sectionHeaders) {
		if (section.VirtualAddress <= rva &&
			rva < section.VirtualAddress + section.SizeOfRawData) {
				addr = (rva - section.VirtualAddress) + section.PointerToRawData;
                return addr;
			}
	    }
        throw new Exception("Failed to Find Physical Address of RVA: " ~ rva.to!string);
    }
    DWORD physicalOffset(SectionHeader[] sectionHeaders) {
        auto rva = VirtualAddress;
        DWORD addr;
        foreach(section; sectionHeaders) {
		if (section.VirtualAddress <= rva &&
			rva < section.VirtualAddress + section.SizeOfRawData) {
				return -section.VirtualAddress + section.PointerToRawData;
			}
	    }
        return -1;
    }
}