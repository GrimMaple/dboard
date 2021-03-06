module util;

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

/// Is `f` whole
bool isWhole(T)(T f) if(__traits(isFloating, T))
{
    import std.math : trunc;
    if(f - trunc(f) != 0)
        return false;
    return true;
}
