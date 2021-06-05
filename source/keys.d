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
        return str;
    }

    private dstring str;
}