namespace :coaches do
  desc "Sync coaches for teams active in the last 30 days or with upcoming matches"
  task sync: :environment do
    unless FootballApiService.within_budget?(:low)
      puts "⛔ coaches:sync ignoré — quota API proche du seuil (priorité basse)"
      next
    end

    api = FootballApiService.new

    team_ids = Match.where(
      "(start_time >= ? AND start_time <= ?) OR start_time > ?",
      30.days.ago, Time.current, Time.current
    ).pluck(:home_team_api_id, :away_team_api_id)
     .flatten.compact.uniq

    # Skip teams synced within the last 7 days — coaches don't change daily
    recent_ids = Coach.where("updated_at >= ?", 7.days.ago).pluck(:team_api_id).to_set
    team_ids   = team_ids.reject { |id| recent_ids.include?(id) }

    puts "Syncing coaches for #{team_ids.size} active teams (skipped #{recent_ids.size} synced < 7 days)..."
    synced = 0
    errors = 0

    team_ids.each_with_index do |team_id, i|
      begin
        data = api.fetch_coach(team_id)
        next unless data.is_a?(Hash) && data['name'].present?

        coach = Coach.find_or_initialize_by(team_api_id: team_id)
        coach.update!(
          name:        data['name'],
          photo:       data['photo'],
          nationality: data['nationality'],
          age:         data['age'],
          career:      data['career'] || []
        )
        synced += 1
      rescue => e
        errors += 1
        Rails.logger.error("Coach sync error for team #{team_id}: #{e.message}")
      end

      sleep 0.5 if (i + 1) % 20 == 0
    end

    puts "Done. #{synced} synced, #{errors} errors."
  end

  desc "Backfill coaches for ALL teams with an api_id (one-time use)"
  task backfill: :environment do
    api = FootballApiService.new

    all_ids = (
      Match.where.not(home_team_api_id: nil).distinct.pluck(:home_team_api_id) +
      Match.where.not(away_team_api_id: nil).distinct.pluck(:away_team_api_id)
    ).uniq

    already_done = Coach.pluck(:team_api_id).to_set
    remaining    = all_ids.reject { |id| already_done.include?(id) }

    puts "#{remaining.size} teams to backfill (#{already_done.size} already in DB)..."
    synced = 0

    remaining.each_with_index do |team_id, i|
      begin
        data = api.fetch_coach(team_id)
        next unless data.is_a?(Hash) && data['name'].present?

        Coach.find_or_create_by!(team_api_id: team_id) do |c|
          c.name        = data['name']
          c.photo       = data['photo']
          c.nationality = data['nationality']
          c.age         = data['age']
          c.career      = data['career'] || []
        end
        synced += 1
      rescue => e
        Rails.logger.error("Backfill error team #{team_id}: #{e.message}")
      end

      sleep 1 if (i + 1) % 10 == 0
      puts "#{i + 1}/#{remaining.size} — #{synced} synced" if (i + 1) % 50 == 0
    end

    puts "Backfill done. #{synced}/#{remaining.size} coaches stored."
  end
end
