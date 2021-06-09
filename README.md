# DBoard - Kyboard Visualisation Software in D

This is an attempt to create a convenient keyboard visualization software. Convenient means easy to use, so the main feature is visual keyboard editor.  
![Preview](https://raw.githubusercontent.com/GrimMaple/dboard/master/preview.gif)

Currently missing a few features, it's already useable for most parts.

## Explanation
DBoard uses a tile-based grid to display keys for convenience purposes.  
DBoard supports uneven placements (eg 1.5) to provide more visualisation options.  
Auto-snapping to whole and half locations is supported.

## Usage  
I tried to make DBoard as self-explanatory as possible, but here are a few things you can do.

### Normal mode
Right click to acces the context menu to enter "edit" mode, save/load keyboard configurations, or change global settings.  

### Edit mode
To add a new key:  
* Right click and select "Add new"
* Press desired key on the keyboard
* Place the key on the grid and left click

To delete a key, right click the key and press "Delete".  
To change the key string representation, right click and select "Change text".  
Double click any key to change the display string of the key.  
Drag the edges of any key to change its size.  
Double click to change the key mapping.  

### Global settings
Global settings allow for changing the following appearance aspects:
* Side size - changes key side size in pixels. 1 logical space is equal to this metric
* Key offset size - the empty space (in pixel) between two keys
* Background color = a HEX string in RRGGBB format representing DBoard's background color (for chroma key purposes)

## Saving/Loading
DBoard saves keyboard files as plain json text. It can be edited afterwards to your liking.  
Example json:
```json
{
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
