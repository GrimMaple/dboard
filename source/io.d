module io;

import std.json;

import mud.serialization;
import mud.serialization.json;

import keys;
import ui;

private struct JFile
{
    @serializable KeyDisplay[] keys;
}

/// Serialize `KeyDisplay[]` to json string
string saveJson(ref KeyDisplay[] keysDisp)
{
    JFile tmp = JFile(keysDisp);
    auto json = serializeJSON(tmp);
    return toJSON(json, true);
}

/// Deserialize `string` to `KeyDisplay[]`
KeyDisplay[] loadJsonFile(in string json)
{
    JFile j = deserializeJSON!JFile(parseJSON(json));
    return j.keys;
}
