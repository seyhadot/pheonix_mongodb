defmodule LandliteAppWeb.API.V1.UserController do
  use LandliteAppWeb, :controller

  def index(conn, _params) do
    mongo_conn = LandliteApp.MongoDB.get_connection()
    users = Mongo.find(mongo_conn, "users", %{})
            |> Enum.to_list()
            |> Enum.map(&transform_user/1)
    json(conn, %{data: users})
  end

  def show(conn, %{"id" => id}) do
    mongo_conn = LandliteApp.MongoDB.get_connection()
    case Mongo.find_one(mongo_conn, "users", %{_id: BSON.ObjectId.decode!(id)}) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})
      user ->
        json(conn, %{data: transform_user(user)})
    end
  end

  def create(conn, %{"user" => user_params}) do
    mongo_conn = LandliteApp.MongoDB.get_connection()
    {:ok, result} = Mongo.insert_one(mongo_conn, "users", user_params)
    conn
    |> put_status(:created)
    |> json(%{data: %{id: BSON.ObjectId.encode!(result.inserted_id)}})
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    mongo_conn = LandliteApp.MongoDB.get_connection()
    case Mongo.find_one_and_update(mongo_conn, "users",
      %{_id: BSON.ObjectId.decode!(id)},
      %{"$set": user_params},
      return_document: :after
    ) do
      {:ok, nil} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})
      {:ok, updated_user} ->
        json(conn, %{data: transform_user(updated_user)})
    end
  end

  def delete(conn, %{"id" => id}) do
    mongo_conn = LandliteApp.MongoDB.get_connection()
    case Mongo.delete_one(mongo_conn, "users", %{_id: BSON.ObjectId.decode!(id)}) do
      {:ok, %{deleted_count: 1}} ->
        send_resp(conn, :no_content, "")
      {:ok, %{deleted_count: 0}} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "User not found"})
    end
  end

  def conversations(conn, %{"id" => user_id}) do
    mongo_conn = LandliteApp.MongoDB.get_connection()
    conversations = Mongo.aggregate(mongo_conn, "messages", [
      %{"$match": %{
        "$or": [
          %{sender_id: user_id},
          %{receiver_id: user_id}
        ]
      }},
      %{"$group": %{
        _id: %{
          "$cond": [
            %{"$eq": ["$sender_id", user_id]},
            "$receiver_id",
            "$sender_id"
          ]
        },
        last_message: %{"$last": "$$ROOT"}
      }},
      %{"$lookup": %{
        from: "users",
        localField: "_id",
        foreignField: "_id",
        as: "user"
      }},
      %{"$unwind": "$user"},
      %{"$project": %{
        _id: 1,
        user: %{name: 1, email: 1},
        last_message: 1
      }}
    ]) |> Enum.to_list()

    json(conn, %{data: conversations})
  end

  defp transform_user(user) do
    user
    |> Map.update("_id", nil, &BSON.ObjectId.encode!/1)
    |> Map.put("id", BSON.ObjectId.encode!(user["_id"]))
    |> Map.delete("_id")
  end
end
