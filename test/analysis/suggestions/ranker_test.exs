defmodule Ragex.Analysis.Suggestions.RankerTest do
  use ExUnit.Case, async: true

  alias Ragex.Analysis.Suggestions.Ranker

  describe "score_suggestion/1" do
    test "scores suggestion with all factors" do
      suggestion = %{
        pattern: :extract_function,
        confidence: 0.85,
        benefit_score: 0.8,
        effort_score: 0.5,
        impact: %{affected_files: 3, risk: :medium}
      }

      scored = Ranker.score_suggestion(suggestion)

      assert scored.priority_score > 0
      assert scored.priority_score <= 1.0
      assert scored.priority in [:info, :low, :medium, :high, :critical]
    end

    test "assigns critical priority for high scores" do
      suggestion = %{
        confidence: 0.9,
        benefit_score: 0.95,
        effort_score: 0.1,
        impact: %{affected_files: 10, risk: :low}
      }

      scored = Ranker.score_suggestion(suggestion)

      assert scored.priority in [:high, :critical]
      assert scored.priority_score > 0.6
    end

    test "assigns low priority for marginal suggestions" do
      suggestion = %{
        confidence: 0.3,
        benefit_score: 0.2,
        effort_score: 0.8,
        impact: %{affected_files: 1, risk: :high}
      }

      scored = Ranker.score_suggestion(suggestion)

      assert scored.priority in [:info, :low]
    end
  end

  describe "classify_priority/1" do
    test "classifies critical correctly" do
      assert Ranker.classify_priority(0.85) == :critical
      assert Ranker.classify_priority(0.95) == :critical
    end

    test "classifies high correctly" do
      assert Ranker.classify_priority(0.65) == :high
      assert Ranker.classify_priority(0.75) == :high
    end

    test "classifies medium correctly" do
      assert Ranker.classify_priority(0.45) == :medium
      assert Ranker.classify_priority(0.55) == :medium
    end

    test "classifies low correctly" do
      assert Ranker.classify_priority(0.25) == :low
      assert Ranker.classify_priority(0.35) == :low
    end

    test "classifies info correctly" do
      assert Ranker.classify_priority(0.15) == :info
      assert Ranker.classify_priority(0.05) == :info
    end
  end

  describe "calculate_roi/1" do
    test "calculates ROI correctly" do
      suggestion = %{
        benefit_score: 0.8,
        effort_score: 0.4
      }

      roi = Ranker.calculate_roi(suggestion)

      assert roi == 2.0
    end

    test "handles edge case with minimal effort" do
      suggestion = %{
        benefit_score: 0.5,
        effort_score: 0.01
      }

      roi = Ranker.calculate_roi(suggestion)

      assert roi > 0
    end
  end

  describe "adjust_for_pattern/1" do
    test "boosts dead code removal suggestions" do
      suggestion = %{
        pattern: :remove_dead_code,
        priority_score: 0.5,
        priority: :medium
      }

      adjusted = Ranker.adjust_for_pattern(suggestion)

      assert adjusted.priority_score > suggestion.priority_score
    end

    test "slightly boosts complexity suggestions" do
      suggestion = %{
        pattern: :simplify_complexity,
        priority_score: 0.6,
        priority: :high
      }

      adjusted = Ranker.adjust_for_pattern(suggestion)

      assert adjusted.priority_score >= suggestion.priority_score
    end

    test "slightly penalizes split_module suggestions" do
      suggestion = %{
        pattern: :split_module,
        priority_score: 0.7,
        priority: :high
      }

      adjusted = Ranker.adjust_for_pattern(suggestion)

      assert adjusted.priority_score <= suggestion.priority_score
    end
  end

  describe "filter_by_priority/2" do
    setup do
      suggestions = [
        %{id: 1, priority: :critical},
        %{id: 2, priority: :high},
        %{id: 3, priority: :medium},
        %{id: 4, priority: :low},
        %{id: 5, priority: :info}
      ]

      %{suggestions: suggestions}
    end

    test "filters by high priority", %{suggestions: suggestions} do
      filtered = Ranker.filter_by_priority(suggestions, :high)

      assert length(filtered) == 2
      assert Enum.all?(filtered, fn s -> s.priority in [:critical, :high] end)
    end

    test "filters by medium priority", %{suggestions: suggestions} do
      filtered = Ranker.filter_by_priority(suggestions, :medium)

      assert length(filtered) == 3
    end

    test "includes all when filtering by info", %{suggestions: suggestions} do
      filtered = Ranker.filter_by_priority(suggestions, :info)

      assert length(filtered) == 5
    end
  end

  describe "calculate_statistics/1" do
    test "calculates statistics correctly" do
      suggestions = [
        %{priority: :critical, priority_score: 0.9, benefit_score: 0.8, effort_score: 0.3},
        %{priority: :high, priority_score: 0.7, benefit_score: 0.7, effort_score: 0.4},
        %{priority: :medium, priority_score: 0.5, benefit_score: 0.5, effort_score: 0.5}
      ]

      stats = Ranker.calculate_statistics(suggestions)

      assert stats.total == 3
      assert stats.by_priority[:critical] == 1
      assert stats.by_priority[:high] == 1
      assert stats.by_priority[:medium] == 1
      assert stats.high_priority_count == 2
      assert stats.average_score > 0
      assert stats.average_roi > 0
    end

    test "handles empty list" do
      stats = Ranker.calculate_statistics([])

      assert stats.total == 0
      assert stats.average_score == 0.0
      assert stats.average_roi == 0.0
    end
  end
end
