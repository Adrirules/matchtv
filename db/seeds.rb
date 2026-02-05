Match.destroy_all
Matchup.destroy_all

# 1) On crée d'abord les affiches evergreen
om_psg = Matchup.create!(slug: "om-psg")
psg_ol = Matchup.create!(slug: "psg-ol")
real_barca = Matchup.create!(slug: "real-barca")

# 2) On recrée des matchs liés aux affiches
Match.create!(
  matchup: om_psg,
  home_team: "Olympique de Marseille",
  away_team: "Paris Saint-Germain",
  # Time.zone.parse est beaucoup plus robuste en Rails
  start_time: Time.zone.now.change(hour: 21, min: 0),
  tv_channels: "DAZN",
  competition: "Ligue 1"
)

Match.create!(
  matchup: psg_ol,
  home_team: "Paris Saint-Germain",
  away_team: "Olympique Lyonnais",
  start_time: Time.zone.now.tomorrow.change(hour: 20, min: 0),
  tv_channels: "Canal+",
  competition: "Ligue 1"
)

Match.create!(
  matchup: real_barca,
  home_team: "Real Madrid",
  away_team: "FC Barcelone",
  start_time: 2.days.from_now.change(hour: 22, min: 0),
  tv_channels: "BeIN Sports",
  competition: "Liga"
)
