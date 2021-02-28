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