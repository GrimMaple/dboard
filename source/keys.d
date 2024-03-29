module keys;

import mud.serialization;

import keystrings;

/// Key display information
struct KeyDisplay
{
    /// Key display logical X position
    @serializable float locx = 0;

    /// Key display logical Y position
    @serializable float locy = 0;
    
    /// VK code for this key display
    @serializable int keyCode = 0;

    /// Key display logical width
    @serializable float w = 1;
    
    /// Key display logical height
    @serializable float h = 1;

    /// Does this `KeyDisplay` have a custom display string
    @property bool hasVisibleString()
    {
        return str != "";
    }

    /// String that should be drawn for this key
    @property void visibleString(dstring str)
    {
        this.str = str;
    }
    ///
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