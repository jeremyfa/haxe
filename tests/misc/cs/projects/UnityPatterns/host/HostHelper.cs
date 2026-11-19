// A C# class of the global namespace, written by hand next to the generated
// code (like a script of a Unity project). The Haxe side declares it as an
// extern class of the root package.
public class HostHelper
{
    public int calls;

    public static int twice(int value)
    {
        return value * 2;
    }

    public int next()
    {
        return ++calls;
    }
}

public enum HostMode
{
    Off,
    On
}
