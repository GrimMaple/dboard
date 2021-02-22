import std.stdio;

import dlangui;

import keyboard;
import keystrings;

mixin APP_ENTRY_POINT;

int code = 0;
KeyState gstate = KeyState.Up;

immutable keySize = 48;
immutable keyOffset = 3;

bool[] keys = new bool[256];

bool isWhole(float f)
{
    if(f - cast(int)f != 0)
        return false;
    return true;
}

struct KeyDisplay
{
    float locx = 0, locy = 0;
    int keyCode = 0;
    float w = 1, h = 1;

    @property void visibleString(dstring str)
    {
        this.str = str;
    }

    @property dstring visibleString()
    {
        import std.conv : to;
        if(str == "")
            return keyStrings[keyCode];
        return str;
    }

    private dstring str;
}

KeyDisplay temporary;

bool editMode = false;

KeyDisplay[] keysDisp = new KeyDisplay[5];

enum KeyEnd
{
    Left,
    Right
}

bool dragLeft = false;
bool dragRight = false;
bool dragTop = false;
bool dragBottom = false;
KeyDisplay* drag = null;

KeyDisplay n;
bool addMode = false;

bool hasOffset = false;
int xoffs = 0, yoffs = 0;

int getLocOnGrid(KeyEnd end = KeyEnd.Left)(float gridPos)
{
    static if(end == KeyEnd.Left)
        return keyOffset + cast(int)(cast(int)(gridPos) * keyOffset + gridPos * keySize);
    else
        return getLocOnGrid!(KeyEnd.Left)(gridPos) - keyOffset;
}

float getGridLoc(int val)
{
    return cast(float)(val - keyOffset)/cast(float)(keyOffset + keySize);
}

bool withinGridRange(int coord, float a, float b)
{
    import std.algorithm : min, max;
    
    if(coord >= getLocOnGrid!(KeyEnd.Left)(min(a, b)) &&
       coord <= getLocOnGrid!(KeyEnd.Right)(max(a, b)))
        return true;
    return false;
}

float threeWayRound(float input)
{
    float x = input - cast(int)input;
    if(x < 0.2)
        return input - x;
    if(x < 0.6 && x > 0.4)
        return input - x + 0.5;
    if(x > 0.8)
        return input - x + 1;
    return input;
}

void resetDragProperties()
{
    drag = null;
    hasOffset = false;
    dragLeft = false;
    dragRight = false;
    dragTop = false;
    dragBottom = false;
}

