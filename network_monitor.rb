# frozen_string_literal: true

require 'time'
require 'date'
require_relative 'optimum_trello'
require_relative 'ping_stats'

PACKET_LOSS_ACCEPTABLE_LIMIT = 5
PING_COUNT = 5
SUCCESSFUL_PING_DELAY_IN_SECS = 300 - PING_COUNT # 5 mins - Ping time
PING_EXTERNAL_TARGET_ADDRESS = '8.8.8.8'
PING_PROVIDER_TARGET_ADDRESS = '69.119.60.228'
OPTIMUM_OUTPUT_PATH = ENV['OPTIMUM_OUTPUT_PATH']

def write_output(data)
  puts data
  File.open(output_file("#{Date.today.iso8601}.txt"), 'a') { |f| f.write "#{data}\n" }
end

def write_stats(ext_stats, int_stats)
  File.open(output_file('network_monitor.csv'), 'a') do |f|
    f.write "#{Time.now.iso8601},#{ext_stats[:loss_pct]},#{int_stats[:loss_pct]}\n"
  end
end

def output_file(filename)
  OPTIMUM_OUTPUT_PATH ? File.join(OPTIMUM_OUTPUT_PATH, filename) : filename
end

def card_title(ping)
  Time.now.strftime("%I:%M %p  (%Y-%m-%d) - Packet Loss: #{ping.stats[:loss_pct]}%%")
end

def run_pings
  [
    PingStats.new(PING_EXTERNAL_TARGET_ADDRESS, PING_COUNT),
    PingStats.new(PING_PROVIDER_TARGET_ADDRESS, PING_COUNT)
  ].tap do |pings|
    threads = []
    pings.each { |p| threads << Thread.new { p.run_ping } }
    threads.each(&:join)
  end
end

def main(unsent_pings)
  seq = 1
  highest_loss_pct = 0
  program_start_time = Time.now

  loop do
    start_time = Time.now
    ping_ext, ping_int = run_pings
    end_time = Time.now

    elapsed_time = end_time - start_time
    highest_loss_pct = ping_ext.stats[:loss_pct] if highest_loss_pct < ping_ext.stats[:loss_pct]

    write_output "[#{seq}] #{ping_ext.stats.inspect} finished at [#{end_time.iso8601}] after #{elapsed_time.to_i} seconds"
    write_stats(ping_ext.stats, ping_int.stats)

    if ping_ext.stats[:loss_pct] >= PACKET_LOSS_ACCEPTABLE_LIMIT
      write_output "#{ping_ext.output.join("\n")}\n#{ping_ext.stats.inspect}\n"
      unsent_pings << ping_ext
    end

    # sleep(SUCCESSFUL_PING_DELAY_IN_SECS) if ping.stats[:loss_pct].zero?
    # sleep(SUCCESSFUL_PING_DELAY_IN_SECS)
    seq += 1
  end
rescue Interrupt
  write_output "Highest loss percentage: [#{highest_loss_pct}]"
  write_output "Run times - Start: #{program_start_time.iso8601}  -  Stop: #{Time.now.iso8601}  " \
                "-  Elapsed: #{Time.now - program_start_time}"
  exit
end

unsent_pings = []
threads = []

threads << Thread.new { OptimumTrello.watcher_thread(unsent_pings) }
threads << Thread.new { main(unsent_pings) }
threads.each(&:join)

