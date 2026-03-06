class MatchSummaryService
  GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
  MODEL        = "llama-3.3-70b-versatile"

  def self.generate(match)
    return match.summary if match.summary.present?
    return nil unless match.finished? && match.home_score.present?

    prompt = build_prompt(match)

    response = Faraday.post(GROQ_API_URL) do |req|
      req.headers["Authorization"] = "Bearer #{ENV['GROQ_API_KEY']}"
      req.headers["Content-Type"]  = "application/json"
      req.body = {
        model:       MODEL,
        messages:    [{ role: "user", content: prompt }],
        max_tokens:  250,
        temperature: 0.6
      }.to_json
    end

    return nil unless response.success?

    summary = JSON.parse(response.body).dig("choices", 0, "message", "content")&.strip
    match.update_column(:summary, summary) if summary.present?
    summary

  rescue => e
    Rails.logger.error("[MatchSummaryService] Erreur pour match #{match.id}: #{e.message}")
    nil
  end

  def self.generate_batch(matches)
    matches.each do |match|
      generate(match)
      sleep 0.5 # respecter le rate limit Groq (30 req/min free tier)
    end
  end

  private

  def self.build_prompt(match)
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
end
