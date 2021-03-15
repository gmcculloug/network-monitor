# frozen_string_literal: false

# OptimumTrello class creates lists/cards in Trello based on the date
class OptimumTrello
  TRELLO_DEVELOPER_PUBLIC_KEY = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
  TRELLO_MEMBER_TOKEN         = ENV['TRELLO_MEMBER_TOKEN']
  TRELLO_BOARD_NAME           = 'Optimum'
  MAX_CARD_DESCRIPITON        = 16_384

  require 'trello'

  Trello.configure do |config|
    config.developer_public_key = TRELLO_DEVELOPER_PUBLIC_KEY
    config.member_token = TRELLO_MEMBER_TOKEN
  end

  def self.create_card(name, ping_output)
    new.create_card(name, ping_output)
  end

  def create_card(name, ping_output)
    byebug
    Trello::Card.create(
      :name => name,
      :list_id => find_or_create_list.id,
      :desc => Time.now.iso8601,
      :pos => 'top'
    ).tap { |card| add_comments(card, ping_output) }
  end

  private
  
  def find_optimum_board
    Trello::Board.all.detect { |b| b.name == TRELLO_BOARD_NAME }
  end

  def find_or_create_list
    board = find_optimum_board
    raise "Error: Board [#{TRELLO_BOARD_NAME}] not found" if board.nil?

    today = Date.today.iso8601
    list = board.lists.detect { |l| l.name == today }
    list = Trello::List.create(:name => today, :board_id => board.id, :pos => 1) if list.nil?
    raise "Error: Failed to create list for today [#{today}]" if list.nil?

    list
  end

  def add_comments(card, ping_output)
    # Use reverse! as new comments appear at the top of the card.
    # This allows the ping output to be read top to bottom.
    chunk_output(ping_output).reverse!.each do |comment|
      card.add_comment(comment)
    end
  end

  def chunk_output(ping_output)
    result = [] << data = ''

    ping_output.split("\n").each do |new_str|
      new_str << "\n"
      result << data = '' if data.length + new_str.length >= MAX_CARD_DESCRIPITON
      data << new_str
    end

    result
  end
end

require 'byebug'
require 'time'
byebug
OptimumTrello.create_card(Time.now.iso8601, File.read('./logs/2021-03-04T16-29-46.txt'))
