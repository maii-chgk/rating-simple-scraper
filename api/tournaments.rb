class TournamentsAPI
  include HTTParty
  base_uri 'https://api.rating.chgk.net/tournaments?'

  def initialize
    @headers = { accept: 'application/json' }
  end

  def maii_tournaments(page:)
    fetch("properties.maiiRating=true&page=#{page}")
  end

  def tournaments_started_after(start_date:, page:)
    self.class.get("properties.maiiRating=true&page=#{page}", headers: @headers).parsed_response
  end

  private

  def fetch(query)
    self.class.get(query, headers: @headers).parsed_response
  end
end
