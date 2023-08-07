module ui;

import dlangui;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.dialog;

import mud.config;

import io;
import keystrings;
import keys;

import widgets.settingswidget;

import mud.serialization;

import app;

__gshared bool editMode = false;
__gshared bool addMode = false;

// This is sort-of a hack to shorthand the usage of Preferenses
int keyOffset()
{
    return prefs.keyOffset;
}

void keyOffset(int a)
{
    prefs.keyOffset = a;
}

int keySize()
{
    return prefs.keySize;
}

void keySize(int a)
{
    prefs.keySize = a;
}

__gshared KeyDisplay[] keysDisp = new KeyDisplay[0];

struct Preferences
{
    @serializable string lastJson;
    @serializable string keyColor = "00FF00";
    @serializable string pressedColor = "CCCCCC";
    @serializable string depressedColor = "777777";
    @serializable int keySize = 48;
    @serializable int keyOffset = 3;
    @serializable string fontFace = "";
    @serializable int fontSize = 0;
    @serializable int fontWeight = 0;
    @serializable bool fontItalic = false;
}

__gshared Preferences prefs;

auto constructSettingsWidget(ref Window w)
{
    import std.conv : to;
    Window wnd = Platform.instance.createWindow("DBoard settings", null, 0, 300, 300);
    wnd.mainWidget = new SettingsWidget();
    wnd.show();
    return wnd;
}
