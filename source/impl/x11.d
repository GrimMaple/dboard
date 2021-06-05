module impl.x11;

import platformconfig;

static if (EnableX11Hook):

import core.thread;

import std.conv;

import x11.extensions.XI;
import x11.extensions.XI2;
import x11.extensions.XInput;
import x11.extensions.XInput2;
import x11.keysym;
import x11.X;
import x11.Xlib;

import keyboard;

import dlangui;

class X11KeyHook : IKeyHook
{
    protected Display* display;
    protected int xi_opcode;
    protected bool running;
    protected Thread t;

    protected this(Display* display, int xi_opcode)
    {
        this.display = display;
        this.xi_opcode = xi_opcode;
        running = true;
        t = new Thread(&loop);
        t.start();
    }

    int getSpecialKey(SpecialKey key)
    {
        final switch (key)
        {
            case SpecialKey.Escape: return XK_Escape;
        }
    }

    dstring getKeyName(int keysym)
    {
        KeySym lower, upper;
        XConvertCase(keysym, &lower, &upper);
        return XKeysymToString(upper).to!dstring;
    }

    void finish()
    {
        running = false;
        t.join();
    }

    KeyCallback[] callbacks;
    void addCallback(KeyCallback callback)
    {
        synchronized (this)
        {
            callbacks ~= callback;
        }
    }

    protected void loop()
    {
        scope (exit)
            XCloseDisplay(display);

        while (true)
        {
            XEvent event;
            // bug here that the thread will actually only exit once an event
            // has been received, but keyboard events are frequent enough to
            // justify not fixing this here (especially because of the kind of
            // app this is)
            XNextEvent(display, &event);
            if (!running)
                break;
            auto cookie = &event.xcookie;
            if (!XGetEventData(display, cookie))
                continue;

            if (cookie.type != GenericEvent || cookie.extension != xi_opcode)
                continue;

            switch (cookie.evtype)
            {
            case XI_RawKeyRelease:
            case XI_RawKeyPress:
                XIRawEvent* ev = cast(XIRawEvent*) cookie.data;
                KeySym s = XKeycodeToKeysym(display, cast(ubyte) ev.detail, 0);
                if (s == NoSymbol)
                    continue;
                broadcast(cast(int)s, cookie.evtype == XI_RawKeyPress ? KeyState.Down : KeyState.Up);
                break;
            default:
                break;
            }
        }
    }

    protected void broadcast(int keysym, KeyState state)
    {
        foreach (callback; callbacks)
            callback(this, keysym, state);
    }

    @property static X11KeyHook create()
    {
        // open new display for parallel event loop
        auto display = XOpenDisplay(null);
        auto root = DefaultRootWindow(display);

        int xi_opcode;
        int queryEvent, queryError;
        enum char* ext = cast(char*) "XInputExtension".ptr;
        if (!XQueryExtension(display, ext, &xi_opcode, &queryEvent, &queryError))
            return null; // XInput not available

        XIEventMask m;
        m.deviceid = XIAllMasterDevices;
        m.mask_len = XIMaskLen(XI_LASTEVENT);
        ubyte[256] mask;
        assert(m.mask_len <= mask.length);
        m.mask = mask.ptr;
        XISetMask(m.mask, XI_RawKeyPress);
        XISetMask(m.mask, XI_RawKeyRelease);
        XISelectEvents(display, root, &m, 1);
        XSync(display, false);

        return new X11KeyHook(display, xi_opcode);
    }
}

void XISetMask(ubyte* ptr, int event) @system
{
    ptr[event >> 3] |= (1 << (event & 7));
}

ubyte XIMaskLen(int event)
{
    return cast(ubyte)(((event) >> 3) + 1);
}

extern(C) void XConvertCase(KeySym, KeySym *, KeySym *);
