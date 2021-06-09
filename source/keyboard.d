module keyboard;

import core.sys.windows.windows;

enum KeyState
{
    Up,
    Down
}

class KeyHook
{
    private this() nothrow
    {
        hHook = SetHook();
        assert(hHook !is null);
        initConversionTable();
        initNonExtensionConversion();
    }

    private void initConversionTable() nothrow
    {
        extendedConversion[VK_RETURN] = 0x3B; // Hacks :(
    }

    private void initNonExtensionConversion() nothrow
    {
        nonExtendedConversion[VK_INSERT] = VK_NUMPAD0;
        nonExtendedConversion[VK_END] = VK_NUMPAD1;
        nonExtendedConversion[VK_HOME] = VK_NUMPAD7;
        nonExtendedConversion[VK_PRIOR] = VK_NUMPAD9;
        nonExtendedConversion[VK_NEXT] = VK_NUMPAD3;
        nonExtendedConversion[VK_DELETE] = VK_DECIMAL;
        nonExtendedConversion[VK_LEFT] = VK_NUMPAD4;
        nonExtendedConversion[VK_RIGHT] = VK_NUMPAD6;
        nonExtendedConversion[VK_UP] = VK_NUMPAD8;
        nonExtendedConversion[VK_DOWN] = VK_NUMPAD2;
        nonExtendedConversion[VK_CLEAR] = VK_NUMPAD5;
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
                if(vkCode in KeyHook.get().extendedConversion)
                    vkCode = KeyHook.get().extendedConversion[vkCode];
            }
            else
            {
                if(vkCode in KeyHook.get().nonExtendedConversion)
                    vkCode = KeyHook.get().nonExtendedConversion[vkCode];
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

    private DWORD[DWORD] nonExtendedConversion;
    private DWORD[DWORD] extendedConversion;
}