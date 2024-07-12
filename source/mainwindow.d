module mainwindow;

import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;
import mud.config;

import keyboard;
import keys;
import ui;
import util;
import io;
import preferences;
import widgets.gridview;
import widgets.editableview;

/// UI Main Window
class MainWindow
{
    /// Construct a new main window
    this()
    {
        designWindow();
    }

private:

    void designWindow()
    {
        window = Platform.instance.createWindow("DBoard", null, WindowFlag.Resizable);
        window.show();
        immutable sizes = figureOutWindowSize();
        keysStates[] = false;

        auto grid = new GridView();
        grid.setDrawables(keysDisp);
        grid.onToggle = &onResetToEdit;
        window.mainWidget = grid;
        KeyHook.get().OnAction = &onKeyHook;
        reloadSettings();
    }

    void onResetToNormal(Widget source)
    {
        auto widget = new GridView();
        widget.setDrawables(keysDisp);
        widget.onToggle = &onResetToEdit;
        window.executeInUiThread(() => window.mainWidget = widget);
    }

    void onResetToEdit(Widget source)
    {
        auto widget = new EditableView();
        widget.setDrawables(keysDisp);
        widget.onToggle = &onResetToNormal;
        window.executeInUiThread(() => window.mainWidget = widget);
    }

    auto editableCanvas()
    {
        auto ed = new EditableView();
        ed.setDrawables(keysDisp);
        return ed;
    }

    void reloadSettings()
    {
        pressedColor = to!uint(prefs.pressedColor, 16);
        depressedColor = to!uint(prefs.depressedColor, 16);
        Platform.instance.uiLanguage = prefs.locale;
    }

    void onKeyHook(int vkCode, KeyState state)
    {
        /*if(changingHotkey)
        {
            nameEditing.keyCode = vkCode;
            nameEditing = null;
            changingHotkey = false;
        }*/
        /*if(addMode && state == KeyState.Down)
        {
            if(n.keyCode == 0x1B && vkCode == 0x1B) // ESCAPE
            {
                addMode = false;
            }
            else
            {
                n.keyCode = vkCode;
            }
        }*/
        code = vkCode;
        keysStates[code] = (state == KeyState.Down) ? true : false;
        gstate = state;
        window.mainWidget.invalidate();
        window.invalidate();
    }

    void setFont(CanvasWidget c)
    {
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
    }

    auto figureOutWindowSize()
    {
        import std.algorithm : max;
        float maxx = 0, maxy = 0;
        foreach(keyDisp; keysDisp)
        {
            maxx = max(maxx, keyDisp.locx + keyDisp.w);
            maxy = max(maxy, keyDisp.locy + keyDisp.h);
        }

        immutable width = max(getLocOnGrid!(KeyEnd.Right)(maxx + 0.5), minWidth);
        immutable height = max(getLocOnGrid!(KeyEnd.Right)(maxy + 0.5), minHeight);

        window.resizeWindow(Point(width, height));
        return Point(width, height);
    }

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

    int code = 0;
    KeyState gstate = KeyState.Up;

    bool[] keysStates = new bool[256];

    Window window = null;
    CanvasWidget canvas = null;

    bool clicked = false;

    uint pressedColor, depressedColor;

    immutable minWidth = 200;
    immutable minHeight = 200;
}
