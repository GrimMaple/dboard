module ui;

import dlangui;
import dlangui.dialogs.filedlg;
import dlangui.dialogs.dialog;

import mud.config;

import io;
import keystrings;
import keys;

import widgets.colorselector;

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
    @ConfigProperty() string pressedColor = "CCCCCC";
    @ConfigProperty() string depressedColor = "777777";
    @ConfigProperty() int keySize = 48;
    @ConfigProperty() int keyOffset = 3;
}

__gshared Preferences prefs;

auto constructSettingsWidget(ref Window w)
{
    import std.conv : to;
    Window wnd = Platform.instance.createWindow("DBoard settings", null, 0, 300, 300);
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
    main.addChild(new ColorSelector(prefs.keyColor, "bgSel"));

    main.addChild(new TextWidget("cPress", "Pressed color"d));
    main.addChild(new ColorSelector(prefs.pressedColor, "pressClr"));

    main.addChild(new TextWidget("cDePress", "Depressed color"d));
    main.addChild(new ColorSelector(prefs.depressedColor, "deprClr"));

    Button apply = new Button("apply", "Apply"d);
    apply.click = delegate(Widget widg)
    {
        try
        {
            ColorSelector bg = wnd.mainWidget().childById!ColorSelector("bgSel");
            ColorSelector press = wnd.mainWidget().childById!ColorSelector("pressClr");
            ColorSelector depr = wnd.mainWidget().childById!ColorSelector("deprClr");
            int tmpSize, tmpOffset;
            try
            {
                tmpSize = to!int(widthEdit.text);
                tmpOffset = to!int(spacingEdit.text);
            }
            catch(Exception ex)
            {
                throw new Exception("Please enter numbers for key size and offset!");
            }
            if(tmpSize < 1) throw new Exception("Key size can't be less than 1");
            if(tmpOffset < 0) throw new Exception("Key offset can't be negative");
            keySize = tmpSize;
            keyOffset = tmpOffset;
            prefs.keyColor = bg.color;
            prefs.pressedColor = press.color;
            prefs.depressedColor = depr.color;
        }
        catch(Exception ex)
        {
            wnd.showMessageBox("Error"d, to!dstring(ex.message));
            return false;
        }
        w.invalidate();
        wnd.close();
        return true;
    };
    main.addChild(apply);

    wnd.mainWidget = main;
    wnd.show();
    return wnd;
}
