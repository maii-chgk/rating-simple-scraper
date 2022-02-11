class TournamentsAPI
  include HTTParty
  base_uri 'https://api.rating.chgk.net/tournaments?'
  ITEMS_PER_PAGE = 100

  def initialize
    @headers = { accept: 'application/json' }
  end

  def all(page:)
    fetch("page=#{page}")
  end

  def maii_tournaments(page:)
    fetch("properties.maiiRating=true&page=#{page}")
  end

  def tournaments_started_after(date:, page:)
    fetch("dateStart%5Bafter%5D=#{date}&page=#{page}")
  end

  def tournaments_updated_after(date:, page:)
    fetch("lastEditDate%5Bafter%5D=#{date}&page=#{page}")
  end

  private

  def fetch(query)
    self.class.get("#{query}&itemsPerPage=#{ITEMS_PER_PAGE}", headers: @headers).parsed_response
  rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
    puts "connection refused at #{query}, retrying in 3 seconds"
    sleep(3)
    retry
  end
end
