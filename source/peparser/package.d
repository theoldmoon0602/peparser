module peparser;

import std.stdio;

public import types, utils, msdos, nt, sectionheader, cor20,
 resourcessection, streamheader, metadata, tildaStream, manifestResource;

PE readPE(File f)
{
    PE pe;
    with (pe) {
        dosHeader = readDOSHeader(f);

        f.seek(dosHeader.e_lfanew);
        ntHeader = readNTHeader(f);

        sectionHeaders = readSectionHeaders(f, ntHeader.FileHeader.NumberOfSections);

        cor20 = readCOR20HEADER(f, ntHeader, sectionHeaders);

        f.seek(cor20.MetaData.physicalAddr(sectionHeaders));
        auto addr = f.tell;        
        metaData = readMetaData(f);
        

        streamHeaders = f.readStreamHeaders(metaData.Streams);
        StreamHeader tildaStreamHeader;
        foreach(header;streamHeaders) {
            if (header.Name[1] == '~' || header.Name[1] == '-') {
                tildaStreamHeader = header;
            }
        }
        if (tildaStreamHeader.Name.length == 0) {
            throw new Exception("Failed to read #~ stream offset");
        }

        f.seek(addr + tildaStreamHeader.Offset);
        tildaStream = f.readTildaStream;
        
        // ManifestResourceのテーブルまでskip
        foreach(i;0..40) {
            f.seek(f.tell + tildaStream.tableSize(i));
        }

        foreach(i;0..tildaStream.Rows[40]) {
            manifestResources ~= f.readManifestResource;
        }
        foreach(res;manifestResources) {
            f.seek(cor20.Resources.physicalAddr(sectionHeaders) + 4 + res.Offset); // なぜか +4 しないといけなくて敗北        
            auto resourcesHeader = f.readResourcesHeader;
            resources ~= f.readResources(resourcesHeader);
        }
    }

    return pe;
}

struct PE
{
    DOSHeader dosHeader;
    NTHeader ntHeader;
    SectionHeader[] sectionHeaders;
    IMAGE_COR20_HEADER cor20;
    MetaData metaData;
    StreamHeader[] streamHeaders;
    TildaStream tildaStream;
    ManifestResource[] manifestResources;
    Resource[] resources;
}