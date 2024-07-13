module widgets.editableview;

import dlangui;

import widgets.gridview;
import keys;
import keyboard;
import util;
import preferences;
import ui;

class EditableView : GridView
{
    this(string id = null)
    {
        super(id);
        popupMenu = constructMainMenuInEditing(window, canvas);
        KeyHook.get().OnAction = &onKeyHook;
    }

protected:
    override void preDraw(CanvasWidget source, DrawBuf buf, Rect huh)
    {
        drawGrid(buf);
    }

    override bool mouseHandler(Widget source, MouseEvent event)
    {
        import std.math : abs;
        // Restore menu
        if(savedMenu !is null && popupMenu != savedMenu)
            popupMenu = savedMenu;

        savedMenu = popupMenu;
        if(addMode)
        {
            n.locx = threeWayRound(getGridLoc(event.x));
            n.locy = threeWayRound(getGridLoc(event.y));
            if(event.lbutton.isDown)
            {
                KeyDisplay copy = n;
                drawables ~= new KeyDrawable(copy);
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
            if(nameEditing !is null)
                nameEditing.resetOverrideColor();
            nameEditing = selectDispAtPosition(Point(event.x, event.y));
            if(nameEditing !is null)
            {
                nameEditing.setOverrideColor(0x0000AAFF);
                changingHotkey = true;
            }
            return true;
        }
        if(event.lbutton.isDown)
        {
            if(changingHotkey)
            {
                nameEditing.resetOverrideColor();
                changingHotkey = false;
                nameEditing = null;
                return true;
            }
            cancelEditing(this);
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
        foreach(i, drw; drawables)
        {
            KeyDisplay* disp = &(cast(KeyDrawable)drw).disp;
            if(withinGridRange(event.y, disp.locy, disp.locy + disp.h))
            {
                resetDragProperties();
                if(abs(getLocOnGrid!(KeyEnd.Left)(disp.locx) - event.x) < 5)
                {
                    dragLeft = true;
                    window.overrideCursorType(CursorType.SizeWE);
                    drag = disp;
                    return true;
                }
                if(abs(getLocOnGrid!(KeyEnd.Right)(disp.locx + disp.w) - event.x) < 5)
                {
                    dragRight = true;
                    drag = disp;
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
                    drag = disp;
                    return true;
                }
                if(abs(getLocOnGrid!(KeyEnd.Right)(disp.locy + disp.h) - event.y) < 5)
                {
                    dragBottom = true;
                    drag = disp;
                    window.overrideCursorType(CursorType.SizeNS);
                    return true;
                }
            }
            if(withinGridRange(event.y, disp.locy, disp.locy + disp.h) &&
            withinGridRange(event.x, disp.locx, disp.locx + disp.w))
            {

                MenuItem itm = new MenuItem();
                MenuItem del = new MenuItem(new Action(0, "MENU_DELETE"));
                del.menuItemClick = delegate(MenuItem item)
                {
                    drawables = drawables[0 .. i] ~ drawables[i + 1 .. $];
                    return true;
                };

                MenuItem txt = new MenuItem(new Action(1, "MENU_CHANGE_TEXT"));
                txt.menuItemClick = delegate(MenuItem item)
                {
                    immutable pt = Point(event.x, event.y);
                    enableTextEditing(pt, this);
                    return true;
                };

                itm.add(del);
                itm.add(txt);

                popupMenu = itm;
                resetDragProperties();
                drag = disp;
                window.overrideCursorType(CursorType.SizeAll);
                return false;
            }
        }
        resetDragProperties();
        window.overrideCursorType(CursorType.Arrow);
        return false;
    }

    override void postDraw(CanvasWidget source, DrawBuf buf, Rect huh)
    {
        if(addMode)
        {
            drawDisp(buf, source, n, 0x99999999);
        }
    }

private:
    void drawDisp(DrawBuf buf, CanvasWidget c, ref KeyDisplay disp, uint color)
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

    void storeData()
    {
        keysDisp = new KeyDisplay[drawables.length];
        for(int i = 0; i < drawables.length; i++)
            keysDisp[i] = drawables[i].disp;
    }

    void drawGrid(DrawBuf buf)
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

    KeyDrawable selectDispAtPosition(in Point loc)
    {
        foreach(i, drw; drawables)
        {
            KeyDisplay disp = (cast(KeyDrawable)drw).disp;
            if(withinGridRange(loc.y, disp.locy, disp.locy + disp.h) &&
                withinGridRange(loc.x, disp.locx, disp.locx + disp.w))
            {
                return drw;
            }
        }
        return null;
    }

    void cancelEditing(VerticalLayout vl)
    {
        if(changingName && nameEditing)
        {
            changingName = false;
            nameEditing.disp.visibleString = vl.childById!EditLine("editText").text;
            nameEditing = null;
            vl.removeChild("editText");
            vl.invalidate();
        }
    }

    bool withinGridRange(int coord, float a, float b)
    {
        import std.algorithm : min, max;

        if(coord >= getLocOnGrid!(KeyEnd.Left)(min(a, b)) &&
        coord <= getLocOnGrid!(KeyEnd.Right)(max(a, b)))
            return true;
        return false;
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
            textEdit.text = nameEditing.disp.visibleString();
            textEdit.visibility = Visibility.Visible;
            changingName = true;
            textEdit.setFocus();
            return true;
        }
        return false;
    }

    MenuItem constructMainMenuInEditing(Window w, CanvasWidget c)
    {
        MenuItem mainMenu = new MenuItem();
        mainMenu.clear();
        MenuItem sub = new MenuItem(new Action(0, "MENU_EDIT_MODE"));
        MenuItem subAdd = new MenuItem(new Action(1, "MENU_ADD"));
        mainMenu.add(sub);
        sub.menuItemClick = delegate(MenuItem item)
        {
            storeData();
            onToggle(this);
            return true;
        };
        subAdd.menuItemClick = delegate(MenuItem item)
        {
            addMode = true;
            return true;
        };
        mainMenu.add(subAdd);

        MenuItem clear = new MenuItem(new Action(666, "MENU_CLEAR"));
        clear.menuItemClick = delegate(MenuItem itm)
        {
            drawables = new KeyDrawable[0];
            return true;
        };
        mainMenu.add(clear);

        return mainMenu;
    }

    void onKeyHook(int vkCode, KeyState state)
    {
        if(changingHotkey)
        {
            nameEditing.disp.keyCode = vkCode;
            nameEditing.resetOverrideColor();
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
        onRefresh(this);
    }

    bool hasOffset = false;
    int xoffs = 0, yoffs = 0;

    bool dragLeft = false;
    bool dragRight = false;
    bool dragTop = false;
    bool dragBottom = false;
    KeyDisplay* drag = null;

    //KeyDisplay* nameEditing = null;
    KeyDrawable nameEditing = null;

    bool addMode = false;
    bool changingName = false;
    bool changingHotkey = false;
    KeyDisplay n;

    MenuItem savedMenu;
}
