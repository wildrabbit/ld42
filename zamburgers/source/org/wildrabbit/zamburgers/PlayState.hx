package org.wildrabbit.zamburgers;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import org.wildrabbit.zamburgers.world.Grid;
import org.wildrabbit.zamburgers.world.LevelDataTable;
import org.wildrabbit.zamburgers.world.Player;
import org.wildrabbit.zamburgers.world.TileDataTable;

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

	override public function create():Void
	{
		super.create();
		
		currentLevelIdx = 0;
				
		loadLevelTable();
		loadTileTable();
		
		gameGroup = new FlxGroup();
		add(gameGroup);
		
		hudGroup = new FlxGroup();
		add(hudGroup);
		
		lvInfo = new FlxText(0, 0, 200, '', 12);
		hudGroup.add(lvInfo);
		
		loadLevelByIndex(currentLevelIdx);		
	}
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.L)
		{
			loadLevelTable();
			loadLevelByIndex(currentLevelIdx);				
		}
		else if (FlxG.keys.justPressed.R)
		{
			loadLevelByIndex(currentLevelIdx);				
		}
		else if (FlxG.keys.justPressed.T)
		{
			currentLevelIdx = 0;
			loadLevelByIndex(currentLevelIdx);				
		}
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
	}
	
	function levelExit():Void
	{
		if (currentLevelIdx == levelDataTable.numLevels - 1)
		{
			trace("YAY, WON");			
		}
		else
		{
			currentLevelIdx++;			
			loadLevelByIndex(currentLevelIdx);
		}
	}
	
	function resetLevel():Void
	{
		// Kill everything, restart stuff
		if (currentLevelIdx == 0)
		{
			currentLevelIdx = 1;
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
		
		var gridWidth:Int = levelData.width * Grid.TILE_WIDTH;
		var gridHeight:Int = levelData.height * Grid.TILE_HEIGHT;
		var entranceX:Int =  Math.round((FlxG.width - gridWidth) / 2);
		var entranceY:Int= 0;
		
		entrance = new FlxSprite(entranceX, entranceY);
		var entranceHeight:Int = Math.round((FlxG.height - gridHeight) / 2);
		
		entrance.makeGraphic(gridWidth, entranceHeight, FlxColor.GRAY);
		gameGroup.add(entrance);
		
		var gridY:Int  = entranceY + entranceHeight;
		grid = new Grid();
		grid.setTileDataTable(tileDataTable);
		grid.initialize(levelData.tileIDs, levelData.width, levelData.height);
		grid.setPosition(entranceX, gridY);
		gameGroup.add(grid);
		
		exit = new FlxSprite(entranceX, gridY + gridHeight);
		exit.makeGraphic(gridWidth, entranceHeight, FlxColor.GRAY);
		gameGroup.add(exit);
		
		goal = new FlxSprite(exit.x + levelData.goalRect.x, exit.y + levelData.goalRect.y);
		goal.makeGraphic(levelData.goalRect.w, levelData.goalRect.h, FlxColor.BROWN);
		gameGroup.add(goal);

		FlxG.worldBounds.set(entranceX, entranceY, gridWidth, FlxG.height);
		
		player = new Player();
		player.initFree(entranceX + levelData.playerStart.x, entranceY + levelData.playerStart.y, grid, entrance, exit, goal.getHitbox());
		player.playerDropped.add(resetLevel);
		player.playerReachedGoal.add(levelExit);		
		gameGroup.add(player);
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