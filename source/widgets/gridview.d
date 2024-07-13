module widgets.gridview;

import std.algorithm : each;

import dlangui;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.dialog;

import keyboard;
import keys;
import preferences;
import util;
import widgets.settingswidget;
import ui;
import io;

class GridDrawable
{
    abstract void draw(DrawBuf buf, CanvasWidget c);
}

interface EditToggleHandler
{
    void onEditToggled(Widget source);
}

interface RefreshStuffHandler
{
    void onRefreshThings(Widget source);
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
        buf.fillRect(Rect(x, y, x + pxWidth, y + pxHeight), doesOverrideColor ? overrideColor : color);
        c.font.drawText(buf, x + pxWidth/2 - sz.x/2, y+pxHeight/2 - sz.y/2, s, 0x0);
    }

    @property bool pressed() { return pressedKeys[disp.keyCode]; }

    void setOverrideColor(uint color)
    {
        overrideColor = color;
        doesOverrideColor = true;
    }

    void resetOverrideColor()
    {
        doesOverrideColor = false;
    }

    KeyDisplay disp;

private:
    uint overrideColor = 0;
    bool doesOverrideColor = false;
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
        popupMenu = constructMainMenu(window, canvas);
        addChild(canvas);
    }

    void setDrawables(KeyDisplay[] disps)
    {
        drawables = new KeyDrawable[disps.length];
        for(int i = 0; i < disps.length; i++)
            drawables[i] = new KeyDrawable(disps[i]);
    }

    CanvasWidget canvasWidget() { return canvas; }

    Signal!EditToggleHandler onToggle;
    Signal!RefreshStuffHandler onRefresh;

protected:
    void preDraw(CanvasWidget source, DrawBuf buf, Rect huh) { }

    void postDraw(CanvasWidget source, DrawBuf buf, Rect huh) { }

    bool mouseHandler(Widget source, MouseEvent event) { return false; }

    KeyDrawable[] drawables;
    CanvasWidget canvas;

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

    MenuItem constructMainMenu(Window w, CanvasWidget c)
    {
        MenuItem mainMenu = new MenuItem();
        mainMenu.clear();
        MenuItem sub = new MenuItem(new Action(0, "MENU_EDIT_MODE"));
        MenuItem load = new MenuItem(new Action(2, "MENU_LOAD"));
        MenuItem save = new MenuItem(new Action(3, "MENU_SAVE"));
        MenuItem sett = new MenuItem(new Action(4, "MENU_SETTINGS"));
        mainMenu.add(sub);
        sub.menuItemClick = delegate(MenuItem item)
        {
            onToggle(this);
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
                setDrawables(keysDisp);
                onRefresh(this);
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
                invalidate();
            };
            dlg.show();
            return true;
        };

        sett.menuItemClick = delegate(MenuItem item)
        {
            Window wnd = constructSettingsWidget(w);
            wnd.onClose = delegate()
            {
                onRefresh(this);
            };
            return true;
        };

        mainMenu.add(load);
        mainMenu.add(save);
        mainMenu.add(sett);
        return mainMenu;
    }

    auto constructSettingsWidget(ref Window w)
    {
        import std.conv : to;
        Window wnd = Platform.instance.createWindow("DBoard settings", null, 0, 300, 350);
        wnd.mainWidget = new SettingsWidget();
        wnd.show();
        return wnd;
    }
}
