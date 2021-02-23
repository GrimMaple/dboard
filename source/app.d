import std.stdio;
import std.json;
import std.conv : to;

import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;

import keyboard;
import keystrings;

mixin APP_ENTRY_POINT;

int code = 0;
KeyState gstate = KeyState.Up;

int keySize = 48;
int keyOffset = 3;

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

string saveJson()
{
    JSONValue toValue(ref KeyDisplay disp)
    {
        JSONValue val;
        val["locx"] = disp.locx;
        val["locy"] = disp.locy;
        val["h"] = disp.h;
        val["w"] = disp.w;
        val["keyCode"] = disp.keyCode;
        if(disp.str != "")
            val["str"] = disp.str;
        return val;
    }
    JSONValue res;
    res["keySize"] = keySize;
    res["keyOffset"] = keyOffset;
    JSONValue[] vals = new JSONValue[0];
    foreach (ref key; keysDisp)
    {
        vals ~= toValue(key);
    }
    res["keys"] = vals;
    return toJSON(res, true);
}

void loadJsonFile(string json)
{
    keysDisp = new KeyDisplay[0];
    auto parsed = parseJSON(json);
    keySize = parsed["keySize"].get!int();
    keyOffset = parsed["keyOffset"].get!int();
    auto keys = parsed["keys"].get!(JSONValue[])();
    foreach(val; keys)
    {
        KeyDisplay disp;
        disp.h = val["h"].get!float();
        disp.w = val["w"].get!float();
        disp.keyCode = val["keyCode"].get!int();
        disp.locx = val["locx"].get!float();
        disp.locy = val["locy"].get!float();
        try
        {
            disp.str = to!dstring(val["str"].get!string());
        }
        catch(Exception e)
        {
            // it's okay to be missing str property
        }
        keysDisp ~= [disp];
    }
}

MenuItem constructMainMenu(ref Window w, ref CanvasWidget c)
{
    if(editMode)
    {
        return constructMainMenuInEditing(w, c);
    }
    MenuItem mainMenu = new MenuItem();
    mainMenu.clear();
    MenuItem sub = new MenuItem(new Action(0, "Toggle edit"d));
    MenuItem load = new MenuItem(new Action(2, "Load file"d));
    MenuItem save = new MenuItem(new Action(3, "Save file"d));
    mainMenu.add(sub);
    sub.menuItemClick = delegate(MenuItem item)
    {
        editMode = !editMode;
        if(editMode)
        {
            c.popupMenu =  constructMainMenuInEditing(w, c);
        }
        else
        {
           c.popupMenu = constructMainMenu(w, c);
        }
        return true;
    };

    load.menuItemClick = delegate(MenuItem item)
    {
        FileDialog dlg = new FileDialog(UIString("Open file"d), w, null);
        dlg.addFilter(FileFilterEntry(UIString("JSON Files (*.json)"d), "*.json"));
        dlg.dialogResult = delegate(Dialog dialog, const Action result)
        {
            import std.file : readText;
            if(result.id != ACTION_OPEN.id)
                return;
            string filename = dlg.filename;
            string json = readText(filename);
            loadJsonFile(json);
            c.invalidate();
            w.invalidate();
        };
        dlg.show();
        return true;
    };

    save.menuItemClick = delegate(MenuItem item)
    {
        FileDialog dlg = new FileDialog(UIString("Save file"d), w, null, DialogFlag.Modal | DialogFlag.Resizable
            | FileDialogFlag.ConfirmOverwrite | FileDialogFlag.Save);
        dlg.addFilter(FileFilterEntry(UIString("JSON Files (*.json)"d), "*.json"));
        dlg.filename = "mykeyboard";
        dlg.dialogResult = delegate(Dialog dialog, const Action result)
        {
            import std.file : write;
            import std.algorithm : endsWith;
            if(result.id != ACTION_SAVE.id)
                return;
            auto ext = dlg.selectedFilter()[0][1 .. $];
            string filename = dlg.filename;
            if(!filename.endsWith(ext))
                filename ~= ext;
            string json = saveJson();
            write(filename, json);
            c.invalidate();
            w.invalidate();
        };
        dlg.show();
        return true;
    };
    mainMenu.add(load);
    mainMenu.add(save);
    return mainMenu;
}

MenuItem constructMainMenuInEditing(ref Window w, ref CanvasWidget c)
{
    MenuItem mainMenu = new MenuItem();
    mainMenu.clear();
    MenuItem sub = new MenuItem(new Action(0, "Toggle edit"d));
    MenuItem subAdd = new MenuItem(new Action(1, "Add new"d));
    mainMenu.add(sub);
    sub.menuItemClick = delegate(MenuItem item)
    {
        editMode = !editMode;
        if(editMode)
        {
            c.popupMenu = constructMainMenuInEditing(w, c);
        }
        else
        {
            c.popupMenu = constructMainMenu(w, c);
        }
        return true;
    };
    subAdd.menuItemClick = delegate(MenuItem item)
    {
        addMode = true;
        return true;
    };
    mainMenu.add(subAdd);
    
    return mainMenu;
}

extern(C) int UIAppMain()
{
    string testJson = 
    `{
        "keySize": 48,
        "keyOffset": 3,
        "keys": [
            {
                "locx": 1,
                "locy": 0,
                "w": 1,
                "h": 1,
                "keyCode": 87
            },
            {
                "locx": 0,
                "locy": 1,
                "w": 1,
                "h": 1,
                "keyCode": 65
            },
            {
                "locx": 1,
                "locy": 1,
                "w": 1,
                "h": 1,
                "keyCode": 83
            },
            {
                "locx": 2,
                "locy": 1,
                "w": 1,
                "h": 1,
                "keyCode": 68
            }
        ]
    }`;

    loadJsonFile(testJson);

    immutable str = "QWERTYUIOP";
    Window window = Platform.instance.createWindow("DBoard", null, WindowFlag.Resizable, 400, 200);
    window.show();
    keys[] = false;

    CanvasWidget canvas = new CanvasWidget("canvas");

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
                        canvas.popupMenu = constructMainMenu(window, canvas);
                        return true;
                    };
                    itm.add(del);
                    if(canvas.canShowPopupMenu(event.x, event.y))
                    {
                        canvas.popupMenu = itm;
                        canvas.showPopupMenu(event.x, event.y);
                    }
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

        c.fontFace = "Arial";// = FontManager.instance.getFont(24, 300, false, FontFamily.Serif, "Arial");
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
