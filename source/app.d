import std.stdio, std.range;
import msdos;
import nt;
import sectionheader;
import resource;
import utils;
import cliheader;

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
	auto rscAddr = cor20.Resources.physicalAddr(sectionHeaders);
	f.seek(rscAddr);
	auto resourcesHeader = readDotResources(f);
	writeln(resourcesHeader);
	auto resources = readResources(f, resourcesHeader);
	writeln(resources);	
	return 0;
}
