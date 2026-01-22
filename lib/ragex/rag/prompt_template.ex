defmodule Ragex.RAG.PromptTemplate do
  @moduledoc """
  Manages prompt engineering templates.
  """

  def render(:query, vars) do
    """
    #{vars.system_prompt}

    # Code Context

    #{vars.context}

    # User Query

    #{vars.query}

    Please provide a detailed answer based on the code context above.
    Include specific references to files and functions when relevant.
    """
  end

  def render(:explain, vars) do
    """
    Explain the following code in detail:

    #{vars.context}

    Focus on: #{vars.aspect}
    """
  end

  def render(:suggest, vars) do
    """
    Review the following code and suggest improvements:

    #{vars.context}

    Focus area: #{vars.focus}

    Provide specific, actionable recommendations.
    """
  end
end
