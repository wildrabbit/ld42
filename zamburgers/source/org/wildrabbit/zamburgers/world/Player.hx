package org.wildrabbit.zamburgers.world;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSignal;
import flixel.util.FlxSignal.FlxTypedSignal;

@:enum
abstract MoveDirection(Int) from Int to Int
{
	var None = -1;
    var North = 0;
    var South = 1;
    var East = 2;
	var West = 3;
	var NumEntries = West - North + 1;
}
/**
 * ...
 * @author Ithil
 */
class Player extends FlxSprite 
{
	private static inline var THRESHOLD_ENTER_GRID:Float = 8;
	private static inline var ENTER_FREE_MOVEMENT_OFFSET:Float = 12;
	
	var freeMotion:Bool = true;
	var updateFunction:Float->Void;
	
	var gridX:Int = -1;
	var gridY:Int = -1;
	
	var anchor:FlxPoint = new FlxPoint(0.5, 1);
		
	var grid:Grid;
	var entrance:FlxRect;
	var exit:FlxRect;
	var goal:FlxRect;
	
	var referenceArea:FlxRect;
	
	var freeMotionSpeed: Float = 3 * 64;
	
	var posX:Float = 0;
	var posY:Float = 0;
	
	var moveDir:MoveDirection = MoveDirection.None;
	
	public var playerDropped:FlxSignal = new FlxSignal();
	public var playerReachedGoal:FlxSignal = new FlxSignal();
	
	public function new() 
	{
		super();
		makeGraphic(24, 32);
	}
	
	public function initFree(x:Float, y:Float, grid:Grid, entrance:FlxSprite, exit:FlxSprite, goal:FlxRect):Void
	{
		color = FlxColor.WHITE;
		alpha = 1;
		scale.set(1, 1);
		updateHitbox();
		
		
		this.grid = grid;
		this.entrance = FlxRect.get(entrance.x, entrance.y, entrance.width, entrance.height);
		this.exit = FlxRect.get(exit.x, exit.y, exit.width, exit.height);
		this.goal = goal;
		referenceArea = this.entrance;
		
		
		drag.x = drag.y = 1600;
		setPosition(x, y);
		
		updateFunction = updateFreeMovement;
		FlxG.watch.add(this, "x");
		FlxG.watch.add(this, "y");
		FlxG.watch.add(this, "posX");
		FlxG.watch.add(this, "posY");
		FlxG.watch.add(this, "width");
		FlxG.watch.add(this, "height");
		FlxG.watch.add(this, "graphic");
		FlxG.watch.add(this, "color");
		FlxG.watch.add(this, "visible");
		FlxG.watch.add(this, "exists");
	}
	
	public function initGrid(x:Int, y:Int, grid:Grid, entrance:FlxSprite, exit:FlxSprite):Void
	{
		makeGraphic(24, 32, FlxColor.WHITE);
		
		this.grid = grid;
		drag.x = drag.y = 1600;
		setCoords(x, y);
		
		updateFunction = updateFreeMovement;
	}
	
	public function enterGrid(col:Int, row:Int, stepped:Bool = true):Void
	{
		setCoords(col, row);
		if (stepped)
		{			
			grid.stepped(col, row);
			if (grid.getTileAtCoords(col, row) == Grid.INVALID_TILE_ID)
			{
				FlxTween.color(this, 0.5, FlxColor.WHITE, FlxColor.TRANSPARENT, {onComplete: function(t:FlxTween) {playerDropped.dispatch(); }});
				FlxTween.tween(this.scale, {x:0.15, y:0.15}, 0.3);
				updateFunction = updateDeath;
				return;
			}
		}
		updateFunction = updateGridMovement;
	}
	
	override public function setPosition(newX:Float = 0, newY:Float = 0):Void
	{
		posX = newX;
		posY = newY;
		
		newX -= anchor.x * width;
		newY -= anchor.y * height;
		
		super.setPosition(newX, newY);
	}
	
	public function setCoords(col:Int, row:Int):Void
	{
		gridX = col;
		gridY = row;
		
		var pos:FlxPoint = grid.worldFromCoords(gridX, gridY);
		setPosition(pos.x, pos.y);
		pos.put();
	}
	
	override public function update(elapsed:Float):Void
	{
		updateFunction(elapsed);

	}
	
