package;

import flixel.math.FlxVector;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class Minion extends FlxSprite
{
    var speed:Float = 58;
    public var target:FlxPoint;
    var velocityVector:FlxVector = new FlxVector();
    //var velocityVectorLength:Float = 0.0;

    public var selectionOffsetX:Float = 0;
    public var selectionOffsetY:Float = 0;

    public var type:Int = 1;

    public var attacking:Minion;

    public var isMinion:Bool = true;
    public var killedByType:Int = 0;

    public var centerX:Float = 0.0;
    public var centerY:Float = 0.0;

    // for AI attack and defense //
    public var otherOverlordInRange:Overlord;
    public var otherOverlordDetectionRange:Float = 500;
    public var otherOverlordProtected:Bool = true;
    public var otherOverlordProtectedRange:Float = 150;
    public var minOverlordProtected:Int = 8;
    public var minionWithinRange:Minion;
    public var minionProtected:Bool = true;
    public var minMinionProtected:Int = 5;
    public var ownOverlord:Overlord;
    public var ownOverlordNearby:Bool = false;
    public var ownOverlordUnderAttack:Bool = false;

    public var state:Int = 0;

    static public inline var IDLE = 0;
    static public inline var ATTACKING_OVERLORD = 1;
    static public inline var ATTACKING_MINIONS = 2;
    static public inline var RETREATING = 3;
    static public inline var PROTECTING_OVERLORD = 4;

    public function new(X:Float, Y:Float, T:Int)
    {
        super(X, Y);
        
        type = T;
        switch (type) {
            case 1:
                frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/minion_yellow.png", "assets/images/minion.json");
            case 2:
                frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/minion_blue.png", "assets/images/minion.json");
            case 3:
                frames = FlxAtlasFrames.fromTexturePackerJson("assets/images/minion_green.png", "assets/images/minion.json");
        }
       
        animation.frameName = "minion_idle1.png";

        animation.addByStringIndices("idle", "minion_idle", ["1", "2"], ".png", 2, true);
        animation.addByStringIndices("run", "minion_run", ["2", "3", "4", "5", "6", "7", "8"], ".png", 9, true);
        animation.addByStringIndices("attack", "minion_attack", ["1", "2", "2"], ".png", 6, false);
        animation.addByStringIndices("death", "minion_death", ["1", "2", "3", "4"], ".png", 7, false);
        
        animation.play("idle");
        animation.callback = animationCallback;
        
        width = 23 * 2;
        height = 18 * 2;
        offset.x = 4 - 11.5;
        offset.y = 28 - 9;

        health = 40;

        centerX = x + width * 0.5;
        centerY = y + height * 0.5;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        centerX = x + width * 0.5;
        centerY = y + height * 0.5;


        if (target != null) {
            moveTowardsTarget();
        }

        if (health <= 0) {
            alive = false;
            if (animation.name != "death")
                animation.play("death");
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

        //velocityVectorLength = velocityVector.length;

        if (velocityVector.lengthSquared > speed * speed)
            velocityVector.length = speed;
        else {
            if (velocityVector.lengthSquared < 25) {
                target = null;
                velocity.set(0.0, 0.0);
                animation.play("idle");
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

    function animationCallback(name:String, frameNumber:Int, frameIndex:Int)
    {
        if (name == "attack") {
            if (animation.finished) {
                animation.play("idle");
                attacking.health -= 10;
                if (attacking.health <= 0) {
                    attacking.killedByType = type;
                }
            }
        }
    }

    public function setFlipX(flip:Bool)
    {
        if (flip) {
            flipX = true;
            offset.x = 28 - 11.5;
        }
        else {
            flipX = false;
            offset.x = 4 - 11.5;
        }
    }
}