PING_COUNT = 60
PACKET_LOSS_ACCEPTABLE_LIMIT = 10
SUCCESSFUL_PING_DELAY_IN_SECS = 300 - PING_COUNT
PING_TARGET_ADDRESS = '8.8.8.8'.freeze
PING_STATS_REGEX = /(?<transmitted>\d+) .* (?<received>\d+) .* (?<loss_pct>\d+.?\d?+)%/.freeze

require 'time'

def run_ping
  all_output = `ping -c #{PING_COUNT} #{PING_TARGET_ADDRESS}`.split("\n")
  packet_stats = all_output[-2]
  [parse_stats(packet_stats), all_output]
end

def parse_stats(packet_stats)
  stats = PING_STATS_REGEX.match(packet_stats)
  {
    :transmitted => stats[:transmitted].to_i,
    :received => stats[:received].to_i,
    :loss_pct => stats[:loss_pct].to_f
  }
end

seq = 1
highest_loss_pct = 0
program_start_time = Time.now

begin
  loop do
    start_time = Time.now
    stats, all_output = run_ping
    end_time = Time.now
    elapsed_time = end_time - start_time
    highest_loss_pct = stats[:loss_pct] if highest_loss_pct < stats[:loss_pct]

    puts "SEQ:[#{seq}] #{stats.inspect} finished at [#{end_time.iso8601}] after #{elapsed_time.to_i} seconds"

    if stats[:loss_pct] >= PACKET_LOSS_ACCEPTABLE_LIMIT
      puts
      puts all_output.join("\n")
      puts
      puts stats.inspect
    end

    sleep(SUCCESSFUL_PING_DELAY_IN_SECS) if stats[:loss_pct].zero?
    seq += 1
  end
rescue Interrupt
  puts
  puts "Highest loss percentage: [#{highest_loss_pct}]"
  puts "Run times:"
  puts "Start:   #{program_start_time.iso8601}"
  puts "Stop:    #{Time.now.iso8601}"
  puts "Elapsed: #{Time.now - program_start_time}"
  exit
end
