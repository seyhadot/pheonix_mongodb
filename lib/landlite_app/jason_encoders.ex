defimpl Jason.Encoder, for: BSON.ObjectId do
  def encode(id, opts) do
    BSON.ObjectId.encode!(id)
    |> Jason.Encoder.encode(opts)
  end
end
