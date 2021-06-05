module impl.win32;

import platformconfig;

static if (EnableWin32Hook):

import win32.windows;

import keyboard;

class Win32KeyHook : IKeyHook
{
    private this()
    {
        hHook = SetHook();
    }

    private static bool instantiated;

    private HHOOK hHook;

    private __gshared Win32KeyHook instance;

    @property static Win32KeyHook get()
    {
        synchronized
        {
            if (!instantiated)
            {
                instance = new Win32KeyHook();
            }
            instantiated = true;
        }

        if (instance.hHook is null)
            return null;

        return instance;
    }

    KeyCallback[] onAction;
    void addCallback(KeyCallback callback)
    {
        onAction ~= callback;
    }

    private auto SetHook()
    {
        return SetWindowsHookEx(WH_KEYBOARD_LL, &HookCallback, GetModuleHandle(NULL), 0);
    }

    int getSpecialKey(SpecialKey key)
    {
        final switch (key)
        {
            case SpecialKey.Escape: return 0x1B;
        }
    }

    dstring getKeyName(int keysym)
    {
        import keystrings;

        debug
        {
            import std.conv : toChars, to;
            immutable s = keyCode;
            dstring t = to!dstring(toChars!(16)(cast(uint)s));
            return hasVisibleString ? str :
                keyStrings[keyCode] == "" ? t : keyStrings[keyCode];
        }
        else return hasVisibleString ? str : keyStrings[keyCode];
    }

    void finish()
    {
        UnhookWindowsHookEx(hHook);
        hHook = NULL;
        Win32KeyHook.instance = null;
    }

    private static extern(Windows) LRESULT HookCallback(int nCode, WPARAM wParam, LPARAM lParam) @system nothrow
    {
        if(nCode >= 0 && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN || wParam == WM_KEYUP || wParam == WM_SYSKEYUP))
        {
            KBDLLHOOKSTRUCT* kb = cast(KBDLLHOOKSTRUCT*)lParam;
            int vkCode = kb.vkCode;
            try
            {
                auto keyhook = Win32KeyHook.get();
                foreach (action; keyhook.onAction)
                    action(keyhook, vkCode, (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) ? KeyState.Down : KeyState.Up);
            }
            catch(Exception ex)
            {
                // ...
            }
        }
        HHOOK hook = null;
        try
        {
            hook = Win32KeyHook.get().hHook;
        }
        catch(Exception ex)
        {
            // ...
        }
        return CallNextHookEx(hook, nCode, wParam, lParam);
    }
}