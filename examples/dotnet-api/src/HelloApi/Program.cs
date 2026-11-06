using HelloApi;

var app = WebApplication.CreateBuilder(args).Build();

app.MapGet("/", (string? name) => Greeting.For(name));
app.MapGet("/healthz", () => Results.Ok());

app.Run();
