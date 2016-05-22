// Written in the D programming language.
/*
 * dmd 2.070.0
 *
 * Copyright Seiji Fujita 2016.
 * Distributed under the Boost Software License, Version 1.0.
 * http://www.boost.org/LICENSE_1_0.txt
 */
module rfind;

import dlsbuffer;

class Find
{
	import std.datetime;
private:
	// in
	string[]	regStr;
	string	baseDir;
	bool	outFullPath;
	bool	findSTOP;
	void	delegate(string) dgput; // output tool
	// out
	bool	_status;
	ulong	_matchCount;
	ulong   _fileCount;
	SysTime startTime;
	SysTime stopTime;
	
public:
	this(void delegate(string) dg) {
		dgput = dg;
	}
	
	bool checkDir(string dir) {
		import std.file;
		bool Result;
		if (dir !is null && dir.length > 0 && dir.exists() && dir.isDir()) {
			Result = true;
		}
		return Result;
	}
	
	void Stop() {
		findSTOP = true;
	}
	
	bool getStop() {
		return findSTOP;
	}
	
	// true is find running...
	bool getStatus() {
		return _status;
	}
	private void init() {
		_status = true;
		_fileCount = 0;
		_matchCount = 0;
		findSTOP = false;
	}
	
	int findfile(string dir, string reStr, bool fullpath = false) {
		int result = 1;
		init();
		if (checkDir(dir)) {
			baseDir = dir;
			outFullPath = fullpath;
			if (reStr.length == 0) {
				regStr = ["."];
			} else {
				regStr = ex1_splitLines(reStr);
			}
			dlog("findFile:regStr: ", regStr);
			
			startTime = Clock.currTime();
			findf(dir);
			stopTime = Clock.currTime();
			
			result = 0;
		}
		_status = false;
		return result;
	}
	
	string[] ex1_splitLines(string line) {
		import std.algorithm;
		import std.array;
		return line.splitter!(a => !":".find(a).empty).array;
	}
	string[] ex_splitLines(string line) {
		string[] Result;
		string ex_line;
		ex_line = line ~ "\r";
		
		for (int i, n; ex_line.length > i; i++) {
			if (ex_line[i] == ':') {
				Result ~= ex_line[n .. i].dup;
				n = i + 1;
			}
			if (ex_line[i] == '\r' && n != 0) {
				Result ~= ex_line[n .. i].dup;
			}
		}
		if (Result.length == 0) {
			Result ~= line.dup;
		}
		return Result;
	}
	
	private void findLine(string[] regs, string dir, string fullpath) {
		import std.regex;
		string fileName = fullpath[dir.length + 1 .. $];
		foreach (v ; regs) {
			auto m = match(fileName, regex(v));
			auto c = m.captures;
			++_fileCount;
			if (!c.empty()) {
				++_matchCount;
				if (outFullPath) {
					dgput(fullpath);
				}
				else {
					auto n = baseDir.length;
					if (fullpath[n] == '\\') {
						dgput(fullpath[n + 1 .. $]);
					} else {
						dgput(fullpath[n .. $]);
					}
				}
			}
		}
	}
	
	private void findf(string dir) {
		import std.file;
		import std.regex;
		try {
			// bool skip_flag = true;
			foreach (DirEntry e; dirEntries(dir, SpanMode.shallow)) {
				if (findSTOP) {
					return;
				}
				if (e.isDir()) {
				/*	if (skip_flag && dir.length <= 3 && e.name == "C:\\$Recycle.Bin") {
						skip_flag = false;
						continue;
					}
				*/
					findf(e.name);
				}
				else {
					findLine(regStr, dir, e.name);
				}
			}
		}
		catch (Exception ex) {
			dlog("#Exception: ", ex.toString());
		}
	}
	
	ulong matchCount() {
		return _matchCount;
	}
	ulong fileCount() {
		return _fileCount;
	}
	string StartTime() {
		return timeToString(startTime);
	}
	string StopTime() {
		return timeToString(stopTime);
	}
	private string timeToString(SysTime st) {
		import std.format;
		return  format(
					"%04d/%02d/%02d-%02d:%02d:%02d",
					st.year,
					st.month,
					st.day,
					st.hour,
					st.minute,
					st.second);
	}
	private string getDateTimeStr() {
		import std.format;
		SysTime cTime = Clock.currTime();
		return  format(
					"%04d/%02d/%02d-%02d:%02d:%02d",
					cTime.year,
					cTime.month,
					cTime.day,
					cTime.hour,
					cTime.minute,
					cTime.second);
	}
}

version (use_main) {
	
import std.stdio;
import std.conv : to;

void printHelp()
{
	writeln("findf help message");
}

// c:\dlang\test.exe -> c:\dlang\test
string getExecPath()
{
	import std.string : lastIndexOf;
	import core.runtime: Runtime;
	
	string Result;
	string execPath;
	if (Runtime.args.length)
		execPath = Runtime.args[0];
	
	if (execPath.length > 0) {
		int n = lastIndexOf(execPath, ".");
		if (n > 0) {
			Result = execPath[0 .. n];
		} else {
			Result = execPath;
		}
	}
	else {
		Result = ".\\noname";
	}
	
	return Result;
}

string getTempFileName(string ext = "txt")
{
	return getExecPath() ~ "." ~ ext;
}

int doFind(string regex, string dir, bool outputFile = false, bool fullpath_Flag = false)
{
	string wFile = getTempFileName();
	void output(string s) { 
		import std.file : append;
		if (outputFile)
			append(wFile, s ~ "\r\n");
		else 
			writeln(s);
	}
	int Result;
	auto rfind = new Find(&output);
	if (rfind.checkDir(dir)) {
		Result = rfind.findfile(dir, regex, fullpath_Flag);
		
		string starttime = rfind.StartTime();
		string stoptime = rfind.StopTime();
		ulong count = rfind.matchCount();
		ulong files = rfind.fileCount();
		output("# done...\n"
			~ "# Start :" ~ starttime ~ "\n"
			~ "# Stop  :" ~ stoptime  ~ "\n"
			~ "# Files/Match :" ~ to!string(files) ~ "/" ~ to!string(count) ~ " files\n"
		);
		//
	} else {
		writeln("#directory missmatch!");
	}
	return Result;
}


int  main(string[] args)
{
	int Result;
	try {
		string regex = "d$";
		string searchdir;
		
/*		writeln("args.length: ", args.length);
		foreach(arg; args) {
			writeln(arg);
		}
*/		
		if (args.length == 2) {
			doFind(args[1], ".\\");
		}
		if (args.length == 3) {
			doFind(args[1], args[2]);
		}
		
		Result = 1;
		//
	} catch(Exception e) {
		dlog("Exception: ", e.toString());
	}
	return Result;
}

} // version (USE_Main)
