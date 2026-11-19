// Stands for the Unity side: it has its own entry point and calls static
// methods of the Haxe code. Program.Main of the Haxe output does not exist.
public static class Host
{
    public static int Main(string[] args)
    {
        return global::haxe.root.Main.run();
    }
}
