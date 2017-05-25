import std.stdio, std.range;
import msdos;
import nt;
import sectionheader;
import utils;
import resourcessection;
import cor20;

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
	auto cor20 = readCOR20HEADER(f, ntheader, sectionHeaders);
	f.seek(cor20.Resources.physicalAddr(sectionHeaders) + 4);
	auto resourcesHeader = readResourcesHeader(f);
	writeln(resourcesHeader);
	auto resources = readResources(f, resourcesHeader);
	writeln(resources);	
	return 0;
}
