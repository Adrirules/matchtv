class MatchesController < ApplicationController
  def show
    @matchup = Matchup.find_by!(slug: params[:slug])

    # 1. On cherche d'abord le match le plus proche (futur ou en cours)
    # On retire 3 heures à Time.current pour garder le match affiché pendant sa diffusion
    @match = @matchup.matches
                      .where("start_time >= ?", Time.current - 3.hours)
                      .order(:start_time)
                      .first

    # 2. Sécurité : Si aucun match futur n'existe, on prend le dernier match passé
    # Cela évite l'erreur "nil:NilClass" si tu consultes une ancienne affiche
    @match ||= @matchup.matches.order(start_time: :desc).first

    # 3. Ultime sécurité : si vraiment aucun match n'est lié à ce matchup
    if @match.nil?
      redirect_to root_path, alert: "Aucune diffusion trouvée pour ce match."
    end
  end
end
