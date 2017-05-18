import std.stdio, std.range;
import msdos;
import nt;
import sectionheader;
import utils;

int main(string[] args)
{
	if (args.length == 1) {
		stderr.writefln("[Usage] %s <PE FILE>", args[0]);
		return 1;
	}
	auto f = File(args[1], "rb");
	auto dosHeader = readDOSHeader(f);
	f.seek(dosHeader.e_lfanew);
	auto ntheader = readNTHeader(f);
	auto sectionHeaders = readSectionHeaders(f, ntheader.FileHeader.NumberOfSections);
	auto sectionDatas = readSectionDatas(f, sectionHeaders);
	// auto sectionData = readSectionData(f, sectionHeaders[0]);
	writeln(dosHeader);
	writeln(ntheader);
	writeln(sectionHeaders);
	// writeln(sectionData);
	writeln(sectionDatas[0]);
	foreach(section; zip(sectionHeaders, sectionDatas)) {

		if (section[0].isExecutable) {
			continue;
		}
		if (! section[0].isInitialized) {
			continue;
		}
		writeln(section);
	}
	return 0;
}
