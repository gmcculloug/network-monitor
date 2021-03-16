# frozen_string_literal: true

# Runs ping and parses output
class PingStats
  PING_TARGET_ADDRESS = '8.8.8.8'
  PING_STATS_REGEX = /(?<transmitted>\d+) .* (?<received>\d+) .* (?<loss_pct>\d+.?\d?+)%/.freeze

  attr_reader :output, :stats_line, :stats, :ping_count

  def initialize(ping_count = nil)
    @ping_count = ping_count || 60
  end

  def self.create(ping_count = nil)
    new(ping_count).tap(&:run_ping)
  end

  def run_ping
    @output = `ping -c #{PING_COUNT} #{PING_TARGET_ADDRESS}`.split("\n")
    @stats_line = @output[-2]
    @stats = parse_stats(@stats_line)
  end

  def parse_stats(stats)
    stats = PING_STATS_REGEX.match(stats)
    {
      # rubocop:disable Style/HashSyntax
      :transmitted => stats[:transmitted].to_i,
      :received => stats[:received].to_i,
      :loss_pct => stats[:loss_pct].to_f
      # rubocop:enable Style/HashSyntax
    }
  end
end
