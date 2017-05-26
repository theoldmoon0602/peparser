import std.stdio, std.range;
import peparser;

int main(string[] args)
{
	if (args.length == 1) {
		stderr.writefln("[Usage] %s <PE FILE>", args[0]);
		return 1;
	}
	auto f = File(args[1], "rb");
	auto pe = readPE(f);

	writeln("===RESOURCES===");
	writeln("NAME\t\tVALUE");
	foreach(res;pe.resources) {
		writeln(res.Name, "\t\t", res.Value);
	}
	return 0;
}
