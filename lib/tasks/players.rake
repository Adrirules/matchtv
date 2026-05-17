namespace :players do
  desc "Importe les effectifs de toutes les équipes connues"
  task import: :environment do
    unless FootballApiService.within_budget?(:low)
      puts "⛔ players:import ignoré — quota API proche du seuil (priorité basse)"
      next
    end

    api = FootballApiService.new

    # Récupère tous les team_api_ids uniques depuis les matchs
    team_ids = (
      Match.where.not(home_team_api_id: nil).pluck(:home_team_api_id, :home_team, :home_team_logo) +
      Match.where.not(away_team_api_id: nil).pluck(:away_team_api_id, :away_team, :away_team_logo)
    ).uniq { |id, _, _| id }

    puts "🏟️  #{team_ids.count} équipes à traiter..."
    total_players = 0

    team_ids.each_with_index do |(team_api_id, team_name, team_logo), i|
      print "  [#{i+1}/#{team_ids.count}] #{team_name.ljust(25)} "

      # Arrêt si le budget API est dépassé (vérifié équipe par équipe)
      unless FootballApiService.within_budget?(:low)
        puts "\n⛔ Budget API atteint — arrêt à #{i+1}/#{team_ids.count} équipes"
        break
      end

      # Skip si l'effectif a déjà été importé dans les 14 derniers jours
      if Player.where(team_api_id: team_api_id).where('updated_at > ?', 14.days.ago).exists?
        puts "⏭️  (à jour)"
        next
      end

      squad = api.fetch_squad(team_api_id)

      if squad.empty?
        puts "⚠️  Aucun joueur"
        next
      end

      squad.each do |player_data|
        name    = player_data['name']
        next if name.blank?

        base_slug = name.parameterize
        slug = base_slug
        counter = 1

        # Gérer les homonymes (ex: deux joueurs nommés "David")
        while Player.where(slug: slug).where.not(api_id: player_data['id']).exists?
          slug = "#{base_slug}-#{counter}"
          counter += 1
        end

        Player.find_or_initialize_by(api_id: player_data['id']).tap do |p|
          p.name        = name
          p.slug        = slug
          p.team_name   = team_name
          p.team_api_id = team_api_id
          p.team_logo   = team_logo
          p.position    = player_data['position']
          p.nationality = player_data['nationality']
          p.photo       = player_data['photo']
          p.age         = player_data['age']
          p.save!
        end

        total_players += 1
      end

      puts "✅ #{squad.count} joueurs"
      sleep 1 # respecter les quotas API
    end

    puts "\n🎉 #{total_players} joueurs importés au total !"

    # Enchaîne sur les équipes nationales CdM 2026 (TTL 7j, même job scheduler)
    Rake::Task['players:import_national_teams'].invoke
  end

  desc "Importe les effectifs des équipes nationales qualifiées pour la CdM 2026 (FORCE=1 pour bypasser le TTL)"
  task import_national_teams: :environment do
    unless FootballApiService.within_budget?(:low)
      puts "⛔ players:import_national_teams ignoré — quota API proche du seuil"
      next
    end

    api   = FootballApiService.new
    force = ENV['FORCE'] == '1'

    # Toutes les équipes nationales via les matchs CdM 2026
    team_ids = (
      Match.where(competition: "Coupe du Monde 2026").where.not(home_team_api_id: nil)
           .pluck(:home_team_api_id, :home_team, :home_team_logo) +
      Match.where(competition: "Coupe du Monde 2026").where.not(away_team_api_id: nil)
           .pluck(:away_team_api_id, :away_team, :away_team_logo)
    ).uniq { |id, _, _| id }

    if team_ids.empty?
      puts "⚠️  Aucune équipe trouvée pour la CdM 2026 en DB — vérifier que les matchs sont synchés."
      next
    end

    puts "🌍 #{team_ids.count} équipes nationales à traiter#{force ? ' (FORCE)' : ''}..."
    total_players = 0

    team_ids.each_with_index do |(team_api_id, team_name, team_logo), i|
      print "  [#{i+1}/#{team_ids.count}] #{team_name.to_s.ljust(25)} "

      unless FootballApiService.within_budget?(:low)
        puts "\n⛔ Budget API atteint — arrêt à #{i+1}/#{team_ids.count}"
        break
      end

      # TTL 7 jours pour les sélections nationales (sauf FORCE=1)
      if !force && Player.where(team_api_id: team_api_id).where('updated_at > ?', 7.days.ago).exists?
        puts "⏭️  (à jour)"
        next
      end

      squad = api.fetch_squad(team_api_id)

      if squad.empty?
        puts "⚠️  Aucun joueur"
        next
      end

      squad.each do |player_data|
        name = player_data['name']
        next if name.blank?

        base_slug = name.parameterize
        slug      = base_slug
        counter   = 1

        while Player.where(slug: slug).where.not(api_id: player_data['id']).exists?
          slug    = "#{base_slug}-#{counter}"
          counter += 1
        end

        Player.find_or_initialize_by(api_id: player_data['id']).tap do |p|
          p.name        = name
          p.slug        = slug
          p.team_name   = team_name
          p.team_api_id = team_api_id
          p.team_logo   = team_logo
          p.position    = player_data['position']
          p.nationality = player_data['nationality']
          p.photo       = player_data['photo']
          p.age         = player_data['age']
          p.save!
        end

        total_players += 1
      end

      puts "✅ #{squad.count} joueurs"
      sleep 1
    end

    puts "\n🎉 #{total_players} joueurs nationaux importés !"
  end
end
