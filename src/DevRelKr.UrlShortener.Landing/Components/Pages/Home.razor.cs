using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.WebUtilities;

namespace DevRelKr.UrlShortener.Landing.Components.Pages;

public partial class Home : ComponentBase
{
    [Inject]
    protected NavigationManager? NavigationManager { get; set; }

    [CascadingParameter]
    public HttpContext? HttpContext { get; set; }

    protected override async Task OnInitializedAsync()
    {
        var headers = this.HttpContext?.Request.Headers;
        var uri = this.NavigationManager?.ToAbsoluteUri(NavigationManager.Uri);
        var queries = QueryHelpers.ParseQuery(uri.Query);

        // Store the request header

        // Search path
        var path = queries.TryGetValue("path", out var value) ? value.ToString() : "/";
        // If the path does not exist, redirect to the dashboard page
        var url = "https://app.dvrl.kr";

        this.NavigationManager?.NavigateTo(url, forceLoad: false, replace: true);

        await Task.CompletedTask;
    }
}
