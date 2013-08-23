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

package ;
import buildutils.BuildUtils;
import fileutils.FileUtils;
import fileutils.TextFileUtils;
import haxe.crypto.Sha1;
import haxe.Http;
import haxe.io.Bytes;
import neko.Lib;
import neko.net.ThreadServer;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import sys.net.Socket;

#if neko
import neko.vm.Thread;
#elseif cpp
import cpp.vm.Thread;
#end

typedef Client = {
	var id:Int;
}

typedef Message = {
	var str:String;
}

class Main extends ThreadServer<Client, Message>
{
	var build_date:Date;
	var client:Socket;
	var handshake_complete:Bool;
	var project_path:String;
	var project_file:String;
	var program_path:String;
	var build_mode:String;
	var lib_name:String;
	var flex_sdk_path:String;
	var fcsh_process:Process;
	
	function new()
	{	
		super();
		
		build_mode = "flash";
		
		var args:Array<String> = Sys.args();
		
		for (arg in args)
		{
			if (arg == "html5")
			{
				build_mode = "html5";
			}
		}
		
		program_path = Sys.executablePath();	
		program_path = checkPath(program_path.substring(0, program_path.lastIndexOf("\\")));
		
		project_path = Sys.getCwd();
		
		flex_sdk_path = "G:\\ApacheFlex\\"; 
		
		lib_name = "nme";
		
		var project_file_names:Array<String> = ["application.xml", "project.xml", ".nmml", ".hxproj",".as3proj"];
		
		for (i in 0...project_file_names.length)
		{
			project_file = FileUtils.searchFile(project_path, project_file_names[i]);
			
			if (project_file != null)
			{
				switch (project_file_names[i])
				{
					case "application.xml", "project.xml": 
						lib_name = "openfl";
					case ".hxproj":
						build_mode = "haxe";
					case ".as3proj":
						build_mode = "as3";
				}
				
				break;
			}
		}
		
		if (project_file == null)
		{
			Sys.println("Can't find project file");
			return;
		}
		
		build_date = BuildUtils.getBuildDate(project_path + "bin\\.build_date");
		
		if (build_mode == "as3")
		{
			Sys.setCwd("\"" + flex_sdk_path + "bin\\");
			fcsh_process = new Process("fcsh", []);
			
			readUntilMatches(fcsh_process,"fcsh", 2);
		}
		else
		{
			BuildUtils.startCompilationServer();
		}
		
		if (build_date == null) build(project_path, project_file);
		
		var n:Int = null;
		
		if (build_mode == "as3")
		{
			n = Sys.command("start " + project_path + "bin\\index.html");
		}
		else
		{
			if (build_mode == "html5" || build_mode == "flash")
			{
				//Thread.create(Sys.command.bind("nekotools server -d " + project_path + "bin\\" + build_mode + "\\bin"));
				//Sys.command("nekotools server -d " + project_path + "bin\\" + build_mode + "\\bin");
				
				var array:Array<String> = new Array();
				array.push("server");
				array.push("-d");
				array.push(project_path + "bin\\" + build_mode + "\\bin");
				
				var neko_server:Process = new Process("nekotools", array);
				readUntilMatches(neko_server, "2000", 1);
				
				var http:Http = new Http("http://localhost:2000");
				while (http.responseData == null)
				{
					http.request();
					Sys.sleep(0.5);
				}

				n = Sys.command("start " + "http://localhost:2000");
			}
			else
			{
				n = Sys.command("start " + project_path + "bin\\" + build_mode + "\\bin\\index.html");
			}
		}
		
		if (n != 0)
		{
			trace("HaxeBuilder can't start index.html. Open index.html manually.");
		}
		
		run("127.0.0.1", 5001);
	}
	
	function readUntilMatches(process:Process, string:String, n:Int, ?match_string:String = null):Bool
	{
		var process_output:String = "";
		
		var r:EReg = new EReg(string, "gim");
		var r2:EReg = null;
		if (match_string != null) r2 = new EReg(match_string, "gim");
		var match:Bool = false;
		
		var c:Int = 0;
		
		while (true)
		{
			process_output += process.stdout.readString(1);
			
			if (r.match(process_output))
			{
				if (r2 != null && r2.match(process_output))
				{
					match = true;
				}
				
				c++;
				process_output = "";
				if (c == n)	break;
			}
		}
		
		return match;
	}
	
