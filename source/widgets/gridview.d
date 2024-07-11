module widgets.gridview;

import std.algorithm : each;

import dlangui;

import keyboard;
import keys;
import preferences;
import util;

class GridDrawable
{
    abstract void draw(DrawBuf buf, CanvasWidget c);
}

class KeyDrawable : GridDrawable
{
    this(KeyDisplay disp)
    {
        this.disp = disp;
    }

    final override void draw(DrawBuf buf, CanvasWidget c)
    {
        auto pressedColor = to!uint(prefs.pressedColor, 16);
        auto depressedColor = to!uint(prefs.depressedColor, 16);
        auto s = disp.visibleString;
        auto sz = c.font.textSize(s);
        auto color = pressed ? to!uint(prefs.pressedColor, 16) : to!uint(prefs.depressedColor, 16);
        immutable x = getLocOnGrid!(KeyEnd.Left)(disp.locx);
        immutable y = getLocOnGrid!(KeyEnd.Left)(disp.locy);
        immutable pxWidth = getLocOnGrid!(KeyEnd.Right)(disp.locx + disp.w) - getLocOnGrid!(KeyEnd.Left)(disp.locx);
        immutable pxHeight = getLocOnGrid!(KeyEnd.Right)(disp.locy + disp.h) - getLocOnGrid!(KeyEnd.Left)(disp.locy);
        buf.fillRect(Rect(x, y, x + pxWidth, y + pxHeight), color);
        c.font.drawText(buf, x + pxWidth/2 - sz.x/2, y+pxHeight/2 - sz.y/2, s, 0x0);
    }

    @property bool pressed() { return pressedKeys[disp.keyCode]; }

private:
    KeyDisplay disp;
}

class EditableView : GridView
{
    this(string id = null)
    {
        super(id);
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

private:
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

    KeyDisplay* selectDispAtPosition(in Point loc)
    {
        foreach(i, drw; drawables)
        {
            KeyDisplay disp = (cast(KeyDrawable)drw).disp;
            if(withinGridRange(loc.y, disp.locy, disp.locy + disp.h) &&
                withinGridRange(loc.x, disp.locx, disp.locx + disp.w))
            {
                return &(cast(KeyDrawable)drw).disp;
            }
        }
        return null;
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
            textEdit.text = nameEditing.visibleString();
            textEdit.visibility = Visibility.Visible;
            changingName = true;
            textEdit.setFocus();
            return true;
        }
        return false;
    }

    bool hasOffset = false;
    int xoffs = 0, yoffs = 0;

    bool dragLeft = false;
    bool dragRight = false;
    bool dragTop = false;
    bool dragBottom = false;
    KeyDisplay* drag = null;

    KeyDisplay* nameEditing = null;

    bool addMode = false;
    bool changingName = false;
    bool changingHotkey = false;
    KeyDisplay n;

    MenuItem savedMenu;
}

class GridView : VerticalLayout
{
    this(string id = null)
    {
        super(id);
        canvas = new CanvasWidget();
        canvas.onDrawListener = &render;
        canvas.layoutWidth(FILL_PARENT).layoutHeight(6000);

        canvas.mouseEvent = delegate(Widget source, MouseEvent event)
        {
            return mouseHandler(source, event);
        };
        addChild(canvas);
    }

    void setDrawables(KeyDisplay[] disps)
    {
        drawables = new KeyDrawable[disps.length];
        for(int i = 0; i < disps.length; i++)
            drawables[i] = new KeyDrawable(disps[i]);
    }

    CanvasWidget canvasWidget() { return canvas; }

protected:
    void preDraw(CanvasWidget source, DrawBuf buf, Rect huh) { }

    void postDraw(CanvasWidget source, DrawBuf buf, Rect huh) { }

    bool mouseHandler(Widget source, MouseEvent event) { return false; }

private:
    void render(CanvasWidget source, DrawBuf buf, Rect huh)
    {
        import std.conv : to;
        buf.resize(window.width, window.height);
        buf.fill(to!uint(prefs.keyColor, 16));
        auto c = canvas;

        preDraw(source, buf, huh);

        if(prefs.fontFace != "")
        {
            c.fontFace = prefs.fontFace;
            c.fontSize = prefs.fontSize;
            c.fontWeight = prefs.fontWeight;
            c.fontItalic = prefs.fontItalic;
        }
        else
        {
            c.fontFace = "Arial";
            c.fontSize = 13;
            c.fontWeight = 700;
            c.fontItalic = false;
        }

        drawables[].each!(x => x.draw(buf, c));

        postDraw(source, buf, huh);
    }

    KeyDrawable[] drawables;
    CanvasWidget canvas;
}
