import std.stdio;

import types, utils, msdos, nt, sectionheader, cor20, resourcessection;

PE readPE(File f)
{
    PE pe;
    with (pe) {
        dosHeader = readDOSHeader(f);
        f.seek(dosHeader.e_lfanew);
        ntHeader = readNTHeader(f);
        sectionHeaders = readSectionHeaders(f, ntHeader.FileHeader.NumberOfSections);
        cor20 = readCOR20HEADER(f, ntHeader, sectionHeaders);
        f.seek(cor20.Resources.physicalAddr(sectionHeaders) + 4); // なぜか +4 しないといけなくて敗北
        resourcesHeader = readResourcesHeader(f);
        resources = readResources(f, resourcesHeader);
    }

    return pe;
}

struct PE
{
    DOSHeader dosHeader;
    NTHeader ntHeader;
    SectionHeader[] sectionHeaders;
    IMAGE_COR20_HEADER cor20;
    ResourcesHeader resourcesHeader;
    Resource[] resources;
}