	function createHtmlWrapper()
	{
		FileUtils.createFolders(project_path + "bin\\js");
		
		FileUtils.copy(program_path + "index.html", project_path + "bin\\index.html", false);
		FileUtils.copy(program_path + "js\\swfobject.js", project_path + "bin\\js\\swfobject.js", false);
		FileUtils.copy(program_path + "expressInstall.swf", project_path + "bin\\expressInstall.swf", false);
		
		TextFileUtils.replaceString(project_path + "bin\\index.html", "StarlingTest.swf", "</head>", "<script>var flashvars = {};var params = {	menu: \"false\",scale: \"noScale\",allowFullscreen: \"true\",allowScriptAccess: \"always\",bgcolor: \"\",wmode: \"direct\"};var attributes = {id:\"StarlingTest\"};swfobject.embedSWF(\"StarlingTest.swf\", \"altContent\", \"100%\", \"100%\", \"10.0.0\",\"expressInstall.swf\", flashvars, params, attributes);</script></head>");
	}
	
	function checkPath(folder_path:String):String
	{
		var path:String = folder_path;
		
		if (path.charAt(path.length - 1)!= "\\")
		{
			path += "\\";
		}
		
		return path;
	}
	
	function checkHtmlPage(file_path:String) 
	{		
		if (build_mode == "flash")
		{
			var file_text:String = TextFileUtils.readTextFile(file_path);
			
			var _ereg:EReg = new EReg("swfobject.embedSWF(.+);", "");
			
			if (_ereg.match(file_text))
			{
				var _str:String = _ereg.matched(1);
				_str = getStringBetween(_str, "(");
				
				var array:Array<String> = _str.split(",");
				
				var flash_player_version:Float = Std.parseFloat(getStringBetween(array[4], "\""));
				
				if (flash_player_version >= 11)
				{
					TextFileUtils.replaceString(file_path, "wmode:(.+)\"direct\"", "{}", "{},{wmode:\"direct\"}");
				}
			}
		}
		
		TextFileUtils.replaceString(file_path, "WebSocketTest.js", "</body>", "\n\t<script type=\"text/javascript\" src=\"http://localhost:2000/WebSocketTest.js\"></script>\n</body>");
	}
	
	private function getStringBetween(_str:String, _str2:String):String
	{
		var n:Int = _str.indexOf(_str2, 0);
		return _str.substr(n+1, _str.length - n - 2);
	}
	
	public function build(project_path:String, project_file:String) 
	{	
		var current_time:Float = Sys.time();
		
		Sys.println("build started");
		
		if (build_mode == "as3")
		{			
			if (FileSystem.exists(flex_sdk_path + "bin\\mxmlc") && FileSystem.exists(flex_sdk_path + "bin\\fcsh"))
			{								
				build_date = Date.now();
				
				fcsh_process.stdin.writeString("mxmlc" + " -load-config+=G:\\AS3_and_Haxe_Projects\\StarlingTest\\obj\\StarlingTestConfig.xml" + " -debug=true -incremental=true -output=G:\\AS3_and_Haxe_Projects\\StarlingTest\\bin\\StarlingTest.swf\n");
				
				var match:Bool = readUntilMatches(fcsh_process,"fcsh", 2, ".swf");
				
				//fcsh_process.kill();
				
				//var n:Int = Sys.command("mxmlc" + " -load-config+=G:\\AS3_and_Haxe_Projects\\StarlingTest\\obj\\StarlingTestConfig.xml" + " -debug=true -incremental=true -output=G:\\AS3_and_Haxe_Projects\\StarlingTest\\bin\\StarlingTest.swf");
				
				if (match)
				{
					TextFileUtils.updateTextFile(project_path + "bin\\.build_date", build_date.toString());
					Sys.println("build complete");
				}
				else
				{
					Sys.println("build failed");
				}
				
				createHtmlWrapper();
				checkHtmlPage(project_path + "bin\\index.html");
			}
			else
			{
				trace("can't find Flex SDK in path: " +  flex_sdk_path);
			}
			
			//mxmlc -load-config+=obj\HexagonMenuConfig.xml -debug=true -incremental=true -swf-version=20 -o obj\HexagonMenu635058830002070312
		}
		else
		{
			var additional_args:String = "";
		
			if (build_mode == "flash")
			{
				additional_args = " -web";
			}
			
			build_date = Date.now();
			
			//var t1:Thread = Thread.create(
			//function ()
			//{
				//var main:Thread = Thread.readMessage(true);
				var n:Int = Sys.command("haxelib run " + lib_name + " build " + project_path + project_file + " " + build_mode + additional_args + " -debug" + " --connect 5000");
				//main.sendMessage(n);
			//}
			//);
			//
			//t1.sendMessage(Thread.current());
			
			//var n:Int = Thread.readMessage(true);
			//trace(n);
			if (n == 0)
			{
				TextFileUtils.updateTextFile(project_path + "bin\\.build_date", build_date.toString());
				Sys.println("build complete");
			}
			else
			{
				Sys.println("build failed");
			}
			
			checkHtmlPage(project_path + "bin\\" + build_mode + "\\bin\\index.html");
			FileUtils.copy(program_path + "WebSocketTest.js", project_path + "bin\\" + build_mode + "\\bin\\WebSocketTest.js", false);
		}
		
		sendUpdateMessage();
		
		var delta:Float = Sys.time() - current_time;
		Sys.println("build time: " + Std.string(delta));
	}
	
