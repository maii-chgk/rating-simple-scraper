require_relative '../fetchers/tournament/rosters'

TournamentRostersFetcher.new(ids: maii_tournaments).run
