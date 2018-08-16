package org.wildrabbit.zamburgers;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledLayer;
import flixel.group.FlxGroup;
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
		
		loadBackground(levelData.bgSource);
		
		var gridWidth:Int = levelData.width * Grid.TILE_WIDTH;
		var gridHeight:Int = levelData.height * Grid.TILE_HEIGHT;
		var entranceX:Int =  Math.round((FlxG.width - gridWidth) / 2);
		var entranceY:Int= 0;
		
		entrance = new FlxSprite(entranceX, entranceY);
		var entranceHeight:Int = Math.round((FlxG.height - gridHeight) / 2);
		
		entrance.makeGraphic(gridWidth, entranceHeight, FlxColor.fromString("#008d6e93"));
		gameGroup.add(entrance);
		
		var gridY:Int  = entranceY + entranceHeight;
		grid = new Grid();
		grid.setTileDataTable(tileDataTable);
		grid.initialize(levelData.tileIDs, levelData.width, levelData.height);
		grid.setPosition(entranceX, gridY);
		gameGroup.add(grid);
		
		exit = new FlxSprite(entranceX, gridY + gridHeight);
		exit.makeGraphic(gridWidth, entranceHeight, FlxColor.fromString("#008d6e93"));
		gameGroup.add(exit);
		
		goal = new FlxSprite(exit.x + levelData.goalRect.x, exit.y + levelData.goalRect.y);
		goal.makeGraphic(levelData.goalRect.w, levelData.goalRect.h, FlxColor.BROWN);
		goal.loadGraphic("assets/images/tile-pholders.png", true, 64, 64);
		goal.animation.add('def', [(currentLevelIdx != 0) ? 24 : 25]);
		goal.animation.play('def');
		gameGroup.add(goal);

		FlxG.worldBounds.set(entranceX, entranceY, gridWidth, FlxG.height);
		
		player = new Player();
		player.initFree(entranceX + levelData.playerStart.x, entranceY + levelData.playerStart.y, grid, entrance, exit, goal.getHitbox());
		player.playerDropped.add(resetLevel);
		player.playerDroppedStart.add(dropped);
		player.playerReachedGoal.add(levelExit);		
		gameGroup.add(player);
	}
	
	function loadBackground(path:FlxTiledMapAsset):Void
	{
		var leMap:TiledMap = new TiledMap(path);
		
		for (layer in leMap.layers)
		{
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