	function updateFreeMovement(elapsed:Float):Void
	{
		var dir:MoveDirection = move();
		super.update(elapsed);
	
		x = FlxMath.bound(x, referenceArea.x, referenceArea.x + referenceArea.width - width);
		y = FlxMath.bound(y, referenceArea.y, referenceArea.y + referenceArea.height - height);
		
		posX = x + anchor.x * width;
		posY = y + anchor.y * height;
		
		if (goal.containsPoint(FlxPoint.weak(posX, posY)))
		{
			playerReachedGoal.dispatch();
			updateFunction = updateDeath;
			return;
		}
		
		var gridRow:Int = -1;
		var gridCol:Int = -1;
				
		if (dir == MoveDirection.South && (Math.abs(posY - grid.y) < THRESHOLD_ENTER_GRID))
		{
			gridRow = 0;
			gridCol = grid.getClosestColumn(posX);
		}
		else if (dir == MoveDirection.North && (Math.abs(posY  - (grid.y + grid.height + height * anchor.y)) < THRESHOLD_ENTER_GRID))
		{
			gridRow = grid.heightInTiles - 1;
			gridCol = grid.getClosestColumn(posX);			
		}
		else if (dir == MoveDirection.East && (Math.abs(posX - grid.x) < THRESHOLD_ENTER_GRID))
		{
			gridRow = grid.heightInTiles - 1;
			gridCol = grid.getClosestRow(posY);			
		}
		else if (dir == MoveDirection.West && (Math.abs(posX - (grid.x + grid.width + width * anchor.x)) < THRESHOLD_ENTER_GRID))
		{
			gridRow = grid.heightInTiles - 1;
			gridCol = grid.getClosestRow(posY);			
		}
		
		if (grid.canBeStepped(gridCol, gridRow))
		{
			enterGrid(gridCol, gridRow, true);
		}
	}
	
	function updateGridMovement(elapsed:Float):Void
	{
		step();

		super.update(elapsed);
	}
	
	function step():MoveDirection
	{
		var deltaCol:Int = 0;
		var deltaRow:Int = 0;
		
		var dir:MoveDirection = MoveDirection.None;
		if (FlxG.keys.anyJustPressed([FlxKey.UP, FlxKey.W]))
		{
			dir = MoveDirection.North;
			deltaRow = -1;
		}
		else if (FlxG.keys.anyJustPressed([FlxKey.DOWN, FlxKey.S]))
		{
			dir = MoveDirection.South;
			deltaRow = 1;
		}
		else if (FlxG.keys.anyJustPressed([FlxKey.RIGHT, FlxKey.D]))
		{
			dir = MoveDirection.East;
			deltaCol = 1;
		}
		else if (FlxG.keys.anyJustPressed([FlxKey.LEFT, FlxKey.A]))
		{
			dir = MoveDirection.West;
			deltaCol = -1;
		}
		
		if (dir != MoveDirection.None)
		{
			var targetCol: Int = gridX + deltaCol;
			var targetRow: Int = gridY + deltaRow;
			if (grid.canBeStepped(targetCol, targetRow))
			{
				setCoords(targetCol, targetRow);
				grid.stepped(targetCol, targetRow);
				
				if (grid.getTileAtCoords(targetCol, targetRow) == Grid.INVALID_TILE_ID)
				{
					FlxTween.color(this, 0.5, FlxColor.WHITE, FlxColor.TRANSPARENT, {onComplete: function(t:FlxTween) {playerDropped.dispatch(); }});
					FlxTween.tween(this.scale, {x:0.15, y:0.15}, 0.3);
					updateFunction = updateDeath;
				}
				else
				{
					return dir;
				}
			}
			else if (targetRow == -1)
			{
				enterFreeMovement(entrance);			
			}
			else if (targetRow == grid.heightInTiles)
			{
				enterFreeMovement(exit);
			}			
		}

		return dir;
	}
	
	function enterFreeMovement(refRect:FlxRect):Void
	{
		referenceArea = refRect;
		if (referenceArea == entrance)
		{			
			setPosition(posX, referenceArea.y + referenceArea.height - ENTER_FREE_MOVEMENT_OFFSET);
		}
		else if (referenceArea == exit)
		{
			setPosition(posX, referenceArea.y + ENTER_FREE_MOVEMENT_OFFSET);
		}
		updateFunction = updateFreeMovement;
	}
	
	function move():MoveDirection
	{
		var speed:Float = 0;
		var angle:Float = 0;
		var dir:MoveDirection = MoveDirection.None;
		if (FlxG.keys.anyPressed([FlxKey.UP, FlxKey.W]))
		{
			speed = freeMotionSpeed;
			angle = 270;
			dir = MoveDirection.North;
		}
		else if (FlxG.keys.anyPressed([FlxKey.DOWN, FlxKey.S]))
		{
			speed = freeMotionSpeed;
			angle = 90;
			dir = MoveDirection.South;
		}
		else if (FlxG.keys.anyPressed([FlxKey.RIGHT, FlxKey.D]))
		{
			speed = freeMotionSpeed;
			angle = 0;
			dir = MoveDirection.East;
		}
		else if (FlxG.keys.anyPressed([FlxKey.LEFT, FlxKey.A]))
		{
			speed = freeMotionSpeed;
			angle = 180;
			dir = MoveDirection.West;
		}
		
		if (speed > 0)
		{
			velocity.set(speed, 0);
			velocity.rotate(FlxPoint.weak(), angle);
		}
		
		return dir;
	}
	
	public function updateDeath(elapsed:Float):Void
	{		
	}
	
	
}