module util;

import preferences;

/// Rounds to lesser .0, .5, or greater .0
float threeWayRound(float input)
{
    float x = input - cast(int)input;
    if(x < 0.2)
        return input - x;
    if(x < 0.6 && x > 0.4)
        return input - x + 0.5;
    if(x > 0.8)
        return input - x + 1;
    return input;
}

string keyboardsPath()
{
    import std.file : thisExePath;
    import std.path;

    return absolutePath(thisExePath).dirName() ~ "/keyboards";
}

/// Is `f` whole
bool isWhole(T)(T f) if(__traits(isFloating, T))
{
    import std.math : trunc;
    if(f - trunc(f) != 0)
        return false;
    return true;
}

int getLocOnGrid(KeyEnd end = KeyEnd.Left)(float gridPos)
{
    static if(end == KeyEnd.Left)
        return keyOffset + cast(int)(cast(int)(gridPos) * keyOffset + gridPos * keySize);
    else
        return getLocOnGrid!(KeyEnd.Left)(gridPos) - keyOffset;
}

float getGridLoc(int val)
{
    return cast(float)(val - keyOffset)/cast(float)(keyOffset + keySize);
}

enum KeyEnd
{
    Left,
    Right
}