defmodule Dbot.Email.Poller do
  use GenServer
  require Logger

  @default_interval_ms 5 * 60 * 1000
  @initial_delay_ms 10_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def poll_now do
    GenServer.cast(__MODULE__, :poll)
  end

  def get_status do
    GenServer.call(__MODULE__, :status)
  end

  @impl GenServer
  def init(_opts) do
    interval = Application.get_env(:dbot, :poll_interval_ms, @default_interval_ms)

    if Application.get_env(:dbot, :google_credentials_path) do
      Process.send_after(self(), :poll, @initial_delay_ms)
      Logger.info("[Poller] Started, polling every #{div(interval, 1000)}s")
    else
      Logger.warning("[Poller] Google credentials not configured — polling disabled")
    end

    {:ok, %{interval_ms: interval, last_polled_at: nil, poll_count: 0, status: :idle}}
  end

  @impl GenServer
  def handle_cast(:poll, state) do
    {:noreply, do_poll(state)}
  end

  @impl GenServer
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_info(:poll, state) do
    new_state = do_poll(state)
    Process.send_after(self(), :poll, new_state.interval_ms)
    {:noreply, new_state}
  end

  defp do_poll(state) do
    Logger.info("[Poller] Poll ##{state.poll_count + 1} starting")

    case Dbot.Email.fetch_and_process_new() do
      {:ok, 0} -> Logger.info("[Poller] No new emails")
      {:ok, n} -> Logger.info("[Poller] Dispatched #{n} new email(s)")
      {:error, e} -> Logger.error("[Poller] Error: #{inspect(e)}")
    end

    %{state | status: :idle, last_polled_at: DateTime.utc_now(), poll_count: state.poll_count + 1}
  end
end
