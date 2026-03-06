module TeamContentHelper
  def generate_team_intro(team_name, stats, standing)
    return nil unless stats.present?

    played    = stats.dig("fixtures", "played", "total").to_i
    wins      = stats.dig("fixtures", "wins", "total").to_i
    draws     = stats.dig("fixtures", "draws", "total").to_i
    losses    = stats.dig("fixtures", "losses", "total").to_i
    goals_for = stats.dig("goals", "for", "total", "total").to_i
    goals_against = stats.dig("goals", "against", "total", "total").to_i
    league_name = stats.dig("league", "name") || "championnat"
    rank = standing&.dig("rank")

    paragraphs = []

    if rank && played > 0
      paragraphs << "#{team_name} occupe actuellement la #{rank}e place de #{league_name} " \
                    "avec un bilan de #{wins} victoire#{'s' if wins > 1}, #{draws} nul#{'s' if draws > 1} " \
                    "et #{losses} défaite#{'s' if losses > 1} en #{played} matchs disputés cette saison."
    elsif played > 0
      paragraphs << "#{team_name} a disputé #{played} matchs cette saison en #{league_name} " \
                    "pour un bilan de #{wins} victoire#{'s' if wins > 1}, #{draws} nul#{'s' if draws > 1} " \
                    "et #{losses} défaite#{'s' if losses > 1}."
    end

    if goals_for > 0 && played > 0
      avg_scored   = (goals_for.to_f / played).round(1)
      avg_conceded = (goals_against.to_f / played).round(1)
      paragraphs << "Sur le plan offensif, #{team_name} a inscrit #{goals_for} but#{'s' if goals_for > 1} " \
                    "(#{avg_scored} par match en moyenne). Défensivement, l'équipe a encaissé " \
                    "#{goals_against} but#{'s' if goals_against > 1}, soit #{avg_conceded} par rencontre."
    end

    win_rate = played > 0 ? (wins * 100 / played).round : 0
    if win_rate >= 50
      paragraphs << "Avec un taux de victoire de #{win_rate}%, #{team_name} figure parmi les équipes " \
                    "les plus performantes de #{league_name} cette saison."
    elsif wins < losses
      paragraphs << "#{team_name} traverse une période compliquée cette saison en #{league_name}, " \
                    "avec #{losses} défaite#{'s' if losses > 1} à son compteur."
    end

    paragraphs.join(" ").presence
  end
end
