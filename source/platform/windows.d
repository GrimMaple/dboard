module platform.windows;

import keyboard;

version(Windows):
import core.sys.windows.windows;

class KeyHookWin : KeyHook
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

    private HHOOK hHook;

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
                pressedKeys[vkCode] = (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN);
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