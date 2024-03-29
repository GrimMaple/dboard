module preferences;

import mud.serialization;

struct Preferences
{
    @serializable string lastJson;
    @serializable string keyColor = "00FF00";
    @serializable string pressedColor = "CCCCCC";
    @serializable string depressedColor = "777777";
    @serializable int keySize = 48;
    @serializable int keyOffset = 3;
    @serializable string fontFace = "";
    @serializable int fontSize = 0;
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
