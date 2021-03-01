module ui;

import dlangui;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.dialog;

import io;
import keystrings;
import keys;

__gshared bool editMode = false;
__gshared bool addMode = false;

__gshared int keySize = 48;
__gshared int keyOffset = 3;

__gshared KeyDisplay[] keysDisp = new KeyDisplay[0];

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
    MenuItem sett = new MenuItem(new Action(4, "Settings"d));
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
            string json = saveJson(keysDisp);
            write(filename, json);
            c.invalidate();
            w.invalidate();
        };
        dlg.show();
        return true;
    };

    sett.menuItemClick = delegate(MenuItem item)
    {
        //w.mainWidget = constructSettingsWidget(w);
        constructSettingsWidget(w);
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
    Window wnd = Platform.instance.createWindow("DBoard settings", null, WindowFlag.Resizable, 400, 200);
    HorizontalLayout main = new HorizontalLayout();
    main.layoutHeight(FILL_PARENT).layoutWidth(FILL_PARENT);
    GroupBox sizes = new GroupBox("sizes", "Sizes"d);
    sizes.layoutWidth(FILL_PARENT);
    EditLine widthEdit = new EditLine();
    widthEdit.layoutWidth(40);
    widthEdit.text = to!dstring(keySize);

    EditLine spacingEdit = new EditLine();
    spacingEdit.text = to!dstring(keyOffset);

    Button apply = new Button("apply", "Apply"d);
    apply.click = delegate(Widget widg)
    {
        try
        {
            keySize = to!int(widthEdit.text);
            keyOffset = to!int(spacingEdit.text);
        }
        catch(Exception ex)
        {
            wnd.showMessageBox("Error"d, "Please enter number!"d);
        }
        w.invalidate();
        //w.updateWindowOrContentSize();
        return true;
    };

    spacingEdit.layoutWidth(40);
    sizes.addChild(new TextWidget("wText", "Side size (px)"d));
    sizes.addChild(widthEdit);
    sizes.addChild(new TextWidget("oText", "Key offset size (px)"d));
    sizes.addChild(spacingEdit);
    sizes.addChild(apply);
    main.addChild(sizes);
    wnd.mainWidget = main;
    wnd.show();
    return main;
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