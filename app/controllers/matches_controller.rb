class MatchesController < ApplicationController
  def show
    # 1. On essaie d'abord de trouver un Matchup (ancienne logique)
    @matchup = Matchup.find_by(slug: params[:slug])

    if @matchup
      # Si c'est un Matchup, on garde ta logique : on cherche le match le plus proche
      @match = @matchup.matches
                        .where("start_time >= ?", Time.current - 3.hours)
                        .order(:start_time)
                        .first
      @match ||= @matchup.matches.order(start_time: :desc).first
    else
      # 2. Si ce n'est pas un Matchup, c'est peut-être un Match direct (nouveau lien depuis Team)
      @match = Match.find_by(slug: params[:slug]) || Match.find_by(id: params[:slug])

      # Si on a trouvé le match, on récupère son matchup pour la cohérence de la vue
      @matchup = @match&.matchup if @match
    end

    # 3. Ultime sécurité : si vraiment aucun match n'est trouvé
    if @match.nil?
      redirect_to root_path, alert: "Aucune diffusion trouvée pour ce match."
    end
  end
end
