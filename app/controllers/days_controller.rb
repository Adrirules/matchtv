class DaysController < ApplicationController
  def show
    today = Date.today

    # Date sélectionnée
    @date =
      if params[:date]
        Date.parse(params[:date])
      else
        today
      end

    # Sécurité : jamais dans le passé — redirect 301 pour éviter les conflits de canonical
    if @date < today
      redirect_to day_path(date: today), status: :moved_permanently and return
    end

    # Fenêtre fixe de 7 jours
    @days = (0..6).map { |i| today + i.days }

    # Matchs pour le jour sélectionné
    scope = Match.where(start_time: @date.all_day)

    # Pas de filtre sur l'heure : on affiche tous les matchs du jour (y compris terminés)

    @matches = scope.order(:start_time)
  end
end
