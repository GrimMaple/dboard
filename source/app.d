import std.stdio;
import std.json;
import std.conv : to;
import std.functional : toDelegate;

import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;

import mud.config;

import keyboard;
import keystrings;
import ui;
import keys;
import io;
import util;

mixin APP_ENTRY_POINT;

int code = 0;
KeyState gstate = KeyState.Up;

bool[] keysStates = new bool[256];

KeyDisplay temporary;

enum KeyEnd
{
    Left,
    Right
}

Window window = null;

bool dragLeft = false;
bool dragRight = false;
bool dragTop = false;
bool dragBottom = false;
KeyDisplay* drag = null;

bool changingName = false;

bool changingHotkey = false;

KeyDisplay* nameEditing = null;

immutable minWidth = 400;
immutable minHeight = 400;

KeyDisplay n;

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

void loadPreferences()
{
    import std.file : exists, readText;
    if(exists("prefs"))
        deserializeConfig(prefs, "prefs");

    if(prefs.lastJson != "")
    {
        if(exists(prefs.lastJson))
            keysDisp = loadJsonFile(readText(prefs.lastJson));
    }
}

auto figureOutWindowSize()
{
    import std.algorithm : max;
    float maxx = 0, maxy = 0;
    foreach(keyDisp; keysDisp)
    {
        maxx = max(maxx, keyDisp.locx);
        maxy = max(maxy, keyDisp.locy);
    }

    immutable width = max(getLocOnGrid!(KeyEnd.Right)(maxx + keyOffset)+ keyOffset, minWidth);
    immutable height = max(getLocOnGrid!(KeyEnd.Right)(maxy + keyOffset) + keyOffset, minHeight);

    // I don't know why dlnagui does this to me, but it sizes the window by 92 more pixels than requested
    window.resizeWindow(Point(width-92, height-92));
    return Point(width, height);
}

