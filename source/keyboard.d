module keyboard;

import core.sys.windows.windows;

enum KeyState
{
    Up,
    Down
}

class KeyHook
{
    private this()
    {
        hHook = SetHook();
        assert(hHook !is null);
    }

    private static bool instantiated;

    private __gshared KeyHook instance;

    private HHOOK hHook;

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
        HHOOK hook = null;
        try
        {
            hook = KeyHook.get().hHook;
        }
        catch(Exception ex)
        {
            // ...
        }
        return CallNextHookEx(hook, nCode, wParam, lParam);
    }
}