extern(C) int UIAppMain()
{
    keysDisp[0].keyCode = 0x70;
    keysDisp[0].visibleString = "F1";

    keysDisp[1].keyCode = 0x51;
    keysDisp[1].locx = 2.5;

    keysDisp[2].keyCode = 0x57;
    keysDisp[2].locx = 1;
    keysDisp[2].w = 1.5;

    keysDisp[3].keyCode = 0x45;
    keysDisp[3].locx = 3.5;
    keysDisp[3].w = 1.5;

    keysDisp[4].keyCode = 0x52;
    keysDisp[4].locx = 5;
    keysDisp[4].w = 1;

    immutable str = "QWERTYUIOP";
    Window window = Platform.instance.createWindow("DBoard", null, WindowFlag.Resizable, 400, 200);
    window.show();
    keys[] = false;

    CanvasWidget canvas = new CanvasWidget("canvas");

    MenuItem mainMenu = new MenuItem();
    MenuItem sub = new MenuItem(new Action(0, "Toggle edit"d));
    MenuItem subAdd = new MenuItem(new Action(1, "Add new"d));
    mainMenu.add(sub);
    sub.menuItemClick = delegate(MenuItem item)
    {
        editMode = !editMode;
        if(editMode)
        {
            mainMenu.add(subAdd);
        }
        else
        {
            mainMenu.clear();
            mainMenu.add(sub);
        }
        return true;
    };

    subAdd.menuItemClick = delegate(MenuItem item)
    {
        addMode = true;
        return true;
    };

    canvas.popupMenu = mainMenu;

    canvas.mouseEvent = delegate(Widget source, MouseEvent event)
    {
        import std.math : abs;
        canvas.popupMenu = mainMenu;
        if(!editMode)
        {
            return false;
        }
        if(addMode)
        {
            n.locx = threeWayRound(getGridLoc(event.x));
            n.locy = threeWayRound(getGridLoc(event.y));
            if(event.lbutton.isDown)
            {
                KeyDisplay copy = n;
                keysDisp ~= [copy];
                addMode = false;
            }
            canvas.invalidate();
            window.invalidate();
            return true;
        }
        if(event.lbutton.isDown)
        {
            if(dragRight)
            {
                drag.w = threeWayRound(getGridLoc(event.x) - drag.locx);
                canvas.invalidate();
                window.invalidate();
                return true;
            }
            else if(dragLeft)
            {
                return true;
            }
            else if(dragTop)
            {
                return true;
            }
            else if(dragBottom)
            {
                drag.h = threeWayRound(getGridLoc(event.y) - drag.locy);
                canvas.invalidate();
                window.invalidate();
                return true;
            }
            else if(drag !is null) // Drag the whole button
            {
                if(!hasOffset)
                {
                    hasOffset = true;
                    xoffs = getLocOnGrid(drag.locx) - event.x;
                    yoffs = getLocOnGrid(drag.locy) - event.y;
                }
                drag.locx = threeWayRound(getGridLoc(event.x + xoffs));
                drag.locy = threeWayRound(getGridLoc(event.y + yoffs));
                canvas.invalidate();
                window.invalidate();
                return true;
            }
        }
        foreach(i, ref disp; keysDisp)
        {
            if(withinGridRange(event.y, disp.locy, disp.locy + disp.h))
            {
                resetDragProperties();
                if(abs(getLocOnGrid!(KeyEnd.Left)(disp.locx) - event.x) < 5)
                {
                    dragLeft = true;
                    window.overrideCursorType(CursorType.SizeWE);
                    drag = &disp;
                    return true;
                }
                if(abs(getLocOnGrid!(KeyEnd.Right)(disp.locx + disp.w) - event.x) < 5)
                {
                    dragRight = true;
                    drag = &disp;
                    window.overrideCursorType(CursorType.SizeWE);
                    return true;
                }
            }
            if(withinGridRange(event.x, disp.locx, disp.locx + disp.w))
            {
                resetDragProperties();
                if(abs(getLocOnGrid!(KeyEnd.Left)(disp.locy) - event.y) < 5)
                {
                    dragTop = true;
                    window.overrideCursorType(CursorType.SizeNS);
                    drag = &disp;
                    return true;
                }
                if(abs(getLocOnGrid!(KeyEnd.Right)(disp.locy + disp.h) - event.y) < 5)
                {
                    dragBottom = true;
                    drag = &disp;
                    window.overrideCursorType(CursorType.SizeNS);
                    return true;
                }
            }
            if(withinGridRange(event.y, disp.locy, disp.locy + disp.h) &&
               withinGridRange(event.x, disp.locx, disp.locx + disp.w))
            {
                if(event.rbutton.isDown)
                {
                    MenuItem itm = new MenuItem();
                    MenuItem del = new MenuItem(new Action(0, "Delete"d));
                    del.menuItemClick = delegate(MenuItem item)
                    {
                        keysDisp = keysDisp[0 .. i] ~ keysDisp[i+1 .. $];
                        canvas.popupMenu = mainMenu;
                        return true;
                    };
                    itm.add(del);
                    canvas.popupMenu = itm;
                    canvas.showPopupMenu(event.x, event.y);
                }
                resetDragProperties();
                drag = &disp;
                window.overrideCursorType(CursorType.SizeAll);
                return true;
            }
        }
        resetDragProperties();
        window.overrideCursorType(CursorType.Arrow);
        return false;
    };

    canvas.keyEvent = delegate(Widget source, KeyEvent event)
    {
        return false;
    };

    canvas.layoutWidth(FILL_PARENT).layoutHeight(FILL_PARENT);
    canvas.onDrawListener = delegate(CanvasWidget c, DrawBuf buf, Rect rc)
    {
        import std.conv : to;
        buf.fill(0x00FF00);

        void drawDisp(ref KeyDisplay disp, uint color)
        {
            auto s = disp.visibleString;
            auto sz = c.font.textSize(s);
            immutable x = getLocOnGrid!(KeyEnd.Left)(disp.locx);
            immutable y = getLocOnGrid!(KeyEnd.Left)(disp.locy);
            immutable pxWidth = getLocOnGrid!(KeyEnd.Right)(disp.locx + disp.w) - getLocOnGrid!(KeyEnd.Left)(disp.locx);
            immutable pxHeight = getLocOnGrid!(KeyEnd.Right)(disp.locy + disp.h) - getLocOnGrid!(KeyEnd.Left)(disp.locy);
            buf.fillRect(Rect(x, y, x + pxWidth, y + pxHeight), color);
            c.font.drawText(buf, x + pxWidth/2 - sz.x/2, y+pxHeight/2 - sz.y/2, s, 0x0);
        }

        // Draw grid in edit mode
        if(editMode)
        {
            int x = keyOffset;
            while(x < window.width)
            {
                buf.drawLine(Point(x, 0), Point(x, window.height), 0x0);
                x += keyOffset + keySize;
            }
            int y = keyOffset;
            while(y <= window.height)
            {
                buf.drawLine(Point(0, y), Point(window.width, y), 0);
                y += keyOffset + keySize;
            }
        }

        for(int i=0; i<keysDisp.length; i++)
        {
            import std.math : ceil;
            immutable  idx = keysDisp[i].keyCode;
            immutable color = keys[idx] ? 0xCCCCCC : 0x777777;
            drawDisp(keysDisp[i], color);
        }

        if(addMode)
        {
            drawDisp(n, 0x99999999);
        }

        c.font.drawText(buf, 100, 100, to!dstring(code) ~ " " ~ to!dstring(gstate), 0x0);
    };

    window.mainWidget = canvas;

    KeyHook.get().OnAction = (int vkCode, KeyState state)
    {
        if(addMode && state == KeyState.Down)
        {
            if(n.keyCode == 0x1B && vkCode == 0x1B) // ESCAPE
            {
                addMode = false;
            }
            else
            {
                n.keyCode = vkCode;
            }
        }
        code = vkCode;
        keys[code] = (state == KeyState.Down) ? true : false;
        gstate = state;
        canvas.invalidate();
        window.invalidate();
    };
    return Platform.instance.enterMessageLoop();
}