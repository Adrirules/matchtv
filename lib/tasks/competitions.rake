namespace :competitions do
  desc "Génère les descriptions éditoriales des pages compétition via Groq (one-shot, idempotent)"
  task generate_descriptions: :environment do
    require "yaml"
    require "faraday"

    yaml_path = Rails.root.join("config", "competition_descriptions.yml")
    descriptions = File.exist?(yaml_path) ? YAML.load_file(yaml_path) || {} : {}

    competitions = FootballApiService::COMPETITIONS_META.uniq { |c| c[:name] }
    to_generate  = competitions.reject { |c| descriptions[c[:name]].present? }

    if to_generate.empty?
      puts "✅ Toutes les descriptions sont déjà générées (#{descriptions.count} compétitions)."
      next
    end

    puts "🤖 #{to_generate.count} compétition(s) à décrire (#{descriptions.count} déjà faites)..."

    to_generate.each_with_index do |comp, i|
      prompt = <<~PROMPT
        Écris une description éditoriale de la compétition de football "#{comp[:name]}" pour un site français.
        3 paragraphes courts (environ 80 mots chacun), sans titre, sans liste, sans markdown.
        Ton journalistique, naturel, comme rédigé par un fan de foot passionné.

        Paragraphe 1 : présentation (format, nombre d'équipes, histoire, prestige)
        Paragraphe 2 : droits TV en France pour 2025-2026 (quelle chaîne, comment regarder)
        Paragraphe 3 : enjeux de la saison 2025-2026 (favoris, lutte pour le titre ou maintien)

        N'invente pas de résultats précis ni de scores. Reste factuel sur le format, général sur les enjeux.
        Commence directement par le premier paragraphe, sans introduction.
      PROMPT

      response = Faraday.post("https://api.groq.com/openai/v1/chat/completions") do |req|
        req.headers["Authorization"] = "Bearer #{ENV['GROQ_API_KEY']}"
        req.headers["Content-Type"]  = "application/json"
        req.body = {
          model:       "llama-3.3-70b-versatile",
          messages:    [{ role: "user", content: prompt }],
          max_tokens:  450,
          temperature: 0.7
        }.to_json
      end

      unless response.success?
        body = response.body
        puts "  💥 HTTP #{response.status} pour #{comp[:name]}: #{body[0..200]}"
        if response.status == 429 && body.include?("tokens per day")
          puts "  🛑 Quota journalier Groq atteint. Relance demain avec la même commande."
          File.write(yaml_path, descriptions.to_yaml)
          puts "  💾 Progression sauvegardée (#{descriptions.count}/#{competitions.count})."
          exit 0
        end
        puts "  ⚠️  Échec ignoré pour #{comp[:name]}, on continue..."
        sleep 4
        next
      end

      text = JSON.parse(response.body).dig("choices", 0, "message", "content")&.strip

      if text.present?
        descriptions[comp[:name]] = text
        File.write(yaml_path, descriptions.to_yaml)
        puts "  ✅ [#{i + 1}/#{to_generate.count}] #{comp[:name]}"
      else
        puts "  ⚠️  Réponse vide pour #{comp[:name]}"
      end

      sleep 4
    end

    puts "🎉 #{descriptions.count}/#{competitions.count} compétitions décrites."
    puts "💾 Fichier : config/competition_descriptions.yml"
  end
end
