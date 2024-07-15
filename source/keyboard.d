module keyboard;

enum KeyState
{
    Up,
    Down
}

class KeyHook
{
    @property static auto get() nothrow
    {
        synchronized
        {
            if(!instantiated)
            {
                version(Windows)
                {
                    import platform.windows;
                    instance = new KeyHookWindows();
                }
                else version(linux)
                {
                    import platform.linux;
                    instance = new KeyHookLinux();
                }
                else
                    static assert(true, "Platform not supported");
            }
            instantiated = true;
        }
        return instance;
    }

    void delegate(int keycode, KeyState state) OnAction;

    bool isKeyPressed(int key) { return pressedKeys[key]; }
protected:
    bool[256] pressedKeys;

private:
    __gshared KeyHook instance;
    static bool instantiated;
}
