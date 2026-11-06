namespace HelloApi;

public static class Greeting
{
    public static string For(string? name) =>
        string.IsNullOrWhiteSpace(name) ? "Hello, world!" : $"Hello, {name.Trim()}!";
}