	override function clientConnected( s : Socket ) : Client
	{
		var num = Std.random(100);
		Lib.println("client " + num + " is " + s.peer());

		client = s;
		//sendData(client, "<?xml version=\"1.0\"?><cross-domain-policy><allow-access-from domain='*' to-ports='6000' /></cross-domain-policy>\000");
		handshake_complete = false;

		return { id: num };
	}

	private function handshake(msg:String) 
	{
	  var r:EReg = ~/Sec-WebSocket-Key: (.+)\r/;
	  r.match(msg);
	  var m = r.matched(1);
	  
	  m = m + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
	  var s = Sha1.encode(m);

	  m = "";
	  var i:Int = 0;
	  while (i<s.length)
	  {
		m += String.fromCharCode(Std.parseInt("0x" + s.substr(i, 2)));
		i+=2;
	  }
	  
	  var suffix:String = "";
	  if (m.length % 3 == 2)
	  {
		 suffix = "=";
	  }
	  else if(m.length % 3 == 1)
	  {
		 suffix = "==";
	  }
	  
	  m = haxe.crypto.BaseCode.encode(m, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/");
	  
	  m += suffix;
	  
	  var response:String = "";

	  response += 'HTTP/1.1 101 Switching Protocols\r\n';
	  response += 'Upgrade: websocket\r\n';
	  response += 'Connection: Upgrade\r\n';
	  response += 'Sec-WebSocket-Accept: ' + m + '\r\n\r\n';
	  
	  sendData(client, response);
	  handshake_complete = true;	  
	}

	public function sendUpdateMessage():Void
	{
	  if (client != null)
	  {
		  var s:String = "update";
		  client.output.writeByte(129);
		  client.output.writeByte(s.length);
		  client.write(s);	
	  }
	}

	override function clientDisconnected( c : Client )
	{
		Lib.println("client " + Std.string(c.id) + " disconnected");
	}

	override function readClientMessage(c:Client, buf:Bytes, pos:Int, len:Int)
	{
		// find out if there's a full message, and if so, how long it is.

		var msg:String = buf.readString(0, len);

		if (!handshake_complete)
		{
			handshake(msg);
		}

		//var complete = false;
		//var cpos = pos;
		//while (cpos < (pos+len) && !complete)
		//{
		  //complete = (buf.get(cpos) == 10);//46
		  //cpos++;
		//}

		 //no full message
		//if( !complete ) return null;


		 //got a full message, return it
		//var msg:String = buf.readString(pos, cpos-pos);

		//var msg:String = buf.readString(0, buf.length);
		//return { msg: {str:msg}, bytes:buf.length};
		//return {msg: {str: msg}, bytes: cpos-pos};
		return {msg: {str: msg}, bytes: len};
	}

	//override function readClientData( c : ClientInfos<Client> ) 
	//{
	//var available = c.buf.length - c.bufpos;
	//if( available == 0 ) {
		//var newsize = c.buf.length * 2;
		//if( newsize > maxBufferSize ) {
			//newsize = maxBufferSize;
			//if( c.buf.length == maxBufferSize )
				//throw "Max buffer size reached";
		//}
		//var newbuf = haxe.io.Bytes.alloc(newsize);
		//newbuf.blit(0,c.buf,0,c.bufpos);
		//c.buf = newbuf;
		//available = newsize - c.bufpos;
	//}
	//var bytes = c.sock.input.readBytes(c.buf,c.bufpos,available);
	//var pos = 0;
	//var len = c.bufpos + bytes;
	//while( len >= messageHeaderSize ) {
		//var m = readClientMessage(c.client,c.buf,pos,len);
		//if( m == null )
			//break;
		//pos += m.bytes;
		//len -= m.bytes;
		//work(clientMessage.bind(c.client,m.msg));
	//}
	//if( pos > 0 )
		//c.buf.blit(0,c.buf,pos,len);
	//c.bufpos = len;
	//}

	override function clientMessage( c : Client, msg : Message )
	{
		Lib.println(c.id + " sent: " + msg.str);
	}

	override function update()
	{
		if (FileUtils.scanFolder(project_path, build_date.getTime(), "bin")) build(project_path, project_file);
	}
	
	static function main() 
	{
		new Main();
	}
	
}