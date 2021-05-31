module keys;

import keystrings;

struct KeyDisplay
{
    float locx = 0, locy = 0;
    int keyCode = 0;
    float w = 1, h = 1;

    @property bool hasVisibleString()
    {
        return str != "";
    }

    @property void visibleString(dstring str)
    {
        this.str = str;
    }

    @property dstring visibleString()
    {
        debug
        {
            import std.conv : toChars, to;
            immutable s = keyCode;
            dstring t = to!dstring(toChars!(16)(cast(uint)s));
            return hasVisibleString ? str :
                keyStrings[keyCode] == "" ? t : keyStrings[keyCode];
        }
        else return hasVisibleString ? str : keyStrings[keyCode];
    }

    private dstring str;
}