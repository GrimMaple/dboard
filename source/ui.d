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

__gshared KeyDisplay[] keysDisp = new KeyDisplay[0];

auto constructSettingsWidget(ref Window w)
{
    import std.conv : to;
    Window wnd = Platform.instance.createWindow("DBoard settings", null, 0, 300, 350);
    wnd.mainWidget = new SettingsWidget();
    wnd.show();
    return wnd;
}
