/*The MIT License

Copyright (c) 2013 AS3Boyan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

package buildutils;
import fileutils.TextFileUtils;
import sys.net.Host;
import sys.net.Socket;

#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end

class BuildUtils
{

	public function new() 
	{
		
	}
	
	public static function getBuildDate(file_path):Date
	{
		var build_date:Date = null;
		
		var build_file_text:String = TextFileUtils.readTextFile(file_path);
		
		if (build_file_text != "" && build_file_text != "0")
		{
			try 
			{
				build_date = Date.fromString(build_file_text);
			}
			catch (unknown:Dynamic)
			{
				
			}
		}
		
		return build_date;
	}
	
	public static function startCompilationServer()
	{
		if (!checkCompilationServer())
		{
			Sys.println("Starting haxe compilation server...");
			
			Thread.create(function ()
			{
				Sys.command("haxe --wait 5000");
			}
			);
		}
	}
	
	private static function checkCompilationServer():Bool
	{
		var server_started:Bool = true;
			
		try
		{
			var socket:Socket = new Socket();
			socket.connect(new Host("localhost"), 5000);
			socket.close();
		}
		catch (unknown : Dynamic)
		{
			server_started = false;
		}
		
		return server_started;
	}
	
}