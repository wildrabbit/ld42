package org.wildrabbit.zamburgers.world;

import flixel.FlxObject;

/**
 * ...
 * @author ith1ldin
 */

class TileData
{
	public var id:Int = 0;
	public var graphicId:Int = 0;	// Base ID
	public var baseHP:Int = 0;
	public var groupId:Int = 0;
		
	public function new(Id:Int, GroupId:Int = -1, BaseHP:Int = -1, GraphicId:Int = 0) 
	{
		set(Id, GroupId, BaseHP, GraphicId);
	}	
	
	public function set(Id:Int, GroupId:Int, BaseHP:Int, GraphicId:Int):Void
	{
		id = Id;
		groupId = GroupId;
		baseHP = BaseHP;
		graphicId = GraphicId;		
	}
}
