package;

import flixel.util.FlxColor;
import flixel.FlxObject;
import flixel.FlxCamera.FlxCameraFollowStyle;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;

class PlayState extends FlxState
{
	public var selectionCircle:SelectionCircle;

	public var overlords:FlxTypedGroup<Overlord> = new FlxTypedGroup<Overlord>();

	var sortedGroup:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	var sortedIndex:Int = 0;
	var sortedIndexStep:Int = 10;

	var overlordIndex:Int = 0;

	var minionCount:Int = 0;  // for temporary overlap-related calculations.

	var bgSprites:FlxTypedGroup<FlxSprite> = new FlxTypedGroup<FlxSprite>();

	var won:FlxSprite;

	var lost:Bool = false;

	override public function create():Void
	{
		super.create();

		flixelInit();

		for (i in 0...80) {
			bgSprites.add(new FlxSprite(FlxG.random.int(-400, FlxG.width + 200), FlxG.random.int(-400, FlxG.height + 150), 
										"assets/images/grass" + FlxG.random.int(1, 3) + ".png"));
			if (FlxG.random.bool())
				bgSprites.members[bgSprites.members.length - 1].flipX = true;
		}
		add(bgSprites);

		selectionCircle = new SelectionCircle(FlxG.width * 0.5, FlxG.height * 0.5);
		
		
		overlords.add(new Overlord(FlxG.width * 0.5, FlxG.height * 0.5, 1, 40));
		overlords.add(new Overlord(FlxG.width * 0.78, FlxG.height * 0.2, 2, 50));
		overlords.add(new Overlord(-6, -40, 3, 60));

		FlxG.camera.follow(overlords.members[0], FlxCameraFollowStyle.TOPDOWN_TIGHT);


		selectionCircle.playerMinions = overlords.members[0].minions;

		for (i in 0...overlords.members.length) {
			sortedGroup.add(overlords.members[i]);
			for (j in 0...overlords.members[i].minions.members.length) {
				sortedGroup.add(overlords.members[i].minions.members[j]);
			}
		}
		add(sortedGroup);

		add(selectionCircle);

		won = new FlxSprite(205, 85, "assets/images/win.png");
		won.exists = false;
		won.scrollFactor.set(0.0, 0.0);
		add(won);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Z sorting (inefficient) //
		for (i in 0...sortedGroup.members.length) {
			sortedGroup.members.sort(function(a, b):Int {
				if (a.y + a.height < b.y + b.height) return -1;
				else if (a.y + a.height > b.y + b.height) return 1;
				return 0;
		  });
		}

		for (i in 0...sortedIndexStep) {
			FlxG.overlap(sortedGroup.members[sortedIndex], sortedGroup, stepAside);
			sortedIndex++;
			if (sortedIndex >= sortedGroup.members.length)
				sortedIndex = 0;
		}

		// "AI" //
		if (overlords.members[overlordIndex].alive && !overlords.members[overlordIndex].playerControlled) {
			// for attacking other Overlords //
			var closestOverlord:Int = -1;
			var shortestDistance:Float = 999999999;
			var distance:Float = 0;
			for (j in 0...overlords.length) {
				if (j == overlordIndex) continue;
				distance = Math.abs(overlords.members[overlordIndex].x - overlords.members[j].x) + Math.abs(overlords.members[overlordIndex].y - overlords.members[j].y);
				if (distance < shortestDistance) {
					shortestDistance = distance;
					closestOverlord = j;
				}
			}
			if (closestOverlord > -1 && shortestDistance <= overlords.members[overlordIndex].otherOverlordDetectionRange) {
				overlords.members[overlordIndex].otherOverlordInRange = overlords.members[closestOverlord];

				minionCount = 0;
				FlxG.overlap(overlords.members[closestOverlord].minions, 
							new FlxObject(overlords.members[closestOverlord].x - overlords.members[closestOverlord].otherOverlordProtectedRange * 0.5, 
										overlords.members[closestOverlord].y - overlords.members[closestOverlord].otherOverlordProtectedRange * 0.4,
										overlords.members[closestOverlord].otherOverlordProtectedRange, overlords.members[closestOverlord].otherOverlordProtectedRange * 0.8),
							countMinionsInArea);

				if (minionCount < overlords.members[overlordIndex].minOverlordProtected)
					overlords.members[overlordIndex].otherOverlordProtected = false;
				else
					overlords.members[overlordIndex].otherOverlordProtected = true;

				// set correct flip //
				if (overlords.members[overlordIndex].state != Overlord.RETREATING) {
					if (overlords.members[overlordIndex].x > overlords.members[closestOverlord].x)
						overlords.members[overlordIndex].setFlipX(true);
					else
						overlords.members[overlordIndex].setFlipX(false);
				}
			}
			else {
				overlords.members[overlordIndex].otherOverlordInRange = null;
			}


			if (overlords.countLiving() > 1) {
				// TODO //
				// for attacking enemy minions //
				// pick an overlord at random, then minions //
				
			}
		}
		overlordIndex++;
		if (overlordIndex >= overlords.length)
		overlordIndex = 0;
		
		if (overlords.countLiving() == 1 && overlords.members[0].alive) {
			won.exists = true;
			if (won.alpha > 0.99)
				won.alpha -= 0.002 * elapsed;
			else
				won.alpha -= 0.5 * elapsed;
		}

		if (!overlords.members[0].alive && !lost) {
			lost = true;
			FlxG.camera.fade(FlxColor.BLACK, 5.0, false, onFadeOut);
		}
	}

