module keystrings;

/// Immutable array of VK_CEYCODES -> String representations
public immutable dstring[] keyStrings =
    [
        "", // 0x00
        "LB", // 0x01 Left Mouse Button
        "RB", // 0x02 Right Mouse Button
        "CNC", // 0x03 Cancel ???
        "MB", // 0x04 Middle Mouse Button
        "X1", // 0x05 X1 Mouse Button
        "X2", // 0x06 X2 Mouse Button
        "", // 0x07 UNDEFINED
        "BKS", // 0x08 Backspace
        "TAB", // 0x09 Tab
        "", // 0x0A RESERVED
        "", // 0x0B RESERVED
        "CLR", // 0x0C Clear
        "ENT", // 0x0D Enter
        "", // 0x0E UNDEFINED
        "", // 0x0F UNDEFINED
        "SHFT", // 0x10 Shift
        "CTRL", // 0x11 Control
        "ALT", // 0x12 Alt
        "PAUSE", // 0x13 Pause
        "CAPS", // 0x14 Caps Lock
        "IME", // 0x15 IME Kana
        "IME", // 0x16 IME On
        "IME", // 0x17 IME Junja
        "IME", // 0x18 IME Final
        "IME", // 0x19 IME Kanji
        "IME", // 0x1A IME OFF
        "ESC", // 0x1B Escape
        "IME", // 0x1C IME Convert
        "IME", // 0x1D IME Non-Convert
        "IME", // 0x1E IME Accept
        "IME", // 0x1F IME Mode Change
        "SPC", // 0x20 Spacebar
        "PGUP", // 0x21 Page Up
        "PGDN", // 0x22 PageDown
        "END", // 0x23 End
        "HOME", // 0x24 Home
        "←", // 0x25 Left Arrow
        "↑", // 0x26 Up Arrow
        "→", // 0x27 Right Arrow
        "↓", // 0x28 Down Arrow
        "SEL", // 0x29 Select
        "PRT", // 0x2A Print
        "EXE", // 0x2B Execute
        "PRTSC", // 0x2C Print Screen
        "INS", // 0x2D Insert
        "DEL", // 0x2E Delete
        "HELP", // 0x2F Help
        "0", // 0x30 0
        "1", // 0x31 1
        "2", // 0x32 2
        "3", // 0x33 3
        "4", // 0x34 4
        "5", // 0x35 5
        "6", // 0x36 6
        "7", // 0x37 7
        "8", // 0x38 8
        "9", // 0x39 9
        "", // 0x3A-0x40 Undefined
        "ENT", // 0x3B
        "", // 0x3C
        "", // 0x3D
        "", // 0x3E
        "", // 0x3F
        "", // 0x40
        "A", // 0x41 A
        "B", // 0x42 B
        "C", // 0x43 C
        "D", // 0x44 D
        "E", // 0x45 E
        "F", // 0x46 F
        "G", // 0x47 G
        "H", // 0x48 H
        "I", // 0x49 I
        "J", // 0x4A J
        "K", // 0x4B K
        "L", // 0x4C L
        "M", // 0x4D M
        "N", // 0x4E N
        "O", // 0x4F O
        "P", // 0x50 P
        "Q", // 0x51 Q
        "R", // 0x52 R
        "S", // 0x53 S
        "T", // 0x54 T
        "U", // 0x55 U
        "V", // 0x56 V
        "W", // 0x57 W
        "X", // 0x58 X
        "Y", // 0x59 Y
        "Z", // 0x5A Z
        "WIN", // 0x5B Left Win Key
        "WIN", // 0x5C Right Win Key
        "APP", // 0x5D Application key
        "", // 0x5E RESERVED
        "SLP", // 0x5F Sleep
        "NUM0", // 0x60 Numpad 0
        "NUM1", // 0x61 Numpad 1
        "NUM2", // 0x62 Numpad 2
        "NUM3", // 0x63 Numpad 3
        "NUM4", // 0x64 Numpad 4
        "NUM5", // 0x65 Numpad 5
        "NUM6", // 0x66 Numpad 6
        "NUM7", // 0x67 Numpad 7
        "NUM8", // 0x68 Numpad 8
        "NUM9", // 0x69 Numpad 9
        "*", //0x6A Multiply
        "+", // 0x6B Add
        "/", // 0x6C Separator
        "-", // 0x6D Subtract
        ".", // 0x6E Decimal
        "/", // 0x6F Divide
        "F1", //0x70 F1
        "F2", //0x71 F2
        "F3", //0x72 F3
        "F4", //0x73 F4
        "F5", //0x74 F5
        "F6", //0x75 F6
        "F7", //0x76 F7
        "F8", //0x77 F8
        "F9", //0x78 F9
        "F10", //0x79 F10
        "F11", //0x7A F11
        "F12", //0x7B F12
        "F13", //0x7C F13
        "F14", //0x7D F14
        "F15", //0x7E F15
        "F16", //0x7F F16
        "F17", //0x80 F17
        "F18", //0x81 F18
        "F19", //0x82 F19
        "F20", //0x83 F20
        "F21", //0x84 F21
        "F22", //0x85 F22
        "F23", //0x86 F23
        "F24", //0x87 F24
        "", // 0x88-0x8F Unassigned
        "", // 0x89 Unassigned
        "", // 0x8A Unassigned
        "", // 0x8B Unassigned
        "", // 0x8C Unassigned
        "", // 0x8D Unassigned
        "", // 0x8E Unassigned
        "", // 0x8F Unassigned
        "NUMLK", // 0x90 Num Lock
        "SCRLK", // 0x91 Scroll Lock
        "O1", // 0x92-0x96 OEM Specific
        "O2", // 0x93
        "O3", // 0x94
        "O4", // 0x95
        "O5", // 0x96
        "", // 0x97-0x9F Unassigned
        "", // 0x98
        "", // 0x99
        "", // 0x9A
        "", // 0x9B
        "", // 0x9C
        "", // 0x9D
        "", // 0x9E
        "", // 0x9F
        "SHIFT", // 0xA0 Left Shift
        "SHIFT", // 0xA1 Right Shift
        "LCTRL", // 0xA2 Left Ctrl
        "RCTRL", // 0xA3 Right Ctrl
        "ALT", // 0xA4 Left Menu
        "ALT", // 0xA5 Right Menu
        "", // 0xA6 ???????????
        "", // 0xA7 Browser Back
        "", // 0xA8 Browser Refresh
        "", // 0xA9 Browser Stop
        "", // 0xAA Browser Search
        "", // 0xAB Browser Favourites
        "", // 0xAC Browser Start and Home
        "♫x", // 0xAD Volume Mute
        "♫↓", // 0xAE Volume Down
        "♫↑", // 0xAF Volume Up
        "►►", // 0xB0 Next Track
        "◄◄", // 0xB1 Previous Track
        "■", // 0xB2 Media Stop
        "►", // 0xB3 Media Play/Pause
        "", // 0xB4 Start Mail
        "", // 0xB5 Select Media
        "", // 0xB6 Start App 1
        "", // 0xB7 Start App 2
        "", // 0xB8 RESERVED
        "", // 0xB9 RESERVED
        ";", // 0xBA Misc chars (OEM-1) ;
        "+", // 0xBB OEM +
        ",", // 0xBC OEM ,
        "-", // 0xBD OEM -
        ".", // 0xBE OEM .
        "?", // 0xBF Misc chars (OEM-2) ?
        "~", // 0xC0 Misc chars (OEM-3) ~
        "", // 0xC1-0xD7 RESERVED
        "", // 0xC2
        "", // 0xC3
        "", // 0xC4
        "", // 0xC5
        "", // 0xC6
        "", // 0xC7
        "", // 0xC8
        "", // 0xC9
        "", // 0xCA
        "", // 0xCB
        "", // 0xCC
        "", // 0xCD
        "", // 0xCE
        "", // 0xCF
        "", // 0xD0
        "", // 0xD1
        "", // 0xD2
        "", // 0xD3
        "", // 0xD4
        "", // 0xD5
        "", // 0xD6
        "", // 0xD7
        "", // 0xD8-0xDA UNASSIGNED
        "", // 0xD9
        "", // 0xDA
        "[", // 0xDB Misc chars (OEM-4) [
        "|", // 0xDC Misc chars (OEM-5) |
        "]", // 0xDD Misc chars (OEM-6) ]
        "\'", // 0xDE Misc chars (OEM-7) '
        "", // 0xDF Misc chars (OEM-8) (Not aplicable for US keyboard)
        "", // 0xE0 RESERVED
        "", // 0xE1 OEM-Specific
        "", // 0xE2
        "", // 0xE3 OEM-Specific
        "", // 0xE4 OEM-Specific
        "IME", // 0xE5 IME Process
        "", // 0xE6 OEM-Specific
        "", // 0xE7 Packet
        "", // 0xE8 UNASSIGNED
        "", // 0xE9-0xF5 OEM-Specific
        "", // 0xEA
        "", // 0xEB
        "", // 0xEC
        "", // 0xED
        "", // 0xEE
        "", // 0xEF
        "", // 0xF0
        "", // 0xF1
        "", // 0xF2
        "", // 0xF3
        "", // 0xF4
        "", // 0xF5
        "ATTN", // 0xF6 Attn
        "CRSEL", // 0xF7 CrSel
        "EXSEL", // 0xF8 ExSel
        "EOF", // 0xF9 EOF
        "►", // 0xFA Play
        "", // 0xFB Zoom
        "", // 0xFC RESERVED
        "PA1", // 0xFD PA1
        "CLR", // 0xFE Clear
    ];