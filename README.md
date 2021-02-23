# DBoard - Kyboard Visualisation Software in D

This is an attempt to create a convenient keyboard visualization software. Convenient means easy to use, so the main feature is visual keyboard editor.
![Preview](https://raw.githubusercontent.com/GrimMaple/dboard/master/preview.gif)

Currently missing a few features, it's already useable for most parts.

## Explanation
This softwares uses a tile-based grid to display keys for convenience purposes.  
The software support uneven placements (eg 1.5) to provide more visualisation options.  
Auto-snapping to whole and half locations are supported.

## Saving/Loading
This software saves keyboard files as plain json text. It can be edited afterwards to your liking.  
Example json:
```json
{
    "keyOffset": 3,
    "keySize": 48,
    "keys": [
        {
            "h": 1, // Key height in logical palces
            "w": 1, // Key width in logical places
            "keyCode": 87, // Keyboard key-code, please refer to WinApi's Virtual Key Codes for additional info
            "locx": 1, // Key x location in logical places
            "locy": 0, // Key y location in logical places
            "str": "TEXT" // Key text visualization (optional)
        }
    ]
}
```
