defmodule Benchee.StatistcsTest do
  use ExUnit.Case, async: true
  alias Benchee.{Statistics, Suite, Benchmark.Scenario}
  doctest Benchee.Statistics

  @sample_1 [600, 470, 170, 430, 300]
  @sample_2 [17, 15, 23, 7, 9, 13]
  describe ".statistics" do
    test "computes the statistics for all jobs correctly" do
      scenarios = [
        %Scenario{
          input: "Input",
          input_name: "Input",
          job_name: "Job 1",
          run_times: @sample_1,
          memory_usages: @sample_1
        },
        %Scenario{
          input: "Input",
          input_name: "Input",
          job_name: "Job 2",
          run_times: @sample_2,
          memory_usages: @sample_2
        }
      ]

      suite = %Suite{scenarios: scenarios}
      new_suite = Statistics.statistics(suite)

      stats_1 = stats_for(new_suite, "Job 1", "Input")
      stats_2 = stats_for(new_suite, "Job 2", "Input")

      sample_1_asserts(stats_1)
      sample_2_asserts(stats_2)
    end

    test "computes statistics correctly for multiple inputs" do
      scenarios = [
        %Scenario{
          input: "Input 1",
          input_name: "Input 1",
          job_name: "Job",
          run_times: @sample_1,
          memory_usages: @sample_1
        },
        %Scenario{
          input: "Input 2",
          input_name: "Input 2",
          job_name: "Job",
          run_times: @sample_2,
          memory_usages: @sample_2
        }
      ]

      suite = %Suite{scenarios: scenarios}
      new_suite = Statistics.statistics(suite)

      stats_1 = stats_for(new_suite, "Job", "Input 1")
      stats_2 = stats_for(new_suite, "Job", "Input 2")

      sample_1_asserts(stats_1)
      sample_2_asserts(stats_2)
    end

    @mode_sample [55, 40, 67, 55, 44, 40, 10, 8, 55, 90, 67]
    test "mode is calculated correctly" do
      scenarios = [%Scenario{run_times: @mode_sample, memory_usages: @mode_sample}]
      suite = Statistics.statistics(%Suite{scenarios: scenarios})

      [%Scenario{run_time_statistics: stats}] = suite.scenarios
      assert stats.mode == 55
    end

    @standard_deviation_sample [600, 470, 170, 430, 300]
    test "statistical standard deviation is calculated correctly" do
      scenarios = [
        %Scenario{
          run_times: @standard_deviation_sample,
          memory_usages: @standard_deviation_sample
        }
      ]

      suite = Statistics.statistics(%Suite{scenarios: scenarios})

      [%Scenario{run_time_statistics: stats}] = suite.scenarios
      assert_in_delta stats.std_dev, 164.7, 0.1
      assert_in_delta stats.std_dev_ratio, 0.41, 0.01
    end

    test "preserves all other keys in the map handed to it" do
      suite = %Suite{
        scenarios: [],
        configuration: %{formatters: []}
      }

      assert %Suite{configuration: %{formatters: []}} = Statistics.statistics(suite)
    end

    @all_zeros [0, 0, 0, 0, 0]
    test "doesn't blow up when all measurements are zeros (mostly memory measurement)" do
      scenarios = [%Scenario{run_times: @all_zeros, memory_usages: @all_zeros}]
      suite = Statistics.statistics(%Suite{scenarios: scenarios})

      [%Scenario{run_time_statistics: run_time_stats, memory_usage_statistics: memory_stats}] =
        suite.scenarios

      assert run_time_stats.sample_size == 5
      assert memory_stats.sample_size == 5
    end

    defp stats_for(suite, job_name, input_name) do
      %Scenario{run_time_statistics: stats} =
        Enum.find(suite.scenarios, fn scenario ->
          scenario.job_name == job_name && scenario.input_name == input_name
        end)

      stats
    end

    defp sample_1_asserts(stats) do
      assert stats.average == 394.0
      assert_in_delta stats.std_dev, 164.71, 0.01
      assert_in_delta stats.std_dev_ratio, 0.41, 0.01
      assert_in_delta stats.ips, 2538, 1
      assert stats.median == 430.0
      assert stats.minimum == 170
      assert stats.maximum == 600
      assert stats.sample_size == 5
      assert stats.mode == nil
    end

    defp sample_2_asserts(stats) do
      assert stats.average == 14.0
      assert_in_delta stats.std_dev, 5.76, 0.01
      assert_in_delta stats.std_dev_ratio, 0.41, 0.01
      assert_in_delta stats.ips, 71_428, 1
      assert stats.median == 14.0
      assert stats.minimum == 7
      assert stats.maximum == 23
      assert stats.sample_size == 6
      assert stats.mode == nil
    end
  end

  describe ".sort" do
    test "sorts the benchmarks correctly and retains all data" do
      fourth = %Scenario{run_time_statistics: %Statistics{average: 400.1}}
      second = %Scenario{run_time_statistics: %Statistics{average: 200.0}}
      third = %Scenario{run_time_statistics: %Statistics{average: 400.0}}
      first = %Scenario{run_time_statistics: %Statistics{average: 100.0}}
      scenarios = [fourth, second, third, first]

      assert Statistics.sort(scenarios) == [first, second, third, fourth]
    end
  end
end
