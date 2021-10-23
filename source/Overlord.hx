package;

import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import flixel.math.FlxVector;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Overlord extends FlxSprite {

    public var minions:FlxTypedGroup<Minion> = new FlxTypedGroup<Minion>();
    var maxSpeed:Float = 165;
    var speed:Float = 165;
    public var target:FlxPoint;
    var velocityVector:FlxVector = new FlxVector();
    var type:Int = 0;

    public var playerControlled:Bool = false;

    public var attacking:Minion;

    public var isMinion:Bool = false;

    public var killedByType:Int = 1;

    public var centerX:Float = 0.0;
    public var centerY:Float = 0.0;

    var iX:Float = 0.0;
    var iY:Float = 0.0;

    // for AI attack and defense //
    public var otherOverlordInRange:Overlord;
    public var otherOverlordDetectionRange:Float = 650;
    public var otherOverlordProtected:Bool = true;
    public var otherOverlordProtectedRange:Float = 300;
    public var minOverlordProtected:Int = 4;
    public var minMinionProtected:Int = 5;
    public var minionWithinRange:Minion;
    public var minionProtected:Bool = true;

    // for iterating through minion behavior a few steps each frame //
    public var overlordIndex:Int = 0;
    public var minionIndex:Int = 0;
    public var minionStep:Int = 10;

    public var state:Int = 0;

    static public inline var IDLE = 0;
    static public inline var ATTACKING_OVERLORD = 1;
    static public inline var ATTACKING_MINIONS = 2;
    static public inline var RETREATING = 3;


    public function new(X:Float, Y:Float, T:Int, NumMinions:Int) {
        super(X, Y);

        type = T;
        switch (type) {
            case 1:
                frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/overlord_yellow.png", "assets/images/overlord.json");
                playerControlled = true;
            case 2:
                frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/overlord_blue.png", "assets/images/overlord.json");
            case 3:
                frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/overlord_green.png", "assets/images/overlord.json");
        }

        animation.frameName = "overlord_idle1.png";

        animation.addByStringIndices("idle", "overlord_idle", ["1", "2"], ".png", 2, true);
        animation.addByStringIndices("run", "overlord_run", ["2", "3", "4", "5", "6", "7", "8"], ".png", 9, true);
        animation.addByStringIndices("attack", "overlord_attack", ["1", "2", "2"], ".png", 6, false);
        animation.addByStringIndices("attack_minion", "overlord_kick", ["1"], ".png", 4, false);
        animation.addByStringIndices("death", "overlord_death", ["1", "2", "3", "4"], ".png", 7, false);
        
        animation.play("idle");

        animation.callback = animationCallback;

        width = 45 * 2;
        height = 22 * 2;
        offset.x = 25 - 22.5;
        offset.y = 162 - 11;

        centerX = x + width * 0.5;
        centerY = y + height * 0.5;

        iX = X;
        iY = Y;

        for (i in 0...NumMinions) {
            minions.add(new Minion(X + FlxG.random.floatNormal(0, 50), Y + FlxG.random.floatNormal(0, 50), type));
        }

        health = 750;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        centerX = x + width * 0.5;
        centerY = y + height * 0.5;


        if (playerControlled && alive && animation.name.substr(0, 6) != "attack") {
            velocityVector.set(0.0, 0.0);

        
            if (FlxG.keys.pressed.RIGHT || FlxG.keys.pressed.D) {
                velocityVector.x++;
            }
            if (FlxG.keys.pressed.LEFT || FlxG.keys.pressed.A) {
                velocityVector.x--;
            }
            if (FlxG.keys.pressed.DOWN || FlxG.keys.pressed.S) {
                velocityVector.y++;
            }
            if (FlxG.keys.pressed.UP || FlxG.keys.pressed.W) {
                velocityVector.y--;
            }
        

            velocityVector.length = speed;
            velocity.set(velocityVector.x, velocityVector.y);
        }

        if (!playerControlled && alive) {
            if (target != null) {
                moveTowardsTarget();
            }
        }

        
        if (velocity.x < -0.1) {
            setFlipX(true);
        }
        else if (velocity.x > 0.1) {
            setFlipX(false);
        }

        if (alive) {
            if (animation.name.substr(0, 6) != "attack") {
                if (!(velocity.x == 0 && velocity.y == 0)) {
                    animation.play("run");
                }
                else {
                    animation.play("idle");
                }

                speed = maxSpeed;
            }
            else {
                speed = maxSpeed * 0.4;
            }
        }



        // "AI" //
        if (!playerControlled && alive) {
            if (otherOverlordInRange != null && !otherOverlordProtected && animation.name.substr(0, 6) != "attack" /*&& target == null*/) {
                state = ATTACKING_OVERLORD;
                if (Math.abs(otherOverlordInRange.x - x) > 90 || Math.abs(otherOverlordInRange.y - y) > 30) {
                    //setTarget(otherOverlordInRange.x, otherOverlordInRange.y);
                    if (otherOverlordInRange.centerX < centerX)
                        setTarget(otherOverlordInRange.x + otherOverlordInRange.width * 0.02, otherOverlordInRange.y);
                    else
                        setTarget(otherOverlordInRange.x - otherOverlordInRange.width * 0.02, otherOverlordInRange.y);
                }
            }
            /*else if (minionWithinRange != null && !minionProtected && animation.name.substr(0, 6) != "attack") {
                state = ATTACKING_MINIONS;

            }*/
            else if (animation.name.substr(0, 6) != "attack" && (Math.abs(x - iX) + Math.abs(y - iY) > 50)) {
                state = RETREATING;
                setTarget(iX, iY);
            }
            else if (animation.name.substr(0, 6) != "attack") {
                state = IDLE;
                target = null;
                velocity.set(0.0, 0.0);
            }
        }


        if (health <= 0 && alive) {
            alive = false;
            target = null;
            drag.set(250, 250);
            if (animation.name != "death") {
                animation.play("death");

                for (i in 0...minions.members.length) {
                    if (!minions.members[i].alive) continue;
                    if (killedByType == 1) 
                        cast(FlxG.state, PlayState).selectionCircle.playerMinions.add(minions.members[i]);
                    minions.members[i].type = killedByType;
                    switch (killedByType) {
                        case 1:
                            minions.members[i].frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/minion_yellow.png", "assets/images/minion.json");
                        case 2:
                            minions.members[i].frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/minion_blue.png", "assets/images/minion.json");
                        case 3:
                            minions.members[i].frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/minion_green.png", "assets/images/minion.json");
                        case 4:
                            minions.members[i].frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/minion_purple.png", "assets/images/minion.json");
                        case 5:
                            minions.members[i].frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/minion_red.png", "assets/images/minion.json");
                    }
                        
                    minions.members[i].animation.addByStringIndices("idle", "minion_idle", ["1", "2"], ".png", 2, true);
                    minions.members[i].animation.addByStringIndices("run", "minion_run", ["2", "3", "4", "5", "6", "7", "8"], ".png", 9, true);
                    minions.members[i].animation.addByStringIndices("attack", "minion_attack", ["1", "2", "2"], ".png", 6, false);
                    minions.members[i].animation.addByStringIndices("death", "minion_death", ["1", "2", "3", "4"], ".png", 7, false);
                    minions.members[i].animation.play("idle");
                    minions.members[i].animation.callback = animationCallback;
                    minions.members[i].width = 23 * 2;
                    minions.members[i].height = 18 * 2;
                    if (minions.members[i].flipX)
                        minions.members[i].offset.x = 28 - 11.5;
                    else
                        minions.members[i].offset.x = 4 - 11.5;
                    minions.members[i].offset.y = 28 - 9;

                    cast(FlxG.state, PlayState).overlords.members[killedByType - 1].minions.add(minions.members[i]);
                }
                
            }

            if (playerControlled) {
                // GAME OVER
            }
        }
    }

    function animationCallback(name:String, frameNumber:Int, frameIndex:Int)
    {
        if (name == null) return;  // maybe this prevents a bug that happened once.
        if (!alive) return;

        if (name.substr(0, 6) == "attack") {
            if (animation.finished) {
                animation.play("idle");
                if (health > 0)
                    attacking.health -= 38;
                if (attacking.health <= 0) {
                    attacking.killedByType = type;
                }
            }
        }
    }

    public function setTarget(X:Float, Y:Float)
    {
        target = new FlxPoint(X, Y);
    }
    
    function moveTowardsTarget()
    {
        velocityVector.x = target.x - x;
        velocityVector.y = target.y - y;
    
        animation.play("run");
        animation.curAnim.frameRate = 9;
    
        
        if (velocityVector.lengthSquared > speed * speed)
            velocityVector.length = speed;
        else {
            if (velocityVector.lengthSquared < 65) {  // reached target
                target = null;
                velocity.set(0.0, 0.0);
                animation.play("idle");
                if (state == RETREATING)
                    state = IDLE;
                return;
            }
            else {
                animation.curAnim.frameRate = 60 * (velocityVector.length / speed);
                if (animation.curAnim.frameRate > 9)
                    animation.curAnim.frameRate = 9;
            }
        }
    
        velocity.set(velocityVector.x, velocityVector.y);
    
        if (velocity.x < 0) {
            setFlipX(true);
        }
        else if (velocity.x > 0) {
            setFlipX(false);
        }
    }

    public function setFlipX(flip:Bool)
    {
        if (flip) {
            flipX = true;
            offset.x = 133 - 22.5;
        }
        else {
            flipX = false;
            offset.x = 25 - 22.5;
        }
    }
}