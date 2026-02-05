class SitemapsController < ApplicationController
  layout false

  def index
    @today = Date.today
    @days = (0..6).map { |i| @today + i.days }

    # On utilise "to_a" pour forcer le chargement depuis la BDD immédiatement
    @competitions = Match.distinct.pluck(:competition).compact
    @teams = (Match.distinct.pluck(:home_team) + Match.distinct.pluck(:away_team)).uniq.compact
    @matchups = Matchup.all.to_a

    respond_to do |format|
      format.xml
    end
  end
end
