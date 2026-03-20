class PagesController < ApplicationController
  def home
  end

  def contact
  end

  def about
  end

  def legal
  end

  def privacy
  end

  def archives
    # Matchs terminés groupés par jour, triés du plus récent au plus ancien
    days_counts = Match.where(status: %w[FT AET PEN])
                       .group("start_time::date")
                       .order("start_time::date DESC")
                       .count

    # Grouper par mois en Ruby : { "2026-03" => { date => count, ... }, ... }
    @months = days_counts.group_by { |date, _| date.strftime("%Y-%m") }
                         .transform_values(&:to_h)

    @page_title = "Archives des matchs de football — Résultats par date | Coup d'Envoi TV"
    @page_desc  = "Retrouvez tous les résultats et résumés des matchs de football passés, classés par date. Historique complet depuis le lancement de Coup d'Envoi TV."

    expires_in 2.hours, public: true
  end
end
