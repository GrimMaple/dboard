module io;

import std.json;

import keys;
import ui;

immutable testJson = 
`{
    "keys": [
        {
            "locx": 1,
            "locy": 0,
            "w": 1,
            "h": 1,
            "keyCode": 87
        },
        {
            "locx": 0,
            "locy": 1,
            "w": 1,
            "h": 1,
            "keyCode": 65
        },
        {
            "locx": 1,
            "locy": 1,
            "w": 1,
            "h": 1,
            "keyCode": 83
        },
        {
            "locx": 2,
            "locy": 1,
            "w": 1,
            "h": 1,
            "keyCode": 68
        }
    ]
}`;


/// Serialize `KeyDisplay[]` to json string
string saveJson(ref KeyDisplay[] keysDisp)
{
    JSONValue toValue(ref KeyDisplay disp)
    {
        JSONValue val;
        val["locx"] = disp.locx;
        val["locy"] = disp.locy;
        val["h"] = disp.h;
        val["w"] = disp.w;
        val["keyCode"] = disp.keyCode;
        if(disp.hasVisibleString)
            val["str"] = disp.visibleString;
        return val;
    }
    JSONValue res;
    JSONValue[] vals = new JSONValue[0];
    foreach (ref key; keysDisp)
    {
        vals ~= toValue(key);
    }
    res["keys"] = vals;
    return toJSON(res, true);
}

/// Deserialize `string` to `KeyDisplay[]`
KeyDisplay[] loadJsonFile(in string json)
{
    KeyDisplay[] keysDisp = new KeyDisplay[0];
    auto parsed = parseJSON(json);
    auto keys = parsed["keys"].get!(JSONValue[])();
    foreach(val; keys)
    {
        KeyDisplay disp;
        disp.h = val["h"].get!float();
        disp.w = val["w"].get!float();
        disp.keyCode = val["keyCode"].get!int();
        disp.locx = val["locx"].get!float();
        disp.locy = val["locy"].get!float();
        try
        {
            import std.conv : to;
            disp.visibleString = to!dstring(val["str"].get!string());
        }
        catch(Exception e)
        {
            // it's okay to be missing str property
        }
        keysDisp ~= [disp];
    }
    return keysDisp;
}