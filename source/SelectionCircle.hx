package;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.FlxSprite;
using flixel.util.FlxSpriteUtil;

class SelectionCircle extends FlxSprite {
    
    var lineThickness:Float = 0.0;
    var lineStyle:LineStyle;
    var drawStyle:DrawStyle = { smoothing: true };

    var borderSize:Int = 45;

    var diameter:Float = 10.0;
    var diameterMin:Float = 20.0;
    var diameterMax:Float = 500.0;

    var centerX:Float = 0.0;
    var centerY:Float = 0.0;
    var selectedCenterX:Float = 0.0;
    var selectedCenterY:Float = 0.0;

    var state:Int = 0;
    static public inline var IDLE:Int = 0;
    static public inline var SELECTING:Int = 1;
    static public inline var PLACING:Int = 2;

    public var playerMinions:FlxTypedGroup<Minion>;

    var selectedMinions:FlxTypedGroup<Minion> = new FlxTypedGroup<Minion>();

    public function new(CenterX:Float, CenterY:Float) {
        centerX = CenterX; centerY = CenterY;

        super(centerX - Std.int(diameter + lineThickness * 2) * 0.5, centerY - Std.int(diameter*.5 + lineThickness * 2) * 0.5);
        
        lineStyle = { color: FlxColor.TRANSPARENT, thickness: lineThickness };
        makeGraphic(Std.int(diameter + lineThickness * 2), Std.int(diameter*.5 + lineThickness * 2), FlxColor.TRANSPARENT, true);
        this.drawEllipse(borderSize, borderSize, diameter, diameter*.5, 0x55ffffff, lineStyle, drawStyle);

        visible = false;
    }

    override public function update(elapsed:Float)
    {
        
        if (state == IDLE && FlxG.mouse.justPressed) {
            state = SELECTING;
            diameter = diameterMin;
            visible = true;
        }
        if (state == SELECTING) {
            if (FlxG.mouse.pressed) {
                visible = true;
                if (diameter < diameterMax) {
                    diameter += elapsed * 135.0 + diameter * elapsed * 1.15;
                }
                else {
                    diameter = diameterMax;
                }

                centerX = FlxG.mouse.x;
                centerY = FlxG.mouse.y;


                makeGraphic(Std.int(diameter + borderSize * 2), Std.int(diameter + borderSize * 2), FlxColor.TRANSPARENT, true);
                
                this.drawEllipse(borderSize, borderSize, diameter, diameter, 0x35ffffff, lineStyle, drawStyle);
                blend = "add";
                x = centerX - diameter * 0.5 - borderSize;
                y = centerY - diameter * 0.5 - borderSize;
                pixelPerfectPosition = false;
                antialiasing = true;
            }
            else {
                if (FlxG.mouse.justReleased) {
                    last.x = x;
                    last.y = y;

                    selectedCenterX = FlxG.mouse.x;
                    selectedCenterY = FlxG.mouse.y;

                    selectedMinions.clear();
                    if (FlxG.overlap(this, playerMinions, selectionOverlap, confirmOverlap))
                        state = PLACING;
                    else {
                        state = IDLE;
                        visible = false;
                    }
                }

            }
        }
        if (state == PLACING) {
            centerX = FlxG.mouse.x;
            centerY = FlxG.mouse.y;
            x = centerX - diameter * 0.5 - borderSize;
            y = centerY - diameter * 0.5 - borderSize;

            if (FlxG.mouse.justPressed) {
                selectedMinions.forEachAlive(function(minion) minion.setTarget(x + minion.selectionOffsetX, y + minion.selectionOffsetY));
                state = IDLE;
                visible = false;
            }
        }
    }

    function confirmOverlap(circle:FlxSprite, minion:Minion)
    {
        var falseCount:Int = 0;
        
        // center //
        if ((((minion.x + minion.width * 0.5) - selectedCenterX) * ((minion.x + minion.width * 0.5) - selectedCenterX) + 
            ((minion.y) - selectedCenterY) * ((minion.y) - selectedCenterY)) > 
            (diameter * 0.5) * (diameter * 0.5)) {
            
            falseCount++;
        }

        // bottom //
        if ((((minion.x + minion.width * 0.5 + 12) - selectedCenterX) * ((minion.x + minion.width * 0.5 + 12) - selectedCenterX) + 
            ((minion.y + minion.height) - selectedCenterY) * ((minion.y + minion.height) - selectedCenterY)) > 
            (diameter * 0.5) * (diameter * 0.5)) {
            
            falseCount++;
        }
        if ((((minion.x + minion.width * 0.5 - 12) - selectedCenterX) * ((minion.x + minion.width * 0.5 - 12) - selectedCenterX) + 
            ((minion.y + minion.height) - selectedCenterY) * ((minion.y + minion.height) - selectedCenterY)) > 
            (diameter * 0.5) * (diameter * 0.5)) {
            
            falseCount++;
        }


        // top //
        if ((((minion.x + minion.width * 0.5 + 12) - selectedCenterX) * ((minion.x + minion.width * 0.5 + 12) - selectedCenterX) + 
            ((minion.y - 12) - selectedCenterY) * ((minion.y - 12) - selectedCenterY)) > 
            (diameter * 0.5) * (diameter * 0.5)) {
            
            falseCount++;
        }
        if ((((minion.x + minion.width * 0.5 - 12) - selectedCenterX) * ((minion.x + minion.width * 0.5 - 12) - selectedCenterX) + 
            ((minion.y - 12) - selectedCenterY) * ((minion.y - 12) - selectedCenterY)) > 
            (diameter * 0.5) * (diameter * 0.5)) {
            
            falseCount++;
        }

        if (falseCount == 5)
            return false;

        return true;
    }

    function selectionOverlap(circle:FlxSprite, minion:Minion)
    {
        if (!minion.alive)
            return;
        
        minion.alpha = 0.19;
        stamp(minion, Std.int(minion.x - minion.offset.x - circle.x), Std.int(minion.y - minion.offset.y - circle.y));
        minion.selectionOffsetX = minion.x - circle.x;
        minion.selectionOffsetY = minion.y - circle.y;
        minion.alpha = 1.0;
        selectedMinions.add(minion);
    }

}