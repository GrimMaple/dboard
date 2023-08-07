import std.stdio;
import std.json;
import std.conv : to;
import std.functional : toDelegate;

import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;

import mud.serialization.json;

import keyboard;
import keystrings;
import ui;
import keys;
import io;
import util;

import mainwindow;

mixin APP_ENTRY_POINT;

void loadPreferences()
{
    import std.file : exists, readText;
    if(exists("prefs"))
    {
        try
        {
            prefs = deserializeJSON!Preferences(parseJSON(readText("prefs")));
        }
        catch(Exception ex)
        {
            remove("prefs");
        }
    }

    if(prefs.lastJson != "")
    {
        if(exists(prefs.lastJson))
            keysDisp = loadJsonFile(readText(prefs.lastJson));
    }
}

void storePreferences()
{
    import std.file : wt = write;
    auto res = serializeJSON(prefs);
    wt("prefs", toJSON(res));
}

extern(C) int UIAppMain()
{
    loadPreferences();
    auto window = new MainWindow();
    immutable res = Platform.instance.enterMessageLoop();
    storePreferences();
    version(linux)
    {
        // I will fix this later, maybe...
        import keyboard;
        KeyHook.get().exit();
    }
    return res;
}
