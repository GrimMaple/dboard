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

class GridView : VerticalLayout
{
    this(string id = null)
    {
        super(id);
        canvas = new CanvasWidget();
        canvas.onDrawListener = &render;
        canvas.layoutWidth(FILL_PARENT).layoutHeight(6000);
        canvas.onDrawListener = &render;
        addChild(canvas);
    }

    void setDrawables(KeyDisplay[] disps)
    {
        drawables = new KeyDrawable[disps.length];
        for(int i = 0; i < disps.length; i++)
            drawables[i] = new KeyDrawable(disps[i]);
    }

private:
    void render(CanvasWidget source, DrawBuf buf, Rect huh)
    {
        import std.conv : to;
        buf.resize(window.width, window.height);
        buf.fill(to!uint(prefs.keyColor, 16));
        auto c = canvas;

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
        /*foreach(i, ref keyDisp; drawables)
        {
            immutable color = keysStates[keyDisp.keyCode] ? pressedColor : depressedColor;
            drawDisp(buf, c, keyDisp, color);
        }*/
    }

    KeyDrawable[] drawables;
    CanvasWidget canvas;
}
