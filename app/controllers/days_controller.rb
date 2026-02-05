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

    # Sécurité : jamais dans le passé
    @date = today if @date < today

    # Fenêtre fixe de 7 jours
    @days = (0..6).map { |i| today + i.days }

    # Matchs pour le jour sélectionné
    scope = Match.where(start_time: @date.all_day)

    # Si c'est aujourd'hui, on ne montre que ceux qui n'ont pas encore commencé (ou pas fini)
    if @date == today
      scope = scope.where("start_time >= ?", Time.current - 2.hours) # -2h pour garder le match affiché pendant qu'il joue
    end

    @matches = scope.order(:start_time)
  end
end
