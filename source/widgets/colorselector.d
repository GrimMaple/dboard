module widgets.colorselector;

import dlangui;
import dlangui.graphics.colors;

import core.sys.windows.windows;

import std.conv : toChars;
import std.string : toUpper;

class ColorSelector : HorizontalLayout
{
    this(string startingColor, string ID = "")
    {
        super(ID);
        layoutWidth(FILL_PARENT);
        line = new EditLine();
        line.text(to!dstring(startingColor)).layoutWidth(FILL_PARENT);
        addChild(line);
        version(Windows)
        {
            line.enabled = false;
            auto btn = new Button("", "THREEDOTS");
            btn.click = delegate(Widget source)
            {
                static COLORREF[16] custClr;
                CHOOSECOLORW chooseColor;
                chooseColor.lStructSize = chooseColor.sizeof;
                chooseColor.Flags = CC_FULLOPEN | CC_RGBINIT;
                chooseColor.lpCustColors = custClr.ptr;
                chooseColor.rgbResult = colorStringToUint(line.text.to!string);
                if(!ChooseColorW(&chooseColor)) return true;
                parseColor(chooseColor.rgbResult);
                return true;
            };
            addChild(btn);
        }
    }

    @property string color() { return line.text.to!string; }
private:
    void parseColor(uint result)
    {
        string res = byteToHexString((result & 0xFF).to!ubyte) ~
                     byteToHexString(((result & 0xFF00) >> 8).to!ubyte) ~
                     byteToHexString(((result & 0xFF0000) >> 16).to!ubyte);

        line.text = res.to!dstring;
    }

    uint colorStringToUint(string color)
    {
        return (color[4 .. 6].to!uint(16) << 16) + 
        (color[0 .. 2].to!uint(16) << 0) +
        (color[2 .. 4].to!uint(16) << 8);
    }

    string byteToHexString(ubyte input)
    {
        string res = (cast(uint)input).toChars!(16).to!string;
        return res.length == 2 ? res : "0" ~ res;
    }

    EditLine line;
}
