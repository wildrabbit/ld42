package org.wildrabbit.zamburgers.world;

import flixel.FlxObject;
import haxe.ds.ArraySort;
import flixel.system.FlxAssets.FlxGraphicAsset;

class TileDataTable
{
	public inline static var NO_TILE:Int = -1;
	
	private var tileTable: Map<Int,TileData> = new Map<Int,TileData>();
	private var sortedKeys: Array<Int> = new Array<Int>();	
	private var reverseMappings:Map<Int,Int> = new Map<Int, Int>();

	public function new()
	{		
	}
	
	public function iterator():Iterator<TileData>
	{
		return tileTable.iterator();
	}
	
	public function getTileForHPChange(referenceID:Int, hpDelta:Int):TileData
	{
		if (tileTable.exists(referenceID))
		{
			var data:TileData = tileTable[referenceID];
			var hp:Int = data.baseHP + hpDelta;
			var group:Int = data.groupId;
			
			for(data in tileTable)
			{
				if (data.groupId == group && data.baseHP == hp)
				{
					return data;
				}
			}
		}
		return null;
	}
	
	public function addEntry(value:TileData):Void
	{
		var needsAdd:Bool = !tileTable.exists(value.id);
		tileTable.set(value.id, value);		
		
		if (needsAdd)
		{
			if (!reverseMappings.exists(value.graphicId))
			{				
				reverseMappings.set(value.graphicId, value.id);
			}
		}
	}
	
	public function emplaceEntry(id:Int, groupId:Int, baseHP:Int, graphicId: Int):Void
	{
		var info:TileData = new TileData(id, groupId, baseHP, graphicId);
		addEntry(info);
	}

	
	public function getInfo(key:Int):TileData
	{
		return tileTable.get(key);
	}
	
	public function clear():Void
	{
		for (key in tileTable.keys())
		{
			tileTable.remove(key);
		}
	}	

	public function  getTypeFromGraphicId(graphicId:Int):Int
	{
		// First try: reverse map
		if (reverseMappings.exists(graphicId))
		{
			return reverseMappings[graphicId];
		}
		return NO_TILE;
	}
}