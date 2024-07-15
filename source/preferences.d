module preferences;

import mud.serialization;

version(Windows)
    private enum string defaultFont = "Impact";
else
    private enum string defaultFont = "";

struct Preferences
{
    @serializable string lastJson;
    @serializable string keyColor = "00FF00";
    @serializable string pressedColor = "6D6C77";
    @serializable string depressedColor = "37313B";
    @serializable string textColor = "AAAAAA";
    @serializable string textPressedColor = "AAAAAA";
    @serializable int keySize = 48;
    @serializable int keyOffset = 3;
    @serializable string fontFace = defaultFont;
    @serializable int fontSize = 14;
    @serializable int fontWeight = 0;
    @serializable bool fontItalic = false;
    @serializable string locale = "en";
}

__gshared Preferences prefs;

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
