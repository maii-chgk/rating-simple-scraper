class TournamentResultsAPI
  include HTTParty
  base_uri 'https://api.rating.chgk.net/tournaments'

  def initialize
    @headers = { accept: 'application/json' }
  end

  def fetch_results(tournament_id:)
    query = "/#{tournament_id}/results?includeTeamMembers=1&includeMasksAndControversials=0&includeTeamFlags=0&includeRatingB=1"
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
