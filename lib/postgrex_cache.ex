defmodule PostgrexCache do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(PostgrexCache.Server, []),
      Postgrex.child_spec([name: __MODULE__] ++ fetch_opts())
    ]

    opts = [strategy: :rest_for_one, name: PostgrexCache.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def query(name, query, params) do
    case PostgrexCache.Server.fetch(name) do
      {:ok, query} ->
        execute(name, query, params)
      :error ->
        prepare_execute(name, query, params)
    end
  end

  # Helpers

  defp prepare_execute(name, statement, params) do
    query = %Postgrex.Query{name: name, statement: statement}
    opts = [function: :prepare_execute] ++ fetch_opts()
    case DBConnection.prepare_execute(__MODULE__, query, params, opts) do
      {:ok, query, result} ->
        _ = PostgrexCache.Server.insert_new(name, query)
        {:ok, result}
      {:error, %Postgrex.Error{}} = error ->
        error
      {:error, err} ->
        raise err
    end
  end

  defp execute(name, query, params) do
    opts = fetch_opts()
    case DBConnection.execute(__MODULE__, query, params, opts) do
      {:ok, _} = ok ->
        ok
      {:error, %ArgumentError{} = err} ->
        PostgrexCache.Server.delete(name, query)
        raise err
      {:error, %Postgrex.Error{postgres: %{code: :feature_not_supported}}} = err ->
        PostgrexCache.Server.delete(name, query)
        err
      {:error, %Postgrex.Error{}} = error ->
        error
      {:error, err} ->
        raise err
    end
  end

  defp fetch_opts() do
    Application.fetch_env!(:postgrex_cache, :postgrex)
  end
end
