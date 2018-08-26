package org.wildrabbit.zamburgers.world;

import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;

/**
 * ...
 * @author Ithil
 */


 class Grid extends FlxTilemap 
{
	public static inline var TILE_WIDTH:Int = 64;
	public static inline var TILE_HEIGHT:Int = 64;

	public static inline var INVALID_TILE_ID:Int = -1;
	private static inline var INVALID_GRID_IDX:Int = -1;
	
	public static inline var Y_OFFSET:Int = 8;
	
	private var _tileData:TileDataTable;
	private var _grid:Array<Int>;
	
	public function new() 
	{
		super();
	}
	
	public function setTileDataTable(tileData:TileDataTable):Void
	{
		_tileData = tileData;
	}

	public function initialize(tileIDs:Array<Int>, w:Int, h:Int):Void
	{
		_grid = tileIDs.copy();
		var tileGraphicIDs:Array<Int> = new Array<Int>();
		convertTileKeysToGraphics(tileIDs, tileGraphicIDs);
		loadMapFromArray(tileGraphicIDs, w, h, "assets/images/tile-pholders.png", TILE_WIDTH, TILE_HEIGHT, OFF, 1);	
	}
	
	function convertTileKeysToGraphics(ids:Array<Int>, graphicIDs:Array<Int>):Void
	{
		for (tileID in ids)
		{
			var data:TileData = _tileData.getInfo(tileID);
			if (data == null)
			{
				graphicIDs.push(0);
			}
			else
			{
				graphicIDs.push(data.graphicId);
			}
		}
	}
	
	public function stepped(col:Int, row:Int, affectsGroups:Bool = true):Void
	{
		var tileIdx:Int = getTileIndex(col, row);
		var tileID:Int = getTileAt(tileIdx);
		if (tileID <= INVALID_TILE_ID)
		{
			return;
		}
		
		var tileData:TileData = _tileData.getInfo(tileID);
		if (tileData == null)
		{
			return;
		}
		
		var affectedTileIndexes = new Array<Int>();
		if (affectsGroups)
		{
			findSameGroupTileIndexes(tileData.groupId, affectedTileIndexes);
		}
		else
		{
			affectedTileIndexes.push(tileIdx);
		}
		
		
		for (idx in affectedTileIndexes)
		{
			var formerID:Int = _grid[idx];
			if (formerID == TileDataTable.NO_TILE)
			{
				continue;
			}
			
			var newTile:TileData = _tileData.getTileForHPChange(formerID, -1);
			if (newTile != null)
			{
				//// Play destruction!
				setTileByIndex(idx, newTile.graphicId);
				_grid[idx] = newTile.id;
			}
			else
			{
				setTileByIndex(idx, 0, true);
				_grid[idx] = TileDataTable.NO_TILE;
			}
			
		}
		
	}
	
	private function findSameGroupTileIndexes(groupID:Int, indexes:Array<Int>)
	{
		var idx:Int = 0;
		for (tileID in _grid)
		{
			var tile:TileData = _tileData.getInfo(tileID);
			if (tile != null && tile.groupId == groupID)
			{
				indexes.push(idx);
			}
			idx++;
		}
	}
	
	public function getTileIndex(col:Int, row:Int):Int
	{
		if (col < 0 || col >= widthInTiles || row < 0 || row >= heightInTiles)
		{
			return INVALID_GRID_IDX;
		}
		return row * widthInTiles + col;
	}
	
	public function getTileAt(idx:Int):Int
	{
		if (idx < 0 || idx >= _grid.length)
		{
			return INVALID_TILE_ID;
		}
		return _grid[idx];
	}
	
	public function getTileAtCoords(col:Int, row:Int):Int
	{
		return getTileAt(getTileIndex(col, row));
	}
		
	public function worldFromCoords(col:Int, row:Int): FlxPoint
	{
		var pos:FlxPoint = FlxPoint.get();
		pos.set(x + (col + 0.5) * TILE_WIDTH , y + (row + 0.5) * TILE_HEIGHT);
		return pos;
	}
	
	public function getClosestColumn(refX:Float):Int
	{
		return  Std.int((refX - x) / TILE_WIDTH);
	}
	
	public function getClosestRow(refY:Float):Int
	{
		return Std.int((refY - y) / TILE_HEIGHT);		
	}
	
	public function canBeStepped(col:Int, row:Int):Bool
	{
		var tileID:Int = getTileAtCoords(col, row);
		return (tileID > INVALID_TILE_ID);
	}
}