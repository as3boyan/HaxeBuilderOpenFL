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

package fileutils;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
import sys.io.FileOutput;

class TextFileUtils
{

	public function new() 
	{
		
	}
	
	public static function updateTextFile(file_path:String, s:String)
	{
		var file_updated:Bool = false;
		var mytextfile:FileOutput = null;
		
		for (i in 0...100)
		{
			if (file_updated) break;
			
			file_updated = true;
			
			try
			{
				mytextfile = File.write(file_path, false);
			}
			catch (unknown : Dynamic)
			{
				file_updated = false;
			}
			
			if (file_updated)
			{
				mytextfile.writeString(s);
				mytextfile.close();
			}
			else
			{
				Sys.sleep(0.1);
			}
		}
		
		if (!file_updated)
		{
			trace("file " + file_path + " is not updated");
		}
	}
	
	public static function replaceString(file_path:String, check_string:String, old_string:String, new_string:String)
	{
		var textfile_data:String = TextFileUtils.readTextFile(file_path);
		
		var r:EReg = new EReg(check_string, "gim");
		
		if (textfile_data != "")
		{
			if (!r.match(textfile_data))
			{
				var r:EReg = new EReg(old_string, "gim");
				
				textfile_data = r.replace(textfile_data, new_string);
				TextFileUtils.updateTextFile(file_path, textfile_data);
			}
		}
		else
		{
			trace("can't find " + file_path + " in output directory");
		}
	}
	
	public static function readTextFile(file_path:String):String
	{
		var textfile_data:String = "";

		if (FileSystem.exists(file_path))
		{			
			var mystatfile:FileInput = File.read(file_path, false);
		
			if (mystatfile != null)
			{
				textfile_data = mystatfile.readAll().toString();
				mystatfile.close();
			}
		}
		
		return textfile_data;
	}
	
}