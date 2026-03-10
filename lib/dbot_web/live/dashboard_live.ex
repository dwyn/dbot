defmodule DbotWeb.DashboardLive do
  use DbotWeb, :live_view

  @refresh_ms 15_000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Process.send_after(self(), :refresh, @refresh_ms)
    {:ok, load_data(socket)}
  end

  @impl true
  def handle_info(:refresh, socket) do
    Process.send_after(self(), :refresh, @refresh_ms)
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_event("poll_now", _params, socket) do
    Dbot.Email.Poller.poll_now()
    {:noreply, put_flash(socket, :info, "Poll triggered")}
  end

  defp load_data(socket) do
    assign(socket,
      page_title: "Dashboard",
      emails: Dbot.Email.list_recent(20),
      poller_status: Dbot.Email.Poller.get_status()
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold">Dashboard</h1>
        <div class="flex items-center gap-4">
          <span class="text-sm opacity-70">
            <%= if @poller_status.last_polled_at do %>
              Last polled: {Calendar.strftime(@poller_status.last_polled_at, "%H:%M:%S")}
            <% else %>
              Not polled yet
            <% end %>
          </span>
          <button phx-click="poll_now" class="btn btn-primary btn-sm">
            Poll Now
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="table table-zebra w-full">
          <thead>
            <tr>
              <th>From</th>
              <th>Subject</th>
              <th>Status</th>
              <th>Draft</th>
              <th>Received</th>
            </tr>
          </thead>
          <tbody>
            <%= if @emails == [] do %>
              <tr>
                <td colspan="5" class="text-center opacity-50 py-8">
                  No emails processed yet. Configure Gmail credentials and poll for new emails.
                </td>
              </tr>
            <% end %>
            <%= for email <- @emails do %>
              <tr>
                <td class="max-w-xs truncate">
                  <div class="font-medium">{email.from_name || email.from_address}</div>
                  <div class="text-xs opacity-50">{email.from_address}</div>
                </td>
                <td class="max-w-sm truncate">{email.subject}</td>
                <td>
                  <span class={[
                    "badge badge-sm",
                    status_badge_class(email.status)
                  ]}>
                    {email.status}
                  </span>
                </td>
                <td>
                  <%= for draft <- email.drafts do %>
                    <span class={[
                      "badge badge-sm",
                      if(draft.is_snarky, do: "badge-warning", else: "badge-success")
                    ]}>
                      {if draft.is_snarky, do: "snarky", else: "AI"}
                    </span>
                  <% end %>
                </td>
                <td class="text-sm opacity-70">
                  {format_time(email.received_at)}
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end

  defp status_badge_class("processed"), do: "badge-success"
  defp status_badge_class("processing"), do: "badge-info"
  defp status_badge_class("failed"), do: "badge-error"
  defp status_badge_class(_), do: "badge-ghost"

  defp format_time(nil), do: "-"
  defp format_time(dt), do: Calendar.strftime(dt, "%b %d, %H:%M")
end
