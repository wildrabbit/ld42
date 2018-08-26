package org.wildrabbit.zamburgers;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.io.Path;
import org.wildrabbit.zamburgers.world.Grid;
import org.wildrabbit.zamburgers.world.LevelDataTable;
import org.wildrabbit.zamburgers.world.Player;
import org.wildrabbit.zamburgers.world.TileDataTable;


import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledTileSet;
import flixel.addons.editors.tiled.TiledTileLayer;

typedef LevelData =
{
	var array:Array<Int>;
	var w:Int;
	var h:Int;
}

class PlayState extends FlxState
{
	var bg:FlxSprite;
	
	var player:Player;
	
	var entrance:FlxSprite;
	var exit:FlxSprite;

	var gameGroup:FlxGroup;
	var hudGroup:FlxGroup;
	
	var grid:Grid;
	
	var tileDataTable:TileDataTable;
	var levelDataTable:LevelDataTable;
	var currentLevelIdx:Int;
	
	var goal:FlxSprite;
	
	var lvInfo:FlxText;
	
	var trap:FlxText;

	override public function create():Void
	{
		super.create();
		
#if !FLX_NO_MOUSE
		FlxG.mouse.visible = false;
#end
		
		bgColor = FlxColor.fromString("#03181c");
		currentLevelIdx = 0;
				
		loadLevelTable();
		loadTileTable();
		
		gameGroup = new FlxGroup();
		add(gameGroup);
		
		hudGroup = new FlxGroup();
		add(hudGroup);
		
		lvInfo = new FlxText(0, 0, 200, '', 12);
		hudGroup.add(lvInfo);
		
    		trap = new FlxText(0,0,200, "It's a trap!",10);
		
		loadLevelByIndex(currentLevelIdx);		
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.M)
		{
			FlxG.sound.toggleMuted();
		}
		if (FlxG.keys.justPressed.R)
		{
			loadLevelByIndex(currentLevelIdx);				
		}
		else if (FlxG.keys.justPressed.T)
		{
			currentLevelIdx = 0;
			loadLevelByIndex(currentLevelIdx);				
		}
#if !FLX_NO_DEBUG		
		else if (FlxG.keys.justPressed.N)
		{
			currentLevelIdx = (currentLevelIdx + 1) % levelDataTable.numLevels;
			loadLevelByIndex(currentLevelIdx);
		}
		else if (FlxG.keys.justPressed.B)
		{
			currentLevelIdx = (levelDataTable.numLevels + currentLevelIdx - 1) % levelDataTable.numLevels;
			loadLevelByIndex(currentLevelIdx);
		}
#end
	}
	
	function levelExit():Void
	{
		if (currentLevelIdx == levelDataTable.numLevels - 1)
		{
			var callback = function(timer:FlxTimer)
			{
				FlxG.switchState(new GameWonState());
			};
			new FlxTimer().start(1, callback);
		}
		else
		{
			currentLevelIdx++;			
			loadLevelByIndex(currentLevelIdx);
		}
	}
	
	function dropped():Void
	{
		if (currentLevelIdx == 0)
		{
			hudGroup.add(trap);
			trap.setPosition(player.x, player.y - trap.height - 8);		
		}
	}
	
	function resetLevel():Void
	{
		var callback = function (timer:FlxTimer)
		{
			// Kill everything, restart stuff
			if (currentLevelIdx == 0)
			{
				currentLevelIdx = 1;
				hudGroup.remove(trap);
				
			}

			loadLevelByIndex(currentLevelIdx);
			//player.kill();
			//player.reset(0, 0);
			//player.initFree(64 * (3 - 1 / 2), 64, grid, entrance, exit, goal.getHitbox());
			//
			//grid.kill();
			//grid.reset(0,0);
			//grid.initialize(levelArray.array, levelArray.w, levelArray.h);
			//grid.setPosition(240, 140);						
		}
		new FlxTimer().start(0.5, callback);

	}
	
	function loadLevelByIndex(idx:Int):Void
	{
		var level:LevelJson = levelDataTable.getLevelAt(idx);
		loadLevel(level);
		lvInfo.text = 'Cur. level: $idx';
	}
	
	function loadLevel(levelData:LevelJson):Void
	{
		if (gameGroup != null)
		{
			for (obj in gameGroup)
			{
				obj.destroy();
			}
			gameGroup.clear();
			entrance = null;
			exit = null;
			player = null;
			goal = null;
			grid = null;			
		}
		
		var playerStart:FlxPoint = FlxPoint.get();
		var goalData:FlxRect = FlxRect.get();
		loadBackground(levelData.bgSource, playerStart, goalData);
		
		var gridWidth:Int = levelData.width * Grid.TILE_WIDTH;
		var gridHeight:Int = levelData.height * Grid.TILE_HEIGHT;
		grid = new Grid();
		grid.setTileDataTable(tileDataTable);
		grid.initialize(levelData.tileIDs, levelData.width, levelData.height);
		grid.setPosition( Math.round((FlxG.width - gridWidth) / 2), entrance.y + entrance.height + Grid.Y_OFFSET);
		gameGroup.add(grid);
		
		goal = new FlxSprite(goalData.x, goalData.y);
		goal.makeGraphic(Math.round(goalData.width), Math.round(goalData.height), FlxColor.TRANSPARENT);
		gameGroup.add(goal);

		FlxG.worldBounds.set(entrance.x, entrance.y, entrance.width, entrance.height + gridHeight + exit.height);
		
		player = new Player();
		player.initFree(playerStart.x, playerStart.y, grid, entrance, exit, goal.getHitbox());
		player.playerDropped.add(resetLevel);
		player.playerDroppedStart.add(dropped);
		player.playerReachedGoal.add(levelExit);		
		gameGroup.add(player);
		
		playerStart.put();
		goalData.put();
	}
	
	function loadBackground(path:FlxTiledMapAsset, start:FlxPoint, goal:FlxRect):Void
	{
		var leMap:TiledMap = new TiledMap(path);
		
		for (layer in leMap.layers)
		{
			if (layer.type == TiledLayerType.OBJECT)
			{
				var objLayer:TiledObjectLayer = cast layer;
				for (obj in objLayer.objects)
				{
					if (obj.name == "entrance")
					{
						entrance = new FlxSprite(obj.x, obj.y);
						entrance.makeGraphic(obj.width, obj.height, FlxColor.fromString("#008d6e93"));
						gameGroup.add(entrance);
					}
					else if (obj.name == "exit")
					{
						exit = new FlxSprite(obj.x, obj.y);
						exit.makeGraphic(obj.width, obj.height, FlxColor.fromString("#008d6e93"));
						gameGroup.add(exit);
					}
					else if (obj.name == "playerStart")
					{
						start.set(obj.x, obj.y);
					}
					else if (obj.name == "goal")
					{
						goal.set(obj.x, obj.y, obj.width, obj.height);
					}
				}
			}
			
			if (layer.type != TiledLayerType.TILE) continue;
			var tileLayer:TiledTileLayer = cast layer;
			var tilesheetName:String = tileLayer.properties.get("tileset");
			
			var tileset:TiledTileSet = null;
			for (ts in leMap.tilesets)
			{
				if (ts.name == tilesheetName)
				{
					tileset = ts;
					break;
				}
			}
			
			if (tileset != null)
			{
				var imgPath:Path = new Path(tileset.imageSource);
				var processedPath = "assets/images/" + imgPath.file + '.' + imgPath.ext;
				
				var map:FlxTilemap = new FlxTilemap();
				map.loadMapFromArray(tileLayer.tileArray, leMap.width, leMap.height, processedPath, tileset.tileWidth, tileset.tileHeight, OFF, tileset.firstGID, 1, 1);
				gameGroup.add(map);
			}
		}
	}

	function loadLevelTable():Void
	{
		levelDataTable = new LevelDataTable("assets/data/levels.json");
	}
	
	function loadTileTable():Void
	{
		tileDataTable = new TileDataTable();
		
		tileDataTable.emplaceEntry(0, 0, 3, 1); 
		tileDataTable.emplaceEntry(1, 1, 3, 4);
		tileDataTable.emplaceEntry(2, 2, 3, 9);
		tileDataTable.emplaceEntry(3, 3, 3, 12);
		tileDataTable.emplaceEntry(4, 4, 3, 17);
		tileDataTable.emplaceEntry(5, 5, 3, 20);
		
		tileDataTable.emplaceEntry(6, 0, 2, 2);
		tileDataTable.emplaceEntry(7, 1, 2, 5);
		tileDataTable.emplaceEntry(8, 2, 2, 10);
		tileDataTable.emplaceEntry(9, 3, 2, 13);
		tileDataTable.emplaceEntry(10, 4, 2, 18);
		tileDataTable.emplaceEntry(11, 5, 2, 21);
		
		tileDataTable.emplaceEntry(12, 0, 1, 3);
		tileDataTable.emplaceEntry(13, 1, 1, 6);
		tileDataTable.emplaceEntry(14, 2, 1, 11);
		tileDataTable.emplaceEntry(15, 3, 1, 14);
		tileDataTable.emplaceEntry(16, 4, 1, 19);
		tileDataTable.emplaceEntry(17, 5, 1, 22);
	}
}