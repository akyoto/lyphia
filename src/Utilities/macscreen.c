// macscreen.c

#include <ApplicationServices/ApplicationServices.h>

static int numberForKey( CFDictionaryRef desc, CFStringRef key )
{
    CFNumberRef value;
    int num = 0;

    if ( (value = CFDictionaryGetValue(desc, key)) == NULL )
        return 0;
    CFNumberGetValue(value, kCFNumberIntType, &num);
    return num;
}

int MACOS_GetWidth( CFDictionaryRef desc )
{	
	return numberForKey(desc, kCGDisplayWidth);
}


int MACOS_GetHeight( CFDictionaryRef desc )
{	
	return numberForKey(desc, kCGDisplayHeight);
}


int MACOS_GetBPP( CFDictionaryRef desc )
{	
	return numberForKey(desc, kCGDisplayBitsPerPixel);
}


int MACOS_GetHertz( CFDictionaryRef desc )
{	
	return numberForKey(desc, kCGDisplayRefreshRate);
}



//added for version 1.17 by d-bug

int MACOS_GetMouseX( )
{
	Point pt;
	GetGlobalMouse(&pt);
	return pt.h;
}

int MACOS_GetMouseY( )
{
	Point pt;
	GetGlobalMouse(&pt);
	return pt.v;
}