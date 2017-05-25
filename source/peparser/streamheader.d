import std.stdio;

import types, utils;

StreamHeader readStreamHeader(File f)
{
    StreamHeader header;
    f.read(header.Offset);
    f.read(header.Size);

    // nullでおわり4byteでパディングされた文字列を読む
    while (true) {
        char[4] buf;
        f.rawRead(buf);
        header.Name ~= buf;
        if (buf[3] == '\0') {
            break;
        }
    }
    return header;
}

StreamHeader[] readStreamHeaders(File f, int numOfStreams)
{
    StreamHeader[] headers;
    headers.reserve(numOfStreams);

    foreach(i;0..numOfStreams)
    {
        headers ~= readStreamHeader(f);
    }
    return headers;
}

struct StreamHeader
{
    DWORD Offset;
    DWORD Size;
    char[] Name;
}