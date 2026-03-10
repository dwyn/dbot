defmodule DbotWeb.TrainingLive do
  use DbotWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, load_data(socket)}
  end

  @impl true
  def handle_event("toggle_approved", %{"id" => id}, socket) do
    Dbot.Training.toggle_approved(String.to_integer(id))
    {:noreply, load_data(socket)}
  end

  @impl true
  def handle_event("export_jsonl", _params, socket) do
    case Dbot.Training.Export.export_jsonl() do
      {:ok, count} ->
        {:noreply,
         put_flash(
           socket,
           :info,
           "Exported #{count} examples to priv/training_data/dataset.jsonl"
         )}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Export failed: #{inspect(reason)}")}
    end
  end

  defp load_data(socket) do
    assign(socket,
      page_title: "Training Data",
      examples: Dbot.Training.list_examples(),
      total_count: Dbot.Training.count_examples(),
      approved_count: Dbot.Training.count_approved()
    )
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex justify-between items-center">
        <h1 class="text-2xl font-bold">Training Data</h1>
        <div class="flex items-center gap-4">
          <span class="text-sm opacity-70">
            {@approved_count} / {@total_count} approved
          </span>
          <button phx-click="export_jsonl" class="btn btn-primary btn-sm">
            Export JSONL
          </button>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="table table-zebra w-full">
          <thead>
            <tr>
              <th>Input (received email)</th>
              <th>Output (your reply)</th>
              <th>Approved</th>
            </tr>
          </thead>
          <tbody>
            <%= if @examples == [] do %>
              <tr>
                <td colspan="3" class="text-center opacity-50 py-8">
                  No training examples yet. Import your sent email history to get started.
                </td>
              </tr>
            <% end %>
            <%= for example <- @examples do %>
              <tr>
                <td class="max-w-xs">
                  <div class="text-sm line-clamp-3">{example.input}</div>
                </td>
                <td class="max-w-xs">
                  <div class="text-sm line-clamp-3">{example.output}</div>
                </td>
                <td>
                  <input
                    type="checkbox"
                    class="toggle toggle-sm toggle-success"
                    checked={example.approved}
                    phx-click="toggle_approved"
                    phx-value-id={example.id}
                  />
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end
end
