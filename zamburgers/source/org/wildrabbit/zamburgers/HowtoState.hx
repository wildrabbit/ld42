package org.wildrabbit.zamburgers;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;

/**
 * ...
 * @author Ithil
 */
class HowtoState extends FlxState 
{
	override public function create():Void
	{
		super.create();
		FlxG.mouse.visible = false;
		
		var sp:FlxSprite = new FlxSprite(0, 0, "assets/images/howto.png");
		add(sp);
		
		var press:FlxText = new FlxText(20, FlxG.height - 20, 200, "Press any key to continue", 10);
		add(press);
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