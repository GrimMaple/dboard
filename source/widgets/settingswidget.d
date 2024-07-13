module widgets.settingswidget;

import std.algorithm : countUntil;

import dlangui;

import widgets.colorselector;
import ui;
import preferences;

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
        widthEdit.text = prefs.keySize.to!dstring;
        spacingEdit.text = prefs.keyOffset.to!dstring;

        sizes.addChild(new TextWidget("", "SETTINGS_SIDE_SIZE"));
        sizes.addChild(widthEdit);
        sizes.addChild(new TextWidget("", "SETTINGS_KEY_OFFSET"));
        sizes.addChild(spacingEdit);
        addChild(sizes);

        addChild(new TextWidget("", "SETTINGS_LANGUAGE"));
        addChild(new ComboBox("langs", ["LANG_EN", "LANG_RU"]));

        addChild(new TextWidget("", "SETTINGS_BACKGROUND_COLOR"));
        addChild(new ColorSelector(prefs.keyColor, "bgSel"));
        bg = childById!ColorSelector("bgSel");

        addChild(new TextWidget("cPress", "SETTINGS_PRESSED_COLOR"));
        addChild(new ColorSelector(prefs.pressedColor, "pressClr"));
        press = childById!ColorSelector("pressClr");

        addChild(new TextWidget("cDePress", "SETTINGS_DEPRESSED_COLOR"));
        addChild(new ColorSelector(prefs.depressedColor, "deprClr"));
        depr = childById!ColorSelector("deprClr");

        addChild(new TextWidget("cTextClr", "SETTINGS_TEXT_COLOR"));
        addChild(new ColorSelector(prefs.textColor, "textClr"));
        textClr = childById!ColorSelector("textClr");

        addChild(new TextWidget("cTextPressClr", "SETTINGS_TEXT_PRESSED_COLOR"));
        addChild(new ColorSelector(prefs.textPressedColor, "textPressedClr"));
        textPressedClr = childById!ColorSelector("textPressedClr");

        selectLocale();

        childById!ComboBox("langs").itemClick = delegate(Widget source, int itemIndex)
        {
            prefs.locale = getLocaleString();
            Platform.instance.uiLanguage = prefs.locale;
            return false;
        };

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
        HorizontalLayout controls = parseML!HorizontalLayout(q{
            HorizontalLayout {
                Button {
                    id: apply
                    text: APPLY
                }
                Button {
                    id: cancel
                    text: CANCEL
                }
            }
        });
        controls.childById!Button("cancel").click = delegate(Widget wdgt)
        {
            window().close();
            return true;
        };
        controls.childById!Button("apply").click = delegate(Widget widg)
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
                    throw new Exception("ERROR_OFFSET_NOT_NUMBER");
                }
                if(tmpSize < 1) throw new Exception("ERROR_KEY_SIZE_LESS_THAN_ONE");
                if(tmpOffset < 0) throw new Exception("ERROR_KEY_OFFSET_NEGATIVE");
                keySize = tmpSize;
                keyOffset = tmpOffset;
                prefs.keyColor = bg.color;
                prefs.pressedColor = press.color;
                prefs.depressedColor = depr.color;
                prefs.textColor = textClr.color;
                prefs.textPressedColor = textPressedClr.color;
                prefs.locale = getLocaleString();
                Platform.instance.uiLanguage = prefs.locale;
            }
            catch(Exception ex)
            {
                window().showMessageBox(UIString.fromId("ERROR"), UIString.fromId(cast(string)ex.message));
                return false;
            }
            window().close();
            return true;
        };
        addChild(controls);
    }
private:
    void selectLocale()
    {
        static immutable langs = ["en", "ru"];
        childById!ComboBox("langs").selectedItemIndex = cast(int)langs.countUntil!(x => x == prefs.locale);
    }

    string getLocaleString()
    {
        static immutable langs = ["en", "ru"];
        return langs[childById!ComboBox("langs").selectedItemIndex()];
    }
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
    ColorSelector textClr;
    ColorSelector textPressedClr;
}
