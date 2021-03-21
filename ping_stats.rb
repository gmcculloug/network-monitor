# frozen_string_literal: true

# Runs ping and parses output
class PingStats
  PING_STATS_REGEX = /(?<transmitted>\d+) .* (?<received>\d+) .* (?<loss_pct>\d+.?\d?+)%/.freeze

  attr_reader :output, :stats_line, :stats, :ping_count

  def initialize(address, ping_count = nil)
    @address = address
    @ping_count = ping_count || 60
  end

  def self.create(address, ping_count = nil)
    new(address, ping_count).tap(&:run_ping)
  end

  def run_ping
    @output = `ping -c #{PING_COUNT} #{@address}`.split("\n")
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
