module ui;

import dlangui;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.dialog;

import mud.config;

import io;
import keystrings;
import keys;

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
    @ConfigProperty() string lastJson;
    @ConfigProperty() string keyColor = "00FF00";
    @ConfigProperty() int keySize = 48;
    @ConfigProperty() int keyOffset = 3;
}

__gshared Preferences prefs;

auto constructSettingsWidget(ref Window w)
{
    import std.conv : to;
    Window wnd = Platform.instance.createWindow("DBoard settings", null, 0, 300, 200);
    VerticalLayout main = new VerticalLayout();
    main.layoutHeight(FILL_PARENT).layoutWidth(FILL_PARENT);
    GroupBox sizes = new GroupBox("sizes", "Sizes"d);
    sizes.layoutWidth(FILL_PARENT);
    EditLine widthEdit = new EditLine();
    widthEdit.layoutWidth(40);
    widthEdit.text = to!dstring(keySize);

    EditLine spacingEdit = new EditLine();
    spacingEdit.text = to!dstring(keyOffset);

    spacingEdit.layoutWidth(40);
    sizes.addChild(new TextWidget("wText", "Side size (px)"d));
    sizes.addChild(widthEdit);
    sizes.addChild(new TextWidget("oText", "Key offset size (px)"d));
    sizes.addChild(spacingEdit);
    main.addChild(sizes);

    main.addChild(new TextWidget("cText", "Background color"d));
    EditLine colorEdit = new EditLine();
    colorEdit.text = to!dstring(prefs.keyColor);
    main.addChild(colorEdit);

    Button apply = new Button("apply", "Apply"d);
    apply.click = delegate(Widget widg)
    {
        try
        {
            try
            {
                keySize = to!int(widthEdit.text);
                keyOffset = to!int(spacingEdit.text);
            }
            catch(Exception ex)
            {
                throw new Exception("Please enter number!");
            }
            if(colorEdit.text.length == 6)
            {
                foreach(ref k; colorEdit.text)
                {
                    import std.algorithm : any;
                    if(!"0123456789ABCDEF"d.any!(a => a == k))
                    {
                        throw new Exception("Only 0-9 and A-F characters are accepted for color!");
                    }
                }
                prefs.keyColor = to!string(colorEdit.text);
            }
            else
            {
                throw new Exception("Color must be 6 digits long!");
            }
        }
        catch(Exception ex)
        {
            wnd.showMessageBox("Error"d, to!dstring(ex.message));
        }
        w.invalidate();
        return true;
    };
    main.addChild(apply);

    wnd.mainWidget = main;
    wnd.show();
    return main;
}
