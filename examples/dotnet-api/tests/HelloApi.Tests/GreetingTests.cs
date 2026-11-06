using HelloApi;
using Xunit;

namespace HelloApi.Tests;

public class GreetingTests
{
    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void For_WithoutName_GreetsTheWorld(string? name)
    {
        Assert.Equal("Hello, world!", Greeting.For(name));
    }

    [Fact]
    public void For_WithName_TrimsAndGreets()
    {
        Assert.Equal("Hello, Meg!", Greeting.For("  Meg "));
    }
}
