module platformconfig;

version (Windows)
    enum EnableWin32Hook = true;
else
    enum EnableWin32Hook = false;

// set through dub build --config=x11
version (EnableX11)
	enum EnableX11Hook = true;
else
	enum EnableX11Hook = false;
