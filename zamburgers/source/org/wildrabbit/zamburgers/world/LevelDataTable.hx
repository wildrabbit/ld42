package org.wildrabbit.zamburgers.world;

import openfl.Assets;
import haxe.Json;

typedef IntVec2 =
{
	var x:Int;
	var y:Int;
}

typedef IntRect =
{
	var x:Int;
	var y:Int;
	var w:Int;
	var h:Int;
}

typedef LevelJson = 
 {
	var id:Int;
	var playerStart:IntVec2;
	var goalRect:IntRect;
	var width:Int;
	var height:Int;
	var tileIDs:Array<Int>;
	
	@:optional var entranceCustomSprite:String;
	@:optional var exitCustomSprite:String;
	@:optional var goalCustomSprite:String;
	@:optional var msg:String;
 }

/**
 * ...
 * @author Ithil
 */
class LevelDataTable 
{
	var table:Array<LevelJson>;
		
	public function new(path:String) 
	{
		var levelFile:String = Assets.getText(path);
		table = Json.parse(levelFile);
	}
	
	public var numLevels(get, null):Int;
	
	function get_numLevels()
	{
		return table.length;
	}
	
	public function getLevelAt(idx:Int):LevelJson
	{
		if (idx < 0 || idx >= table.length)
		{
			trace('Invalid level table idx $idx');
		}
		return table[idx];
	}	
}