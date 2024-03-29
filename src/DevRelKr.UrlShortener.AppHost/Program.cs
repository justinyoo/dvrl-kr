var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.DevRelKr_UrlShortener_Landing>("landing");

builder.AddProject<Projects.DevRelKr_UrlShortener_Dashboard>("dashboard");

builder.Build().Run();
