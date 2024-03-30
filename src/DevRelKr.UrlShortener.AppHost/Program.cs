var builder = DistributedApplication.CreateBuilder(args);

var storage = builder.AddAzureStorage("storage");
var queue = storage.AddQueues("queue");
var table = storage.AddTables("table");

builder.AddProject<Projects.DevRelKr_UrlShortener_Landing>("landing")
    //    .WithReference(table)
        ;

builder.AddProject<Projects.DevRelKr_UrlShortener_Dashboard>("dashboard")
    //    .WithReference(table)
       .WithReference(queue);

builder.Build().Run();
