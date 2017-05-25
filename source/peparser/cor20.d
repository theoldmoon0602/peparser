import std.stdio;

import types, nt, sectionheader, utils;

IMAGE_COR20_HEADER readCOR20HEADER(File f, NTHeader ntheader, SectionHeader[] headers)
{
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





