class MatchSummaryService
  GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
  MODEL        = "llama-3.3-70b-versatile"

  # Compte-rendu pour un match TERMINÉ
  def self.generate(match)
    return match.summary if match.summary.present?
    return nil unless match.finished? && match.home_score.present?

    call_groq(build_summary_prompt(match), match, max_tokens: 250)
  end

  # Avant-match pour un match À VENIR
  def self.generate_preview(match)
    return match.preview if match.preview.present?
    return nil if match.finished?

    call_groq(build_preview_prompt(match), match, max_tokens: 350, field: :preview)
  end

  def self.generate_batch(matches)
    matches.each { |m| generate(m); sleep 2.1 }
  end

  def self.generate_previews_batch(matches)
    matches.each { |m| generate_preview(m); sleep 2.1 }
  end

  private

  def self.call_groq(prompt, match, max_tokens:, field: :summary)
    response = Faraday.post(GROQ_API_URL) do |req|
      req.headers["Authorization"] = "Bearer #{ENV['GROQ_API_KEY']}"
      req.headers["Content-Type"]  = "application/json"
      req.body = {
        model:       MODEL,
        messages:    [{ role: "user", content: prompt }],
        max_tokens:  max_tokens,
        temperature: 0.7
      }.to_json
    end

    unless response.success?
      puts "  💥 HTTP #{response.status} pour match #{match.id}: #{response.body.truncate(300)}"
      Rails.logger.error("[MatchSummaryService] HTTP #{response.status} match #{match.id}: #{response.body}")
      return nil
    end

    text = JSON.parse(response.body).dig("choices", 0, "message", "content")&.strip
    match.update_column(field, text) if text.present?
    text

  rescue => e
    puts "  💥 EXCEPTION #{e.class} pour match #{match.id}: #{e.message}"
    Rails.logger.error("[MatchSummaryService] Erreur match #{match.id}: #{e.message}")
    nil
  end

  def self.build_summary_prompt(match)
    winner = if match.home_score > match.away_score
      "#{match.home_team} s'impose"
    elsif match.away_score > match.home_score
      "#{match.away_team} s'impose"
    else
      "Match nul"
    end

    <<~PROMPT
      Écris un compte-rendu de match de football en français, en 2 à 3 phrases, naturel et factuel.
      Pas de titre, pas de mise en forme, pas d'exagération. Commence directement par le résultat.

      Match : #{match.home_team} #{match.home_score} - #{match.away_score} #{match.away_team}
      Compétition : #{match.competition}
      Résultat : #{winner}
    PROMPT
  end

  def self.build_preview_prompt(match)
    date_fr = match.start_time.strftime("%d/%m/%Y à %Hh%M")

    <<~PROMPT
      Écris une présentation avant-match de football en français, en 3 à 4 phrases, naturelle et informative.
      Pas de titre, pas de liste, pas de mise en forme. Commence directement par une phrase d'accroche sur l'affiche.
      Parle de l'enjeu de la rencontre dans la compétition, du contexte général des deux équipes cette saison.
      N'invente pas de statistiques précises ou de résultats récents que tu ne connais pas avec certitude.

      Match : #{match.home_team} vs #{match.away_team}
      Compétition : #{match.competition}
      Date : #{date_fr}
      Diffusion : #{match.tv_channels}
    PROMPT
  end
end
