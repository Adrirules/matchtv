module StandingsHelper
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
