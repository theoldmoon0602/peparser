import std.stdio, std.algorithm, std.array, std.conv, std.range;

import types;

/// 任意の型を読む
T readT(T)(File f) {
    T v;
    f.rawRead((&v)[0..1]);
    return v;
}
T read(T)(File f, ref T v)
    if (!hasLength!T)
{
    f.rawRead((&v)[0..1]);
    return v;
}
alias readBYTE = readT!BYTE;
alias readWORD = readT!WORD;
alias readDWORD = readT!DWORD;
alias readUINT64 = readT!ULONGLONG;

/// 奇妙にエンコーディングされた数値列を読む
UINT64 read7BitEncodedInteger(File f)
{
    uint v;
    BYTE b;
    f.rawRead((&b)[0..1]);

    if ((b&0x80)==0) {
        v = b;
    }
    else if ((b&0x40)==0) {
        v = b&0x3f;
        f.rawRead((&b)[0..1]);
        v = v << 8 | b;
    }
    else if ((b&0x20)==0) {
        v = b&0x1f;
        f.rawRead((&b)[0..1]);
        v = v << 8 | b;
        f.rawRead((&b)[0..1]);
        v = v << 8 | b;
        f.rawRead((&b)[0..1]);
        v = v << 8 | b;
    }
    else {
        throw new Exception("Failed to Decode Integer at:" ~ f.tell.to!string);
    }

    return v;
}
byte[] readBlob(File f) {
    auto l = f.read7BitEncodedInteger;

    byte[] buf = new byte[](cast(uint)l);
    f.rawRead(buf);
    return buf;
}



/// 文字列を長さ付きで読む
char[] readString(File f) {
    auto l = cast(uint)f.read7BitEncodedInteger;
    char[] str;
    if (l%2!=0) {
        str = new char[](l-1);
        f.rawRead(str);
        f.seek(f.tell+1);    
    }
    else {
        str = new char[](l);
        f.rawRead(str);
    }
    return str;
}

/// バイト列を文字列に変換する
char[] toChars(byte[] bytes)
{
    return bytes.map!(to!char).array;
}

