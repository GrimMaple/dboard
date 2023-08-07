module widgets.settingswidget;

import dlangui;

import widgets.colorselector;
import ui;

class SettingsWidget : VerticalLayout
{
    this(string ID = "")
    {
        super(ID);
        layoutHeight(FILL_PARENT).layoutWidth(FILL_PARENT);
        GroupBox sizes = new GroupBox("sizes", "SETTINGS_SIZES");
        sizes.layoutWidth(FILL_PARENT);
        widthEdit = new EditLine();
        spacingEdit = new EditLine();

        sizes.addChild(new TextWidget("", "SETTINGS_SIDE_SIZE"));
        sizes.addChild(widthEdit);
        sizes.addChild(new TextWidget("", "SETTINGS_KEY_OFFSET"));
        sizes.addChild(spacingEdit);
        addChild(sizes);

        addChild(new TextWidget("", "SETTINGS_BACKGROUND_COLOR"));
        addChild(new ColorSelector(prefs.keyColor, "bgSel"));
        bg = childById!ColorSelector("bgSel");

        addChild(new TextWidget("cPress", "SETTINGS_PRESSED_COLOR"));
        addChild(new ColorSelector(prefs.pressedColor, "pressClr"));
        press = childById!ColorSelector("pressClr");

        addChild(new TextWidget("cDePress", "SETTINGS_DEPRESSED_COLOR"));
        addChild(new ColorSelector(prefs.depressedColor, "deprClr"));
        depr = childById!ColorSelector("deprClr");

        version(Windows)
        {
            Button font = cast(Button)(new Button("", "SETTINGS_KEY_FONTS"));
            font.click = delegate(Widget source)
            {
                import core.sys.windows.windows;
                static LOGFONT logFont;
                wstring cvt = prefs.fontFace.to!wstring;
                logFont.lfHeight = prefs.fontSize;
                logFont.lfFaceName[0 .. cvt.length] = cvt[0 .. $];
                CHOOSEFONTW chooseFont;
                chooseFont.Flags = CF_SCREENFONTS | CF_EFFECTS;
                chooseFont.lpLogFont = &logFont;
                if(!ChooseFontW(&chooseFont)) return true;
                auto sz = wstrlen(logFont.lfFaceName.ptr);
                prefs.fontFace = logFont.lfFaceName[0 .. sz].to!string;
                prefs.fontSize = - logFont.lfHeight * 72 / GetDeviceCaps(GetDC(NULL), LOGPIXELSY);
                prefs.fontWeight = logFont.lfWeight;
                prefs.fontItalic = logFont.lfItalic != 0;
                return true;
            };
            addChild(font);
        }
        Button apply = new Button("", "APPLY");
        apply.click = delegate(Widget widg)
        {
            try
            {
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
                window().showMessageBox(UIString.fromId("ERROR"), to!dstring(ex.message));
                return false;
            }
            //w.invalidate();
            window().close();
            return true;
        };
        addChild(apply);
    }
private:
    version(Windows)
    {
        import core.sys.windows.windef : WCHAR;
        size_t wstrlen(WCHAR* input)
        {
            size_t ret = 0;
            while(input[ret] != 0) ret++;
            return ret;
        }
    }
    EditLine widthEdit;
    EditLine spacingEdit;
    ColorSelector bg;
    ColorSelector press;
    ColorSelector depr;
}
