require 'time'
require 'date'

PING_COUNT = 60
PACKET_LOSS_ACCEPTABLE_LIMIT = 10
SUCCESSFUL_PING_DELAY_IN_SECS = 300 - PING_COUNT   # 5 mins - Ping time
PING_TARGET_ADDRESS = '8.8.8.8'.freeze
PING_STATS_REGEX = /(?<transmitted>\d+) .* (?<received>\d+) .* (?<loss_pct>\d+.?\d?+)%/.freeze

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

def write_output(data)
  puts data
  File.open("#{Date.today.iso8601}.txt", 'a') { |f| f.write data + "\n" }
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

    write_output "SEQ:[#{seq}] #{stats.inspect} finished at [#{end_time.iso8601}] after #{elapsed_time.to_i} seconds"
    write_output "#{all_output.join("\n")}\n#{stats.inspect}\n" if stats[:loss_pct] >= PACKET_LOSS_ACCEPTABLE_LIMIT

    sleep(SUCCESSFUL_PING_DELAY_IN_SECS) if stats[:loss_pct].zero?
    seq += 1
  end
rescue Interrupt
  write_output "Highest loss percentage: [#{highest_loss_pct}]"
  write_output "Run times - Start: #{program_start_time.iso8601}  -  Stop: #{Time.now.iso8601}  -  Elapsed: #{Time.now - program_start_time}"
  exit
end
