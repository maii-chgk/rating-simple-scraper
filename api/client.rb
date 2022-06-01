class APIClient
  include HTTParty
  base_uri 'https://api.rating.chgk.net'
  ITEMS_PER_PAGE = 100

  def initialize
    @headers = { accept: 'application/json' }
  end

  def all_tournaments(page:)
    paged_fetch("/tournaments?", page)
  end

  def maii_tournaments(page:)
    paged_fetch("/tournaments?properties.maiiRating=true", page)
  end

  def tournaments_started_after(date:, page:)
    paged_fetch("/tournaments?dateStart%5Bafter%5D=#{date}", page)
  end

  def tournaments_updated_after(date:, page:)
    paged_fetch("/tournaments?lastEditDate%5Bafter%5D=#{date}", page)
  end

  def tournament_results(tournament_id:)
    fetch("/tournaments/#{tournament_id}/results?includeTeamMembers=0&includeMasksAndControversials=0&includeTeamFlags=0&includeRatingB=0")
  end

  def tournament_rosters(tournament_id:)
    fetch("/tournaments/#{tournament_id}/results?includeTeamMembers=1&includeMasksAndControversials=0&includeTeamFlags=1&includeRatingB=0")
  end

  def team_rosters(team_id:)
    fetch("/teams/#{team_id}/seasons")
  end

  def towns(page:)
    paged_fetch("/towns?", page)
  end

  def teams(page:)
    fetch("/teams?page=#{page}&itemsPerPage=500")
  end

  def players(page:)
    fetch("/players?page=#{page}&itemsPerPage=500")
  end

  def seasons
    fetch("/seasons")
  end

  private

  def paged_fetch(query, page)
    fetch("#{query}&itemsPerPage=#{ITEMS_PER_PAGE}&page=#{page}")
  end

  def fetch(query)
    self.class.get("#{query}", headers: @headers).parsed_response
  rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT
    puts "connection refused at #{query}, retrying in 3 seconds"
    sleep(3)
    retry
  end
end