void storePreferences()
{
    serializeConfig(prefs, "prefs");
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

void cancelEditing(VerticalLayout vl)
{
    if(changingName && nameEditing)
    {
        changingName = false;
        nameEditing.visibleString = vl.childById!EditLine("editText").text;
        nameEditing = null;
        vl.removeChild("editText");
        vl.invalidate();
    }
}

KeyDisplay* selectDispAtPosition(in Point loc)
{
    foreach(i, ref disp; keysDisp)
    {
        if(withinGridRange(loc.y, disp.locy, disp.locy + disp.h) &&
            withinGridRange(loc.x, disp.locx, disp.locx + disp.w))
        {
            return &disp;
        }
    }
    return null;
}

bool enableTextEditing(in Point loc, VerticalLayout vl)
{
    EditLine textEdit = new EditLine("editText");
    textEdit.layoutHeight(30).layoutWidth(FILL_PARENT);
    textEdit.visibility = Visibility.Invisible;

    textEdit.enterKey = delegate(EditWidgetBase w)
    {
        cancelEditing(vl);
        return true;
    };


    nameEditing = selectDispAtPosition(loc);
    if(nameEditing !is null)
    {
        vl.addChild(textEdit);
        textEdit.text = nameEditing.visibleString();
        textEdit.visibility = Visibility.Visible;
        changingName = true;
        textEdit.setFocus();
        return true;
    }
    return false;
}

private void drawGrid(DrawBuf buf)
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

private void drawDisp(DrawBuf buf, CanvasWidget c, ref KeyDisplay disp, uint color)
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

private void onDraw(CanvasWidget c, DrawBuf buf, Rect rc)
{
    import std.conv : to;
    buf.resize(window.width, window.height);
    buf.fill(to!uint(prefs.keyColor, 16));

    c.fontFace = "Arial";

    // Draw grid in edit mode
    if(editMode)
    {
        drawGrid(buf);
    }
    foreach(i, ref keyDisp; keysDisp)
    {
        immutable color = keysStates[keyDisp.keyCode] ? 0xCCCCCC : 0x777777;
        drawDisp(buf, c, keyDisp, color);
    }

    if(addMode)
    {
        drawDisp(buf, c, n, 0x99999999);
    }

    if(changingHotkey)
    {
        drawDisp(buf, c, *nameEditing, 0x00AAFF);
    }
}

extern(C) int UIAppMain()
{
    loadPreferences();
    window = Platform.instance.createWindow("DBoard", null, WindowFlag.Resizable);
    window.show();
    immutable sizes = figureOutWindowSize();
    keysStates[] = false;

    VerticalLayout vl = new VerticalLayout();
    vl.fillParent();
    CanvasWidget canvas = new CanvasWidget("canvas");
    canvas.fillParent();

    canvas.popupMenu = constructMainMenu(window, canvas);

    canvas.mouseEvent = delegate(Widget source, MouseEvent event)
    {
        import std.math : abs;
        canvas.popupMenu = constructMainMenu(window, canvas);
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
        if(event.rbutton.isDown && changingHotkey)
        {
            return true;
        }
        if(event.lbutton.doubleClick && !changingName && !changingHotkey)
        {
            nameEditing = selectDispAtPosition(Point(event.x, event.y));
            if(nameEditing !is null)
            {
                changingHotkey = true;
            }
            return true;
        }
        if(event.lbutton.isDown)
        {
            if(changingHotkey)
            {
                changingHotkey = false;
                nameEditing = null;
                return true;
            }
            cancelEditing(vl);
            if(dragRight)
            {
                drag.w = threeWayRound(getGridLoc(event.x) - drag.locx);
                if(drag.w < 0.5 )
                    drag.w = 0.5;
                canvas.invalidate();
                window.invalidate();
                return true;
            }
            else if(dragLeft)
            {
                immutable save = drag.locx;
                immutable locxx = drag.locx + drag.w;
                if(locxx - threeWayRound(getGridLoc(event.x)) >= 0.5)
                {
                    drag.locx = threeWayRound(getGridLoc(event.x));
                    drag.w = locxx - drag.locx; // Increase the width of the visible item
                }
                return true;
            }
            else if(dragTop)
            {
                immutable save = drag.locy;
                immutable locyy = drag.locy + drag.h;
                if(locyy - threeWayRound(getGridLoc(event.y)) >= 0.5)
                {
                    drag.locy = threeWayRound(getGridLoc(event.y));
                    drag.h = locyy - drag.locy; // Increase the width of visible item
                }
                return true;
            }
            else if(dragBottom)
            {
                drag.h = threeWayRound(getGridLoc(event.y) - drag.locy);
                if(drag.h < 0.5 )
                    drag.h = 0.5;
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

                MenuItem itm = new MenuItem();
                MenuItem del = new MenuItem(new Action(0, "Delete"d));
                del.menuItemClick = delegate(MenuItem item)
                {
                    keysDisp = keysDisp[0 .. i] ~ keysDisp[i+1 .. $];
                    canvas.popupMenu = constructMainMenu(window, canvas);
                    return true;
                };

                MenuItem txt = new MenuItem(new Action(1, "Change text"d));
                txt.menuItemClick = delegate(MenuItem item)
                {
                    immutable pt = Point(event.x, event.y);
                    enableTextEditing(pt, vl);
                    return true;
                };

                itm.add(del);
                itm.add(txt);

                canvas.popupMenu = itm;
                resetDragProperties();
                drag = &disp;
                window.overrideCursorType(CursorType.SizeAll);
                return false;
            }
        }
        resetDragProperties();
        canvas.popupMenu = constructMainMenu(window, canvas);
        window.overrideCursorType(CursorType.Arrow);
        return false;
    };

    canvas.keyEvent = delegate(Widget source, KeyEvent event)
    {
        return false;
    };

    canvas.layoutWidth(FILL_PARENT).layoutHeight(400);
    canvas.onDrawListener = toDelegate(&onDraw);

    vl.addChild(canvas);

    window.mainWidget = vl;

    KeyHook.get().OnAction = (int vkCode, KeyState state)
    {
        if(changingHotkey)
        {
            nameEditing.keyCode = vkCode;
            nameEditing = null;
            changingHotkey = false;
        }
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
        keysStates[code] = (state == KeyState.Down) ? true : false;
        gstate = state;
        canvas.invalidate();
        window.invalidate();
    };
    immutable res = Platform.instance.enterMessageLoop();
    storePreferences();
    return res;
}
