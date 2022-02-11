require_relative 'selectors'
require_relative '../../tournament/results'

TournamentResultsFetcher.new(ids: maii_tournaments).run
