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
import sys.FileStat;
import sys.FileSystem;
import sys.io.File;

class FileUtils
{

	public function new() 
	{
		
	}
	
	public static function isFileModified(file_path:String, date:Float):Bool
	{		
		var modified:Bool = false;
		var filestat:FileStat = FileSystem.stat(file_path);
		var delta:Float = filestat.mtime.getTime() - date;
		if ((delta / 1000) > 0)
		{
			modified = true;
		}
		
		return modified;
	}
	
	public static function deleteFile(file_path:String)
	{
		if (FileSystem.exists(file_path))
		{
			try
			{
				FileSystem.deleteFile(file_path);
			}
			catch (unknown:Dynamic)
			{
				
			}
		}
	}
	
	public static function scanFolder(folder_path:String, date:Float, ?ignore_folder:String = null, ?recursive:Bool = true):Bool
	{				
		var need_rebuild:Bool = false;
		
		var folder_contents:Array<String> = FileSystem.readDirectory(folder_path);
		
		for (item in folder_contents)
		{
			var path:String = folder_path + "\\" + item;
			
			if (!FileSystem.isDirectory(path))
			{				
				if (isFileModified(path, date))
				{
					need_rebuild = true;
					break;
				}
			}
			else if(recursive && (path != folder_path + "\\" + ignore_folder || ignore_folder == null))
			{
				if (scanFolder(path, date))
				{
					need_rebuild = true;
					break;
				}
			}
		}
		
		return need_rebuild;
	}
	
	public static function searchFile(folder_path:String, file_extension:String):String
	{
		var file_path:String = null;
		
		var file_list:Array<String> = FileSystem.readDirectory(folder_path);
		
		var r:EReg = new EReg(file_extension,"i");
		
		for (file in file_list)
		{
			if (r.match(file))
			{
				file_path = file;
				break;
			}
		}
		
		return file_path;
	}
	
	public static function copy(file_path:String, dest_path:String, overwrite:Bool = true)
	{
		if (!FileSystem.exists(dest_path) || overwrite)
		{
			File.copy(file_path, dest_path);
		}
	}
	
	static public function createFolders(folder_path:String) 
	{
		var folders:Array<String> = folder_path.split("\\");
		
		var path:String = "";
		
		for (i in 0...folders.length)
		{
			path += folders[i] + "\\";
			
			if (!FileSystem.exists(path))
			{
				FileSystem.createDirectory(path);
			}
		}
	}
	
}