	function flixelInit()
	{
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.unload();
		FlxG.maxElapsed = 0.05;
		FlxG.fixedTimestep = false;
		#if html5
		FlxG.log.redirectTraces = true;
		#end
		//FlxG.camera.antialiasing = true;
		FlxG.camera.bgColor = 0xff435829;
		FlxG.worldBounds.set(-100000, -100000, 200000, 200000);
	}
	
	// shouldn't be named stepAside anymore, since this is also used for attacking //
	function stepAside(minion1:Minion, minion2:Minion)
	{
		if (!minion1.alive || !minion2.alive) return;

		// don't attack minions if going for overlord //
		/*if (minion1.state == Overlord.ATTACKING_OVERLORD && minion2.isMinion)
			return;
		if (minion2.state == Overlord.ATTACKING_OVERLORD && minion1.isMinion)
			return;*/

		// if not attacking, go towards enemy //
		if ((minion1.type != minion2.type) && 
			(minion1.animation.name.substr(0, 6) != "attack") && (minion2.animation.name.substr(0, 6) != "attack") && 
			minion1.isMinion /*&&
			minion1.state != Overlord.ATTACKING_OVERLORD*/) {

			if (minion1.x + minion1.width * 0.5 <= minion2.x + minion2.width * 0.5) {
				if (minion1.target == null)
					minion1.target = new FlxPoint();
				minion1.target.x = minion2.x;
			}
			else {
				if (minion1.target == null)
					minion1.target = new FlxPoint();
				minion1.target.x = minion2.x;
			}
			if (minion1.y + minion1.height * 0.5 <= minion2.y + minion2.height * 0.5) {
				minion1.target.y = minion2.y;
			}
			else {
				minion1.target.y = minion2.y;
			}
		}

		if (minion1.type != minion2.type && 
			(FlxG.overlap(new FlxObject(minion1.x + minion1.width * 0.2, minion1.y + minion1.height * 0.25, minion1.width * 0.6, minion1.height * 0.5),
						 new FlxObject(minion2.x + minion2.width * 0.2, minion2.y + minion2.height * 0.25, minion2.width * 0.6, minion2.height * 0.5)) || 
						 (!minion1.isMinion && !minion2.isMinion))) {
			
			if (minion1.animation.name.substr(0, 6) != "attack") {
				minion1.animation.play("attack");
				minion1.attacking = minion2;
				if (!minion1.isMinion) {
					if (minion2.isMinion) {
						minion1.animation.play("attack_minion");
					}
				}
				minion1.target = null;
				minion2.target = null;
				minion1.velocity.set(0.0, 0.0);
				minion2.velocity.set(0.0, 0.0);

				if (minion1.x + minion1.width * 0.5 < minion2.x + minion2.width * 0.5) {
					minion1.setFlipX(false);
					minion2.setFlipX(true);
				}
				else {
					minion1.setFlipX(true);
					minion2.setFlipX(false);
				}

			}

			return;
		}

		if (minion1.animation.name.substr(0, 6) == "attack" || minion2.animation.name.substr(0, 6) == "attack")
			return;


		var nearColObj1:FlxObject = new FlxObject(minion1.x + minion1.width * 0.25, minion1.y + minion1.height * 0.25, minion1.width * 0.5, minion1.height * 0.5);
		var nearColObj2:FlxObject = new FlxObject(minion2.x + minion2.width * 0.25, minion2.y + minion2.height * 0.25, minion2.width * 0.5, minion2.height * 0.5);

		if (minion1.target == null && nearColObj1.overlaps(nearColObj2) && minion1.isMinion) {
			
			if (minion1.centerX > minion2.centerX) {
				if (minion1.centerY > minion2.centerY)
					minion1.target = new FlxPoint(minion2.x + minion2.width * .5 + FlxG.random.int(1, 5), minion2.y + minion2.height * .5 + FlxG.random.int(1, 3));
				else
					minion1.target = new FlxPoint(minion2.x + minion2.width * .5 + FlxG.random.int(1, 5), minion2.y - minion1.height * .5 - FlxG.random.int(1, 3));
			}
			else {
				if (minion1.centerY > minion2.centerY)
					minion1.target = new FlxPoint(minion2.x - minion1.width * .5 - FlxG.random.int(1, 5), minion2.y + minion2.height * .5 + FlxG.random.int(1, 3));
				else
					minion1.target = new FlxPoint(minion2.x - minion1.width * .5 - FlxG.random.int(1, 5), minion2.y - minion1.height * .5 - FlxG.random.int(1, 3));
			}
		}
		if (minion2.target == null && nearColObj1.overlaps(nearColObj2) && minion2.isMinion) {
			
			if (minion2.centerX > minion1.centerX) {
				if (minion2.centerY > minion1.centerY)
					minion2.target = new FlxPoint(minion1.x + minion1.width * .5 + FlxG.random.int(1, 5), minion1.y + minion1.height * .5 + FlxG.random.int(1, 3));
				else
					minion2.target = new FlxPoint(minion1.x + minion1.width * .5 + FlxG.random.int(1, 5), minion1.y - minion2.height * .5 - FlxG.random.int(1, 3));
			}
			else {
				if (minion2.centerY > minion1.centerY)
					minion2.target = new FlxPoint(minion1.x - minion2.width * .5 - FlxG.random.int(1, 5), minion1.y + minion1.height * .5 + FlxG.random.int(1, 3));
				else
					minion2.target = new FlxPoint(minion1.x - minion2.width * .5 - FlxG.random.int(1, 5), minion1.y - minion2.height * .5 - FlxG.random.int(1, 3));
			}
		}
	}

	function countMinionsInArea(minion:Minion, object:FlxObject)
	{
		minionCount++;
	}

	function onFadeOut()
	{
		FlxG.switchState(new PlayState());
	}
}
