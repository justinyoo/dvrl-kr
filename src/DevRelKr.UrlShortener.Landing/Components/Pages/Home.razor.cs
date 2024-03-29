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
        // If the path exists, redirect to the path
        // If the path does not exist, redirect to the dashboard page

        this.NavigationManager?.NavigateTo($"https://{queries["path"]}", forceLoad: false, replace: true);
    }
}
