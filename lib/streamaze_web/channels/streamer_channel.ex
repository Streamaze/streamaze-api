defmodule StreamazeWeb.StreamerChannel do
  use Phoenix.Channel

  alias Streamaze.Accounts
  alias Streamaze.OBS
  alias Streamaze.Streams
  alias Streamaze.Finances

  defp authorized?(streamer_id, given_token) do
    found_user = Accounts.get_user_by_api_key(given_token)

    case found_user do
      %Accounts.User{:api_key => api_key} ->
        given_token === api_key and found_user.streamer_id === String.to_integer(streamer_id)

      _ ->
        false
    end
  end

  def join("streamer:" <> streamer_id, payload, socket) do
    if authorized?(streamer_id, payload["userToken"]) do
      socket = assign(socket, :streamer_id, streamer_id)
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("switch_scene", %{"scene" => scene} = payload, socket) do
    # TODO: Figure out how this should be dynamic
    streamer_key = "sam"

    case OBS.switch_scene(streamer_key, scene) do
      :ok ->
        {:reply, {:ok, payload}, socket}

      {:error, _} ->
        payload = Map.put(payload, "reason", "Error switching to #{scene}")
        {:reply, {:error, payload}, socket}
    end
  end

  def handle_in("start_server", %{"service" => service} = payload, socket) do
    # TODO: Figure out how this should be dynamic
    streamer_key = "sam"

    case OBS.start_server(streamer_key, %{"service" => service}) do
      :ok ->
        {:reply, {:ok, payload}, socket}

      {:error, _} ->
        payload = Map.put(payload, "reason", "Error starting #{service} server")
        {:reply, {:error, payload}, socket}
    end
  end

  def handle_in("stop_server", payload, socket) do
    # TODO: Figure out how this should be dynamic
    streamer_key = "sam"

    case OBS.stop_server(streamer_key) do
      :ok ->
        {:reply, {:ok, payload}, socket}

      {:error, _} ->
        payload = Map.put(payload, "reason", "Error stopping server")
        {:reply, {:error, payload}, socket}
    end
  end

  def handle_in("start_broadcast", payload, socket) do
    # TODO: Figure out how this should be dynamic
    streamer_key = "sam"

    case OBS.start_broadcast(streamer_key) do
      :ok ->
        {:reply, {:ok, payload}, socket}

      {:error, _} ->
        payload = Map.put(payload, "reason", "Error starting broadcast")
        {:reply, {:error, payload}, socket}
    end
  end

  def handle_in("stop_broadcast", payload, socket) do
    # TODO: Figure out how this should be dynamic
    streamer_key = "sam"

    case OBS.stop_broadcast(streamer_key) do
      :ok ->
        {:reply, {:ok, payload}, socket}

      {:error, _} ->
        payload = Map.put(payload, "reason", "Error stopping broadcast")
        {:reply, {:error, payload}, socket}
    end
  end

  def handle_in("stop_pi", payload, socket) do
    # TODO: Figure out how this should be dynamic
    streamer_key = "sam"

    case OBS.stop_pi(streamer_key) do
      :ok ->
        {:reply, {:ok, payload}, socket}

      {:error, _} ->
        payload = Map.put(payload, "reason", "Error stopping Pi")
        {:reply, {:error, payload}, socket}
    end
  end

  def handle_info(:after_join, socket) do
    streamer_id = socket.assigns.streamer_id
    active_stream = Streams.get_live_stream_by_streamer_id(streamer_id)
    latest_donations = Finances.list_streamer_donations(streamer_id)

    if active_stream do
      push(socket, "initial_state", %{
        net_profit: Streams.get_streamers_net_profit(streamer_id),
        active_stream: %{
          id: active_stream.id,
          streamer_id: active_stream.streamer_id,
          donation_goal: active_stream.donation_goal,
          donation_goal_currency: active_stream.donation_goal_currency,
          start_time: active_stream.start_time,
          is_live: active_stream.is_live,
          is_subathon: active_stream.is_subathon,
          subathon_minutes_per_dollar: active_stream.subathon_minutes_per_dollar,
          subathon_seconds_added: active_stream.subathon_seconds_added,
          subathon_start_minutes: active_stream.subathon_start_minutes,
          subathon_start_time: active_stream.subathon_start_time,
          subathon_ended_time: active_stream.subathon_ended_time
        },
        last_10_donations:
          Enum.map(latest_donations, fn donation ->
            %{
              type: donation.type,
              display_string: Money.to_string(donation.value),
              message: donation.message,
              sender: donation.sender,
              streamer_id: donation.streamer_id,
              inserted_at: donation.inserted_at,
              amount_in_usd: donation.amount_in_usd,
              metadata: donation.metadata,
              value: %{
                amount: donation.value.amount,
                currency: donation.value.currency
              }
            }
          end)
      })
    end

    {:noreply, socket}
  end
end
