defmodule DbotWeb.SettingsLive do
  use DbotWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_data(socket)}
  end

  defp load_data(socket) do
    assign(socket,
      page_title: "Settings",
      ollama_available: Dbot.Llm.available?(),
      ollama_model: Application.get_env(:dbot, :ollama_model),
      ollama_base_model: Application.get_env(:dbot, :ollama_base_model),
      ollama_base_url: Application.get_env(:dbot, :ollama_base_url),
      poll_interval_ms: Application.get_env(:dbot, :poll_interval_ms),
      google_configured: Application.get_env(:dbot, :google_credentials_path) != nil,
      twilio_configured: Application.get_env(:ex_twilio, :account_sid) != nil,
      notification_phone: Application.get_env(:dbot, :notification_phone),
      notification_backends: Application.get_env(:dbot, :notification_backends, [:ntfy]),
      ntfy_topic: Application.get_env(:dbot, :ntfy_topic)
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-2xl font-bold">Settings</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="card bg-base-200 shadow-sm">
          <div class="card-body">
            <h2 class="card-title">Ollama</h2>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="opacity-70">Status</span>
                <span class={if @ollama_available, do: "text-success", else: "text-error"}>
                  {if @ollama_available, do: "Connected", else: "Unavailable"}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="opacity-70">Base URL</span>
                <span>{@ollama_base_url}</span>
              </div>
              <div class="flex justify-between">
                <span class="opacity-70">Reply Model</span>
                <span>{@ollama_model}</span>
              </div>
              <div class="flex justify-between">
                <span class="opacity-70">Classifier Model</span>
                <span>{@ollama_base_model}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="card bg-base-200 shadow-sm">
          <div class="card-body">
            <h2 class="card-title">Gmail</h2>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="opacity-70">OAuth Configured</span>
                <span class={if @google_configured, do: "text-success", else: "text-error"}>
                  {if @google_configured, do: "Yes", else: "No"}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="opacity-70">Poll Interval</span>
                <span>{div(@poll_interval_ms || 300_000, 1000)}s</span>
              </div>
            </div>
          </div>
        </div>

        <div class="card bg-base-200 shadow-sm">
          <div class="card-body">
            <h2 class="card-title">Notifications</h2>
            <div class="space-y-2 text-sm">
              <div class="flex justify-between">
                <span class="opacity-70">Active Backends</span>
                <span>{Enum.map_join(@notification_backends, ", ", &Atom.to_string/1)}</span>
              </div>
              <div class="flex justify-between">
                <span class="opacity-70">Ntfy Topic</span>
                <span class={if @ntfy_topic, do: "text-success", else: "text-error"}>
                  {@ntfy_topic || "Not set"}
                </span>
              </div>
              <div class="flex justify-between">
                <span class="opacity-70">Twilio Configured</span>
                <span class={if @twilio_configured, do: "text-success", else: "text-error"}>
                  {if @twilio_configured, do: "Yes", else: "No"}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
