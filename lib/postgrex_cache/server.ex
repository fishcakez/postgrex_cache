defmodule PostgrexCache.Server do
  @moduledoc false

  use GenServer

  def insert_new(name, query) do
    # use insert_new to minimise churn of query (identified internally by
    # postgrex by unique reference on prepare)
    :ets.insert_new(__MODULE__, {name, query})
  end

  def fetch(name) do
    try do
      :ets.lookup_element(__MODULE__, name, 2)
    rescue
      ArgumentError ->
        # prepare + execute
        :error
    else
      query ->
        # execute
        {:ok, query}
    end
  end

  def delete(name, query) do
    # Only delete if query matches, other processes may have deleted and
    # replaced
    :ets.delete_object(__MODULE__, {name, query})
  end

  def start_link() do
    GenServer.start_link(__MODULE__, __MODULE__, [name: __MODULE__])
  end

  def init(tab) do
    {:ok, :ets.new(tab, [:named_table, :public])}
  end
end
