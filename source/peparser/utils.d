import std.algorithm, std.traits;

pure size_t calcStructSize(T)(T v, string[] ignore_members)
{

    size_t struct_size = 0;
    foreach(name; FieldNameTuple!T) {
        if (ignore_members.canFind(name)) {
            continue;
        }

        struct_size += __traits(getMember, v, name).sizeof;
    }

    return struct_size;
}