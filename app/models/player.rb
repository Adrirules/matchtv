class Player < ApplicationRecord
  validates :name, :slug, :api_id, presence: true
  validates :slug, uniqueness: true
  validates :api_id, uniqueness: true

  def self.find_by_slug(slug)
    find_by(slug: slug)
  end

  # Source de vérité unique pour savoir si la page joueur doit être indexée.
  # Utilisé par PlayersController (@noindex) ET par le helper player_link_or_text.
  #
  # Paramètres optionnels : les données API ne sont pas en DB, elles sont passées
  # par le controller qui les a déjà fetchées (évite un double appel API).
  def indexable?(games: 0, is_friendly: false, has_upcoming: false, has_bio: false)
    team_active = team_api_id.present? &&
      Match.where(
        "(home_team_api_id = ? OR away_team_api_id = ?) AND start_time > ?",
        team_api_id, team_api_id, 30.days.ago
      ).exists?

    return false unless team_active
    return false if games.to_i == 0 && !has_upcoming
    return false if is_friendly && !has_upcoming
    return false if games.to_i < 10 && !has_upcoming && !has_bio

    true
  end

  # Version légère pour les vues (pas d'appel API, juste l'activité de l'équipe).
  # Un joueur dont l'équipe est inactive n'est jamais indexable, quel que soit le reste.
  # Pour les joueurs d'équipes actives, on présume indexable (lien affiché).
  def team_active?
    return false if team_api_id.blank?

    Rails.cache.fetch("team_active_#{team_api_id}", expires_in: 1.hour) do
      Match.where(
        "(home_team_api_id = ? OR away_team_api_id = ?) AND start_time > ?",
        team_api_id, team_api_id, 30.days.ago
      ).exists?
    end
  end
end
