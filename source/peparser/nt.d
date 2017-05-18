import std.stdio;

import types;
import utils;

/// NTHeaderを読む
NTHeader readNTHeader(File f)
{
    NTHeader header;
    auto fp = f.getFP;

    f.rawRead((&(header.Signature))[0..1]);
    f.rawRead((&(header.FileHeader))[0..1]);

    header.read_image_optional_header(f);
    return header;
}
/// NT Header
struct NTHeader
{
    char[4] Signature;
    IMAGE_FILE_HEADER FileHeader;

    IMAGE_OPTIONAL_HEADER32 OptionalHeader32;
    IMAGE_OPTIONAL_HEADER64 OptionalHeader64;

    WORD Magic;

    void read_image_optional_header(File f)
    {
        auto p = f.tell;
        
        f.rawRead((&Magic)[0..1]);
        f.seek(p);

        if (Magic == 0x10b) {
            read_image_optional_header32(f);
        }
        else if(Magic == 0x20b) {
            read_image_optional_header64(f);
        }
        // error
    }
    void read_image_optional_header32(File f)
    {
        auto size = calcStructSize(OptionalHeader32, [__traits(identifier, OptionalHeader32.DataDirectory)]);

        fread(&OptionalHeader32, size, 1, f.getFP);

        OptionalHeader32.DataDirectory.length = OptionalHeader32.NumberOfRvaAndSizes;
        f.rawRead(OptionalHeader32.DataDirectory);
    }
    void read_image_optional_header64(File f) {
        auto size = calcStructSize(OptionalHeader64, [__traits(identifier, OptionalHeader64.DataDirectory)]);
        
        fread(&OptionalHeader64, size, 1, f.getFP);

        OptionalHeader64.DataDirectory.length = OptionalHeader64.NumberOfRvaAndSizes;
        f.rawRead(OptionalHeader64.DataDirectory);
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

    IMAGE_DATA_DIRECTORY[] DataDirectory;
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
    IMAGE_DATA_DIRECTORY[] DataDirectory;
}

struct IMAGE_DATA_DIRECTORY
{
    DWORD VirtualAddress;
    DWORD Size;
}