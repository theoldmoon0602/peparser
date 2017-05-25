import std.stdio, std.conv, std.container;

import types, nt, sectionheader;

ImageResourceDataEntry[] readAllDataEntries(File f, ImageResourceDirectoryEntry[] directories) {
    ImageResourceDataEntry[] datas;
    auto dirs = DList!ImageResourceDirectoryEntry(directories);
    while(! dirs.empty) {
        auto dir = dirs.front;
        dirs.removeFront(1);

        if (dir.dataIsDirectory) {
            auto rscDir = dir.readDir(f);
            auto entries = rscDir.readEntries(f);
            foreach(entry; entries) {
                dirs.insertBack(entry);
            }
        }
        else {
            datas ~= dir.readData(f);
        }
    }

    return datas;
}

ImageResourceDirectoryEntry[] readImageSourceDirectory(File f, NTHeader ntheader, SectionHeader[] headers)
{
    auto p = f.tell;
    scope(exit) f.seek(p);

    auto offset = ntheader.imageDataDirectories[2].physicalOffset(headers);
    auto addr = ntheader.imageDataDirectories[2].VirtualAddress + offset;
    IMAGE_RESOURCE_DIRECTORY rscDir;
    f.seek(addr);
    f.rawRead((&rscDir)[0..1]);

    auto entries = rscDir.readEntries(f, addr);    

    return entries;
}



class ImageResourceDirectory {
    IMAGE_RESOURCE_DIRECTORY dir;
    DWORD addr;

    this(IMAGE_RESOURCE_DIRECTORY dir, DWORD addr) {
        this.dir = dir;
        this.addr = addr;
    }
    ImageResourceDirectoryEntry[] readEntries(File f) {
        return dir.readEntries(f, addr);
    }

    alias dir this;
}

struct IMAGE_RESOURCE_DIRECTORY {
    DWORD   Characteristics;
    DWORD   TimeDateStamp;
    WORD    MajorVersion;
    WORD    MinorVersion;
    WORD    NumberOfNamedEntries;
    WORD    NumberOfIdEntries;

    ImageResourceDirectoryEntry[] readEntries(File f, DWORD base) {
        ImageResourceDirectoryEntry[] dirEntries;

        foreach(i;0..NumberOfIdEntries)
        {
            IMAGE_RESOURCE_DIRECTORY_ENTRY dirEntry;
            f.rawRead((&dirEntry)[0..1]);
            dirEntries ~= new ImageResourceDirectoryEntry(dirEntry, base);
        }
        foreach(i;0..NumberOfNamedEntries)
        {
            IMAGE_RESOURCE_DIRECTORY_ENTRY dirEntry;
            f.rawRead((&dirEntry)[0..1]);
            dirEntries ~= new ImageResourceDirectoryEntry(dirEntry, base);
        }

        return dirEntries;
    }
}

class ImageResourceDirectoryEntry {
    IMAGE_RESOURCE_DIRECTORY_ENTRY entry;
    DWORD base;

    this(IMAGE_RESOURCE_DIRECTORY_ENTRY entry, DWORD base) {
        this.entry = entry;
        this.base = base;
    }

    override string toString() {
        string s = "ImageResourceDirectoryEntry[" ~ entry.toString;
        s ~= "base=" ~ base.to!string;
        s ~= ", nameAddr=" ~ nameAddr.to!string;
        s ~= ", dataAddr=" ~ dataAddr.to!string;
        s ~= "]";
        return s;
    }

    @property DWORD nameAddr() {
        return base + entry.offsetToName;
    }
    @property DWORD dataAddr() {
        return base + entry.offsetToData;
    }

    ImageResourceDirectory readDir(File f) {
        IMAGE_RESOURCE_DIRECTORY dir;
        f.seek(dataAddr);
        f.rawRead((&dir)[0..1]);

        return new ImageResourceDirectory(dir, dataAddr);        
    }

    ImageResourceDataEntry readData(File f) {
        IMAGE_RESOURCE_DATA_ENTRY data;
        f.seek(dataAddr);
        f.rawRead((&data)[0..1]);

     
        return new ImageResourceDataEntry(data, dataAddr, id);

    }

    alias entry this;
}


struct IMAGE_RESOURCE_DIRECTORY_ENTRY
{
    enum DWORD IsNameStringMask = 0x80000000;
    enum DWORD IsDirectoryMask = 0x80000000;
    enum DWORD DataMask = 0x7fffffff;

    DWORD NameId;
    DWORD OffsetToData;

    @property bool dataIsDirectory() {
        return (OffsetToData & IsDirectoryMask) != 0;
    }
    @property bool IsNameString() {
        return (NameId & IsNameStringMask) != 0;
    }
    @property WORD id() {
        return cast(WORD)NameId;
    }
    @property DWORD offsetToName() {
        return NameId&DataMask;
    }
    @property DWORD offsetToData() {
        return OffsetToData&DataMask;
    }

    string toString() {
        string s = "IMAGE_RESOURCE_DIRECTORY_ENTRY[";
        s ~= "IsDir=" ~ dataIsDirectory.to!string;
        s ~= ", IsName=" ~ IsNameString.to!string;
        if (IsNameString) {
            s ~= ", offsetToName=" ~ offsetToName.to!string;
        }
        else {
            s ~= ", id=" ~ id.to!string;
        }
        s ~= ", offsetToData=" ~ offsetToData.to!string;
        s ~= "]";

        return s;
    }
}

class ImageResourceDataEntry
{
    IMAGE_RESOURCE_DATA_ENTRY data;
    DWORD base;
    WORD id;
    string name;

    this(IMAGE_RESOURCE_DATA_ENTRY data, DWORD base, WORD id, string name) {
        this.data = data;
        this.base = base;
    }
    this(IMAGE_RESOURCE_DATA_ENTRY data, DWORD base, WORD id) {
        this(data, base, id, "");
    }
    this(IMAGE_RESOURCE_DATA_ENTRY data, DWORD base, string name) {
        this(data, base, 0, name);
    }

    DWORD dataAddr() {
        return base + data.OffsetToData;
    }

    string read(File f) {
        char[] buf = new char[](data.Size);
        f.seek(dataAddr);
        f.rawRead(buf);
        return buf.to!string;
    }

    override string toString()
    {
        return "ImageResourceDataEntry[addr=" ~ data.OffsetToData.to!string ~ "]";
    }

    alias data this;
}

struct IMAGE_RESOURCE_DATA_ENTRY
{
    DWORD   OffsetToData;
    DWORD   Size;
    DWORD   CodePage;
    DWORD   Reserved;
}