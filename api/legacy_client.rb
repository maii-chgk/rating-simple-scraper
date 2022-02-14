class LegacyAPIClient
  include HTTParty
  base_uri 'https://rating.chgk.info/api/tournaments/'

  def initialize
    @headers = { accept: 'application/json' }
  end

  def fetch_rosters(tournament_id:)
    query = "/#{tournament_id}/recaps"
    fetch(query)
  end

  private

  def fetch(query)
    response = self.class.get(query, headers: @headers)
    if response.code == 200
      response.parsed_response
    else
      nil
    end
  rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
    puts "connection refused at #{query}, retrying in 3 seconds"
    sleep(3)
    retry
  end
end
