module StandingsHelper
  def generate_standings_narrative(standings, league_slug, league_name)
    return nil if standings.blank? || standings.size < 2

    leader        = standings.first
    second        = standings[1]
    leader_name   = leader.dig("team", "name")
    leader_pts    = leader["points"].to_i
    second_pts    = second&.[]("points").to_i
    gap           = leader_pts - second_pts
    played        = leader.dig("all", "played").to_i
    challenger    = second&.dig("team", "name")
    leader_form_text = form_to_text(leader["form"].to_s.last(5))

    # Zone relégation : 3 derniers ou 2 selon config
    bottom = standings.last(3).map { |s| s.dig("team", "name") }

    # Variante stable par ligue (ne change pas entre les rechargements)
    require 'zlib'
    variant = Zlib.crc32(league_name.to_s) % 4

    case variant
    when 0
      leader_str = "<strong>#{leader_name}</strong> domine le classement de #{league_name} avec <strong>#{leader_pts} point#{leader_pts > 1 ? 's' : ''}</strong>"
      leader_str += gap > 0 ? ", #{gap} unité#{gap > 1 ? 's' : ''} d'avance sur <strong>#{challenger}</strong>" : ", à égalité de points avec <strong>#{challenger}</strong>"
      leader_str += " après <strong>#{played} journée#{played > 1 ? 's' : ''}</strong>."
      releg = bottom.any? ? " En bas de tableau, <strong>#{bottom[-2]}</strong> et <strong>#{bottom[-1]}</strong> sont en zone de relégation." : ""
      leader_str + releg

    when 1
      intro = "Après #{played} journée#{played > 1 ? 's' : ''} de #{league_name}, le classement se précise."
      lead  = gap >= 5 ? "<strong>#{leader_name}</strong> a pris le large avec #{leader_pts} pts, son avance devient confortable sur ses concurrents." : "<strong>#{leader_name}</strong> occupe la tête avec #{leader_pts} pts, mais <strong>#{challenger}</strong> reste dans son sillage à #{second_pts} pts."
      releg = bottom.size >= 3 ? " En zone rouge : <strong>#{bottom[0]}</strong>, <strong>#{bottom[1]}</strong> et <strong>#{bottom[2]}</strong> doivent impérativement réagir." : ""
      "#{intro} #{lead}#{releg}"

    when 2
      form_str = leader_form_text.present? ? " #{leader_name} affiche #{leader_form_text} sur ses 5 derniers matchs." : ""
      title_race = gap <= 3 ? "Le titre est encore très ouvert avec seulement #{gap} point#{gap > 1 ? 's' : ''} séparant le leader de son dauphin." : gap >= 8 ? "<strong>#{leader_name}</strong> semble parti pour loin devant." : "La course au titre est lancée, <strong>#{challenger}</strong> reste menaçant."
      "<strong>#{leader_name}</strong> mène #{league_name} avec <strong>#{leader_pts} points</strong> après #{played} journées.#{form_str} #{title_race}"

    else
      duel = gap <= 2 ? "Le duel <strong>#{leader_name}</strong>/<strong>#{challenger}</strong> est serré (#{leader_pts} contre #{second_pts} pts)" : "<strong>#{leader_name}</strong> devance <strong>#{challenger}</strong> (#{leader_pts} pts contre #{second_pts} pts)"
      releg = bottom.any? ? " A l'autre bout, <strong>#{bottom.last}</strong> ferme la marche et cherche à se relancer." : ""
      "#{duel} en tête de #{league_name} après #{played} journées.#{releg}"
    end
  end

  def zone_color(rank, zones)
    return "#1a56db" if zones[:cl]&.include?(rank)
    return "#2563eb" if zones[:cl_q]&.include?(rank)
    return "#f97316" if zones[:el]&.include?(rank)
    return "#10b981" if zones[:conf]&.include?(rank)
    return "#22c55e" if zones[:promo]&.include?(rank)
    return "#84cc16" if zones[:promo_barrage]&.include?(rank)
    return "#f59e0b" if zones[:releg_barrage]&.include?(rank)
    return "#ef4444" if zones[:releg]&.include?(rank)
    nil
  end
end
