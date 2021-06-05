module keyboard;

import platformconfig;

import dlangui : Window;

enum KeyState
{
    Up,
    Down
}

enum SpecialKey
{
    Escape
}

alias KeyCallback = void delegate(IKeyHook hook, int keysym, KeyState state);
interface IKeyHook
{
    int getSpecialKey(SpecialKey key);
    dstring getKeyName(int keysym);
    void addCallback(KeyCallback callback);
    void finish();
}

class KeyHook
{
    private static bool instantiated;

    private __gshared IKeyHook instance;

    @property static IKeyHook get(Window window)
    {
        synchronized
        {
            if (!instantiated)
            {
                instance = makePlatformHook(window);
            }
            instantiated = true;
        }
        return instance;
    }

    static void finish()
    {
        synchronized
        {
            if (instantiated)
                instance.finish();
        }
    }

    private static IKeyHook makePlatformHook(Window window)
    {
        // window parameter in case we need a window handle in implementations

        static if (EnableWin32Hook)
        {
            import impl.win32;

            // on windows there is only one
            if (auto hook = Win32KeyHook.get())
                return hook;
        }

        static if (EnableX11Hook)
        {
            import impl.x11;

            if (auto hook = X11KeyHook.create())
                return hook;
        }

        assert(false, "No keyboard hook could be created for this system");
    }
}