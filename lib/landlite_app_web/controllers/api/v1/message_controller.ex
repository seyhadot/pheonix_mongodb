defmodule LandliteAppWeb.API.V1.MessageController do
  use LandliteAppWeb, :controller

  def index(conn, %{"user_id" => user_id}) do
    mongo_conn = LandliteApp.MongoDB.get_connection()
    messages = Mongo.find(mongo_conn, "messages", %{
      "$or": [
        %{sender_id: user_id},
        %{receiver_id: user_id}
      ]
    })
    |> Enum.to_list()
    |> Enum.map(&transform_message/1)

    json(conn, %{data: messages})
  end

  def create(conn, %{"message" => message_params}) do
    mongo_conn = LandliteApp.MongoDB.get_connection()
    message = Map.merge(message_params, %{
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
    })
    {:ok, result} = Mongo.insert_one(mongo_conn, "messages", message)

    inserted_message = Mongo.find_one(mongo_conn, "messages", %{_id: result.inserted_id})

    conn
    |> put_status(:created)
    |> json(%{data: transform_message(inserted_message)})
  end

  defp transform_message(message) do
    message
    |> Map.update("_id", nil, &BSON.ObjectId.encode!/1)
    |> Map.put("id", BSON.ObjectId.encode!(message["_id"]))
    |> Map.delete("_id")
  end
end
