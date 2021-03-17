# frozen_string_literal: true

require 'time'
require 'date'
require_relative 'optimum_trello'
require_relative 'ping_stats'

PACKET_LOSS_ACCEPTABLE_LIMIT = 10
PING_COUNT = 60
SUCCESSFUL_PING_DELAY_IN_SECS = 300 - PING_COUNT # 5 mins - Ping time

def write_output(data)
  puts data
  File.open("#{Date.today.iso8601}.txt", 'a') { |f| f.write "#{data}\n" }
end

def card_title
  Time.now.strftime('%I:%M %p  (%Y-%m-%d)')
end

seq = 1
highest_loss_pct = 0
program_start_time = Time.now

begin
  loop do
    start_time = Time.now
    ping = PingStats.create(PING_COUNT)
    end_time = Time.now

    elapsed_time = end_time - start_time
    highest_loss_pct = ping.stats[:loss_pct] if highest_loss_pct < ping.stats[:loss_pct]

    write_output "SEQ:[#{seq}] #{ping.stats.inspect} finished at [#{end_time.iso8601}]" \
                 " after #{elapsed_time.to_i} seconds"
    write_output "SEQ:[#{seq}] #{ping.stats_line}"

    if ping.stats[:loss_pct] >= PACKET_LOSS_ACCEPTABLE_LIMIT
      write_output "#{ping.output.join("\n")}\n#{ping.stats.inspect}\n"

      begin
        OptimumTrello.create_card(card_title, ping.stats_line, ping.output.join("\n"))
      rescue RestClient::Exceptions::OpenTimeout
        write_output 'Failed to create trello card, retrying...'
        retry
      end
    end

    # sleep(SUCCESSFUL_PING_DELAY_IN_SECS) if ping.stats[:loss_pct].zero?
    sleep(SUCCESSFUL_PING_DELAY_IN_SECS)
    seq += 1
  end
rescue Interrupt
  write_output "Highest loss percentage: [#{highest_loss_pct}]"
  write_output "Run times - Start: #{program_start_time.iso8601}  -  Stop: #{Time.now.iso8601}  " \
               "-  Elapsed: #{Time.now - program_start_time}"
  exit
end
