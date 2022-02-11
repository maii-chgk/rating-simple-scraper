require_relative 'selectors'
require_relative '../../tournament/rosters'

TournamentRostersFetcher.new(ids: maii_tournaments).run
