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
        grid.popupMenu = constructMainMenu(window, grid.canvasWidget);
        window.mainWidget = grid;
        KeyHook.get().OnAction = &onKeyHook;
        reloadSettings();
    }

    auto editableCanvas()
    {
        auto ed = new EditableView();
        ed.setDrawables(keysDisp);
        ed.popupMenu = constructMainMenuInEditing(window, ed.canvasWidget);
        return ed;
    }

    void reloadSettings()
    {
        pressedColor = to!uint(prefs.pressedColor, 16);
        depressedColor = to!uint(prefs.depressedColor, 16);
        Platform.instance.uiLanguage = prefs.locale;
    }

    MenuItem constructMainMenu(Window w, CanvasWidget c)
    {
        if(editMode)
        {
            return constructMainMenuInEditing(w, c);
        }
        MenuItem mainMenu = new MenuItem();
        mainMenu.clear();
        MenuItem sub = new MenuItem(new Action(0, "MENU_EDIT_MODE"));
        MenuItem load = new MenuItem(new Action(2, "MENU_LOAD"));
        MenuItem save = new MenuItem(new Action(3, "MENU_SAVE"));
        MenuItem sett = new MenuItem(new Action(4, "MENU_SETTINGS"));
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
            window.executeInUiThread(() => window.mainWidget = editableCanvas());
            return true;
        };

        load.menuItemClick = delegate(MenuItem item)
        {
            FileDialog dlg = new FileDialog(UIString.fromId("OPEN"), w, null);
            dlg.addFilter(FileFilterEntry(UIString.fromRaw("JSON Files (*.json)"), "*.json"));
            dlg.dialogResult = delegate(Dialog dialog, const Action result)
            {
                import std.file : readText;
                if(result.id != ACTION_OPEN.id)
                    return;
                string filename = dlg.filename;
                string json = readText(filename);
                prefs.lastJson = filename;
                keysDisp = loadJsonFile(json);
                c.invalidate();
                w.invalidate();
                figureOutWindowSize();
            };
            dlg.show();
            return true;
        };

        save.menuItemClick = delegate(MenuItem item)
        {
            FileDialog dlg = new FileDialog(UIString.fromRaw("Save file"), w, null, DialogFlag.Modal | DialogFlag.Resizable
                | FileDialogFlag.ConfirmOverwrite | FileDialogFlag.Save);
            dlg.addFilter(FileFilterEntry(UIString.fromRaw("JSON Files (*.json)"), "*.json"));
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
                string json = saveJson(keysDisp);
                write(filename, json);
                prefs.lastJson = filename;
                c.invalidate();
                w.invalidate();
            };
            dlg.show();
            return true;
        };

        sett.menuItemClick = delegate(MenuItem item)
        {
            Window wnd = constructSettingsWidget(w);
            wnd.onClose = delegate()
            {
                reloadSettings();
                figureOutWindowSize();
            };
            return true;
        };

        mainMenu.add(load);
        mainMenu.add(save);
        mainMenu.add(sett);
        return mainMenu;
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
            editMode = !editMode;
            if(editMode)
            {
                c.popupMenu = constructMainMenuInEditing(w, c);
            }
            else
            {
                c.popupMenu = constructMainMenu(w, c);
            }
            auto grid = new GridView();
            grid.setDrawables(keysDisp);
            grid.popupMenu = constructMainMenu(window, grid.canvasWidget);
            window.executeInUiThread(() => window.mainWidget = grid);
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
            keysDisp = new KeyDisplay[0];
            return true;
        };
        mainMenu.add(clear);

        return mainMenu;
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
