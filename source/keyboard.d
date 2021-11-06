module keyboard;

import core.sys.windows.windows;

enum KeyState
{
    Up,
    Down
}

version(Windows)
{

class KeyHook
{
    private enum ScanCodes
    {
        NumLock = 0x45,
        ScrollLock = 0x46,
        NumPad7 = 0x47,
        NumPad8 = 0x48,
        NumPad9 = 0x49,
        NumPadMinus = 0x4A,
        NumPad4 = 0x4B,
        NumPad5 = 0x4C,
        NumPad6 = 0x4D,
        NumPadPlus = 0x4E,
        NumPad1 = 0x4F,
        NumPad2 = 0x50,
        NumPad3 = 0x51,
        NumPad0 = 0x52,
        NumPadPeriod = 0x53
    }

    private this() nothrow
    {
        hHook = SetHook();
        assert(hHook !is null);
        initConversionTable();
        initScanCodesTable();
    }

    private void initConversionTable() nothrow
    {
        extendedConversion[VK_RETURN] = 0x3B; // Hacks :(
    }

    private void initScanCodesTable() nothrow
    {
        scanCodes[ScanCodes.NumLock] = VK_NUMLOCK;
        scanCodes[ScanCodes.NumPad0] = VK_NUMPAD0;
        scanCodes[ScanCodes.NumPad1] = VK_NUMPAD1;
        scanCodes[ScanCodes.NumPad2] = VK_NUMPAD2;
        scanCodes[ScanCodes.NumPad3] = VK_NUMPAD3;
        scanCodes[ScanCodes.NumPad4] = VK_NUMPAD4;
        scanCodes[ScanCodes.NumPad5] = VK_NUMPAD5;
        scanCodes[ScanCodes.NumPad6] = VK_NUMPAD6;
        scanCodes[ScanCodes.NumPad7] = VK_NUMPAD7;
        scanCodes[ScanCodes.NumPad8] = VK_NUMPAD8;
        scanCodes[ScanCodes.NumPad9] = VK_NUMPAD9;
        scanCodes[ScanCodes.NumPadPeriod] = VK_DECIMAL;
    }

    private static bool instantiated;

    private __gshared KeyHook instance;

    private HHOOK hHook;

    @property static auto get() nothrow
    {
        synchronized
        {
            if(!instantiated)
            {
                instance = new KeyHook();
            }
            instantiated = true;
        }
        return instance;
    }

    void delegate(int keycode, KeyState state) OnAction;

    private auto SetHook()
    {
        return SetWindowsHookEx(WH_KEYBOARD_LL, &HookCallback, GetModuleHandle(NULL), 0);
    }

    private static extern(Windows) long HookCallback(int nCode, WPARAM wParam, LPARAM lParam) @system nothrow
    {
        if(nCode >= 0 && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN || wParam == WM_KEYUP || wParam == WM_SYSKEYUP))
        {
            KBDLLHOOKSTRUCT* kb = cast(KBDLLHOOKSTRUCT*)lParam;
            int vkCode = kb.vkCode;
            if(kb.flags & LLKHF_EXTENDED)
            {
                // Windows doesn't distinguish NumPad enter and "normal" enter. If a numpad enter is pressed,
                // an "extended" KeyDown event is generated
                if(vkCode in KeyHook.get().extendedConversion)
                    vkCode = KeyHook.get().extendedConversion[vkCode];
            }
            else if(kb.scanCode in KeyHook.get().scanCodes)
            {
                // Normally Virtual Keys (VKs) don't distinguish between numpad and "real" keys. This is a hack
                // that uses scan codes to understand if the pressed key is a numpad or not
                vkCode = KeyHook.get().scanCodes[kb.scanCode];
            }
            try
            {
                if(KeyHook.get().OnAction !is null)
                    KeyHook.get().OnAction(vkCode, (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) ? KeyState.Down : KeyState.Up);
            }
            catch(Exception ex)
            {
                // ...
            }
        }
        HHOOK hook = KeyHook.get().hHook;
        return CallNextHookEx(hook, nCode, wParam, lParam);
    }

    private DWORD[DWORD] extendedConversion;

    private DWORD[DWORD] scanCodes;
}

}
else version(linux)
{

import core.thread.osthread;
import core.time;

import x11.X;
import x11.Xlib;
import x11.extensions.XI;
import x11.extensions.XI2;
import x11.extensions.XInput;
import x11.extensions.XInput2;

class KeyHook
{
    @property static auto get()
    {
        synchronized
        {
            if(!instantiated)
            {
                instance = new KeyHook();
            }
            instantiated = true;
        }
        return instance;
    }

    void delegate(int keycode, KeyState state) OnAction;

    void exit()
    {
        exiting = true;
        if(workerThread.isRunning)
            workerThread.join();
    }

private:
    static bool instantiated;
    __gshared KeyHook instance;
    this()
    {
        initKeymaps();
        workerThread = new Thread(&worker).start();
    }

    ~this()
    {
        exiting = true;
    }

    void worker()
    {
        auto dpy = XOpenDisplay(null);
        auto root = DefaultRootWindow(dpy);
        int opcode, queryEvent, queryError;
        if(!XQueryExtension(dpy, cast(char*)("XInputExtension".ptr), &opcode, &queryEvent, &queryError))
            throw new Exception("No extension");

        XIEventMask mask;
        mask.deviceid = XIAllMasterDevices;
        mask.mask_len = XIMaskLen!(XI_LASTEVENT);
        ubyte[256] m;
        mask.mask = m.ptr;

        void setMask(int mask)
        {
            m[mask >> 3] |=  (1 << ((mask) & 7));
        }
        setMask(XI_RawKeyPress);
        setMask(XI_RawKeyRelease);

        XISelectEvents(dpy, root, &mask, 1);
        XSync(dpy, false);

        XEvent evt;
        while(!exiting)
        {
            if(!XPending(dpy))
            {
                Thread.sleep(dur!"msecs"(1));
                continue;
            }
            XNextEvent(dpy, &evt);
            XGetEventData(dpy, &evt.xcookie);
            if(evt.xcookie.type != GenericEvent || evt.xcookie.extension != opcode)
                continue;

            XIRawEvent* ev = cast(XIRawEvent*)evt.xcookie.data;

            switch(evt.xcookie.evtype)
            {
            case XI_RawKeyPress:
                if(OnAction !is null) OnAction(keys[ev.detail], KeyState.Down);
                break;
            case XI_RawKeyRelease:
                if(OnAction !is null) OnAction(keys[ev.detail], KeyState.Up);
                break;
            default:
                break;
            }
            debug
            {
                import std.stdio : writeln;
                if(keys[ev.detail] == 0)
                    writeln(ev.detail);
            }
        }
    }

    void initKeymaps()
    {
        void KEYMAP(int a, int b) { keys[a] = b; }
        KEYMAP(9,  0x1b); // Escape
        KEYMAP(67, 0x70); // F1
        KEYMAP(68, 0x71); // F2
        KEYMAP(69, 0x72); // F3
        KEYMAP(70, 0x73); // F4
        KEYMAP(71, 0x74); // F5
        KEYMAP(72, 0x75); // F6
        KEYMAP(73, 0x76); // F7
        KEYMAP(74, 0x77); // F8
        KEYMAP(75, 0x78); // F9
        KEYMAP(76, 0x79); // F10
        KEYMAP(95, 0x7a); // F11
        KEYMAP(96, 0x7b); // F12
        KEYMAP(10, 0x31); // 1
        KEYMAP(11, 0x32); // 2
        KEYMAP(12, 0x33); // 3
        KEYMAP(13, 0x34); // 4
        KEYMAP(14, 0x35); // 5
        KEYMAP(15, 0x36); // 6
        KEYMAP(16, 0x37); // 7
        KEYMAP(17, 0x38); // 8
        KEYMAP(18, 0x39); // 9
        KEYMAP(19, 0x30); // 0
        KEYMAP(20, 0xBD); // -
        KEYMAP(21, 0xBB); // =
        KEYMAP(22, 0x08); // Backspace
        KEYMAP(23, 0x09); // Tab
        KEYMAP(24, 0x51); // Q
        KEYMAP(25, 0x57); // W
        KEYMAP(26, 0x45); // E
        KEYMAP(27, 0x52); // R
        KEYMAP(28, 0x54); // T
        KEYMAP(29, 0x59); // Y
        KEYMAP(30, 0x55); // U
        KEYMAP(31, 0x49); // I
        KEYMAP(32, 0x4f); // O
        KEYMAP(33, 0x50); // P
        KEYMAP(34, 0xDB); // [
        KEYMAP(35, 0xDD); // ]
        KEYMAP(51, 0xDC); // |
        KEYMAP(66, 0x14); // CapsLock
        KEYMAP(38, 0x41); // A
        KEYMAP(39, 0x53); // S
        KEYMAP(40, 0x44); // D
        KEYMAP(41, 0x46); // F
        KEYMAP(42, 0x47); // G
        KEYMAP(43, 0x48); // H
        KEYMAP(44, 0x4a); // J
        KEYMAP(45, 0x4b); // K
        KEYMAP(46, 0x4c); // L
        KEYMAP(47, 0xBA); // ;
        KEYMAP(48, 0xDE); // '
        KEYMAP(36, 0x0d); // Enter
        KEYMAP(50, 0xa0); // LShift
        KEYMAP(52, 0x5a); // Z
        KEYMAP(53, 0x58); // X
        KEYMAP(54, 0x43); // C
        KEYMAP(55, 0x56); // V
        KEYMAP(56, 0x42); // B
        KEYMAP(57, 0x4e); // N
        KEYMAP(58, 0x4d); // M
        KEYMAP(59, 0xBC); // ,
        KEYMAP(60, 0xBE); // .
        KEYMAP(61, 0xBF); // ?
        KEYMAP(62, 0xa1); // RShift
        KEYMAP(37, 0xa2); // LCtrl
        KEYMAP(133, 0x5b); // LWin
        KEYMAP(65, 0x20); // SPACE
        KEYMAP(135, 0x5D); // RMenu
        KEYMAP(105, 0xa3); // RCtrl
        KEYMAP(113, 0x25); // Left
        KEYMAP(111, 0x26); // Up
        KEYMAP(116, 0x28); // Dowdn
        KEYMAP(114, 0x27); // Right
        KEYMAP(118, 0x2D); // Insert
        KEYMAP(119, 0x2E); // Delete
        KEYMAP(110, 0x24); // Home
        KEYMAP(115, 0x23); // End
        KEYMAP(112, 0x21); // PageUp
        KEYMAP(117, 0x22); // PageDown
        KEYMAP(77, 0x90); // NumLock
        KEYMAP(106, 0x6F); // /
        KEYMAP(63, 0x6A); // *
        KEYMAP(82, 0x6D); // -
        KEYMAP(86, 0x6B); // +
        KEYMAP(79, 0x67); // NUM7
        KEYMAP(80, 0x68); // NUM8
        KEYMAP(81, 0x69); // NUM9
        KEYMAP(83, 0x64); // NUM4
        KEYMAP(84, 0x65); // NUM5
        KEYMAP(85, 0x66); // NUM6
        KEYMAP(87, 0x61); // NUM1
        KEYMAP(88, 0x62); // NUM2
        KEYMAP(89, 0x63); // NUM3
        KEYMAP(90, 0x60); // NUM0
        KEYMAP(91, 0x6E); // NUM. (NUM Delete);

        KEYMAP(49, 0xC0); // ~
        KEYMAP(107, 0x2C); // PrintScreen
        KEYMAP(78, 0x91); // Scroll lock
        KEYMAP(127, 0x13); // Pause Break

        KEYMAP(104, 0x3B); // NUM Enter
        KEYMAP(64, 0xA4); // Left Alt
        KEYMAP(108, 0xA5); // Right Alt

        KEYMAP(121, 0xAD); // Volume Mute
        KEYMAP(122, 0xAE); // Volume Down
        KEYMAP(123, 0xAF); // Volume Up

        KEYMAP(173, 0xB1); // Previous Track
        KEYMAP(172, 0xB3); // Media Stop/Play
        KEYMAP(171, 0xB0); // Next track
    }

    int[256] keys;
    bool exiting;
    Thread workerThread;
}

}