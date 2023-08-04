defmodule StreamazeWeb.StripeWebhookController do
  use StreamazeWeb, :controller
  alias Streamaze.Payments

  def index(conn, params) do
    status = params["data"]["object"]["status"]
    type = params["type"]

    case type do
      "customer.subscription.updated" ->
        customer = Payments.get_customer_by_stripe_id(params["data"]["object"]["customer"])

        {:ok, _} =
          Payments.update_subscription(%{
            customer_id: customer.id,
            current_period_end: params["data"]["object"]["current_period_end"],
            status: status
          })

      "customer.subscription.deleted" ->
        customer = Payments.get_customer_by_stripe_id(params["data"]["object"]["customer"])
        subscription = Payments.get_stripe_subscription!(params["data"]["object"]["id"])

        {:ok, _} =
          Payments.delete_subscription(subscription.id)

        {:ok, _} =
          Payments.update_customer(customer, %{
            plan: nil
          })

      "customer.subscription.created" ->
        customer = Payments.get_customer_by_stripe_id(params["data"]["object"]["customer"])
        plan = params["data"]["object"]["plan"]["id"]

        {:ok, _} =
          Payments.create_subscription(%{
            stripe_id: params["data"]["object"]["id"],
            customer_id: customer.id,
            current_period_end: params["data"]["object"]["current_period_end"],
            status: status,
            trial_end: params["data"]["object"]["trial_end"]
          })

        {:ok, _} =
          Payments.update_customer(customer, %{
            plan: plan
          })

      "checkout.session.completed" ->
        metadata = params["data"]["object"]["metadata"]
        user_id = metadata["user_id"]
        customer = Payments.get_customer_by_stripe_id(params["data"]["object"]["customer"])

        if is_nil(customer) do
          {:ok, _} =
            Payments.create_customer(%{
              stripe_id: params["data"]["object"]["customer"],
              email: params["data"]["object"]["customer_details"]["email"],
              name: params["data"]["object"]["customer_details"]["name"],
              user_id: user_id,
              plan: metadata["plan"]
            })
        end

      _ ->
        IO.puts("Unhandled Stripe event: #{type}")
    end

    send_resp(conn, 200, "OK")
  end
end
