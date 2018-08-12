package org.wildrabbit.zamburgers;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;

/**
 * ...
 * @author Ithil
 */
class GameWonState extends FlxState 
{
	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = false;
		
		var sp:FlxSprite = new FlxSprite(0, 0, "assets/images/gover.png");
		add(sp);
	}
	
	override public function update(dt:Float):Void
	{
		super.update(dt);
		
		if (FlxG.keys.justReleased.ANY)
		{
			FlxG.switchState(new PlayState());
		}
	}
}