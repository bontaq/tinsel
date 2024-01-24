defmodule Tinsel.Message do
  defstruct [:type, :raw]
  @type t :: %__MODULE__{type: String.t(), raw: String.t()}
end
