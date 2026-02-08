class SitemapsController < ApplicationController
  layout false

  def index
    # 1. Les Matchs (les 1000 plus récents/futurs)
    @matches = Match.where("start_time > ?", 30.days.ago)
                    .where.not(slug: [nil, ""])
                    .order(start_time: :desc).limit(1000)

    # 2. Les Équipes (uniques)
    @teams = (Match.distinct.pluck(:home_team) + Match.distinct.pluck(:away_team)).uniq.compact

    # 3. Les Compétitions (Ligues)
    @competitions = Match.distinct.pluck(:competition).compact

    respond_to do |format|
      format.xml
    end
  end
end
