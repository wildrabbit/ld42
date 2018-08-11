package org.wildrabbit.zamburgers;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import org.wildrabbit.zamburgers.world.Grid;
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
	var levelArray:LevelData;
	var bg:FlxSprite;
	
	var player:Player;
	
	var entrance:FlxSprite;
	var exit:FlxSprite;

	var gameGroup:FlxGroup;
	
	var grid:Grid;
	var tileDataTable:TileDataTable;
	
	var goal:FlxSprite;

	override public function create():Void
	{
		super.create();
		
		
		gameGroup = new FlxGroup();
		add(gameGroup);
		
		loadTileTable();
		levelArray = loadStartingLevel();
		
		entrance = new FlxSprite(240, 0);
		entrance.makeGraphic(320, 140, FlxColor.GRAY);
		gameGroup.add(entrance);
		
		grid = new Grid();
		grid.setTileDataTable(tileDataTable);
		grid.initialize(levelArray.array, levelArray.w, levelArray.h);
		grid.setPosition(240, 140);
		gameGroup.add(grid);
		
		exit = new FlxSprite(240, 460);
		exit.makeGraphic(320, 140, FlxColor.GRAY);
		gameGroup.add(exit);
		
		goal = new FlxSprite(288, 512);
		goal.makeGraphic(64, 64, FlxColor.BROWN);
		gameGroup.add(goal);

		FlxG.worldBounds.set(240, 0, 64 * 5, FlxG.height);
		
		player = new Player();
		player.initFree(64 * (3 - 1 / 2), 64, grid, entrance, exit, goal.getHitbox());
		player.playerDropped.add(resetLevel);
		player.playerReachedGoal.add(levelExit);		
		gameGroup.add(player);
	}
	
	override public function update(elapsed:Float):Void
	{
	
		super.update(elapsed);
		//if (FlxG.keys.justPressed.S)
		//{
			//grid.stepped(2, 0);
		//}

	}
	
	function levelExit():Void
	{
		trace("YAY");
	}
	
	function resetLevel():Void
	{
		// Kill everything, restart stuff
		player.kill();
		player.reset(0,0);
		player.initFree(64 * (3 - 1 / 2), 64, grid, entrance, exit, goal.getHitbox());
		
		grid.kill();
		grid.reset(0,0);
		grid.initialize(levelArray.array, levelArray.w, levelArray.h);
		grid.setPosition(240, 140);
	}
	
	
	function loadTileTable():Void
	{
		tileDataTable = new TileDataTable();
		tileDataTable.emplaceEntry(0, 0, 3, 1);
		tileDataTable.emplaceEntry(1, 0, 2, 2);
		tileDataTable.emplaceEntry(2, 0, 1, 3);
		
		tileDataTable.emplaceEntry(3, 1, 3, 4);
		tileDataTable.emplaceEntry(4, 1, 2, 5);
		tileDataTable.emplaceEntry(5, 1, 1, 6);
		
		tileDataTable.emplaceEntry(6, 2, 3, 9);
		tileDataTable.emplaceEntry(7, 2, 2, 10);
		tileDataTable.emplaceEntry(8, 2, 1, 11);
		
		tileDataTable.emplaceEntry(9, 3, 3, 12);
		tileDataTable.emplaceEntry(10, 3, 2, 13);
		tileDataTable.emplaceEntry(11, 3, 1, 14);
		
		tileDataTable.emplaceEntry(12, 4, 3, 17);
		tileDataTable.emplaceEntry(13, 4, 2, 18);
		tileDataTable.emplaceEntry(14, 4, 1, 19);
		
		tileDataTable.emplaceEntry(15, 5, 3, 20);
		tileDataTable.emplaceEntry(16, 5, 2, 21);
		tileDataTable.emplaceEntry(17, 5, 1, 22);
	}
	
	function loadStartingLevel():LevelData
	{
		var data:LevelData = 
		{
			array: [-1, -1, 0, -1, -1,
					-1, 6, 0, -1, -1,
					-1, 6, -1, -1, -1,
					-1, 9, 3, -1, -1,
					-1, -1, 3, -1, -1,
			],
			w: 5,
			h: 5		
		};
		return data;
	}
}