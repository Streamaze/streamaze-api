defmodule StreamazeWeb.ExpenseLive.Show do
  use StreamazeWeb, :live_view

  alias Streamaze.Finances

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:expense, Finances.get_expense!(id))}
  end

  defp page_title(:show), do: "Show Expense"
  defp page_title(:edit), do: "Edit Expense"
end
