using Azure;
using Azure.Data.Tables;

using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.WebUtilities;

namespace DevRelKr.UrlShortener.Landing.Components.Pages;

public partial class Home : ComponentBase
{
    [Inject]
    protected NavigationManager? NavigationManager { get; set; }

    [Inject]
    protected TableServiceClient? Table { get; set; }

    [CascadingParameter]
    public HttpContext? HttpContext { get; set; }

    protected override async Task OnInitializedAsync()
    {
        var headers = this.HttpContext?.Request.Headers;
        var uri = this.NavigationManager?.ToAbsoluteUri(this.NavigationManager?.Uri);
        var queries = QueryHelpers.ParseQuery(uri?.Query);

        // Store the request header

        // Search path
        var path = queries.TryGetValue("path", out var value) ? value.ToString() : "/";
        // If the path does not exist, redirect to the dashboard page
        var item = default(UrlEntity);
        var entities = this.Table.GetTableClient(tableName: "urls").QueryAsync<UrlEntity>(p => p.PartitionKey == "abc" && p.Path == path);
        await foreach (var entity in entities.AsPages())
        {
            item = entity.Values.SingleOrDefault();
            if (item != null)
            {
                break;
            }
        }

        var url = item?.Url ?? "https://app.dvrl.kr";

        this.NavigationManager?.NavigateTo(url, forceLoad: false, replace: true);

        await Task.CompletedTask;
    }
}

public class UrlEntity : ITableEntity
{
    public string PartitionKey { get; set; } = string.Empty;
    public string RowKey { get; set; } = string.Empty;
    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }
    public string? Url { get; set; }
    public string? Path { get; set; }
}
