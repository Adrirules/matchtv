module ApplicationHelper
  DAY_LABELS = { 0 => "Dim.", 1 => "Lun.", 2 => "Mar.", 3 => "Mer.", 4 => "Jeu.", 5 => "Ven.", 6 => "Sam." }.freeze

  # Traduit les nationalités anglaises de l'API en français
  # Forme adjectivale : nationality_fr("Belgium") → "belge"
  # Forme pays       : country_fr("Belgium")      → "Belgique"
  NATIONALITY_ADJECTIVES = {
    "Afghanistan" => "afghan", "Albania" => "albanais", "Algeria" => "algérien",
    "Angola" => "angolais", "Argentina" => "argentin", "Armenia" => "arménien",
    "Australia" => "australien", "Austria" => "autrichien", "Azerbaijan" => "azerbaïdjanais",
    "Bahrain" => "bahreïni", "Belarus" => "biélorusse", "Belgium" => "belge",
    "Benin" => "béninois", "Bolivia" => "bolivien", "Bosnia and Herzegovina" => "bosnien",
    "Botswana" => "botswanais", "Brazil" => "brésilien", "Bulgaria" => "bulgare",
    "Burkina Faso" => "burkinabé", "Burundi" => "burundais", "Cameroon" => "camerounais",
    "Canada" => "canadien", "Cape Verde" => "cap-verdien", "Chile" => "chilien",
    "China" => "chinois", "Colombia" => "colombien", "Congo" => "congolais",
    "Congo DR" => "congolais (RDC)", "Costa Rica" => "costaricien", "Croatia" => "croate",
    "Cuba" => "cubain", "Czech Republic" => "tchèque", "Czechia" => "tchèque",
    "Denmark" => "danois", "Dominican Republic" => "dominicain", "Ecuador" => "équatorien",
    "Egypt" => "égyptien", "El Salvador" => "salvadorien", "England" => "anglais",
    "Equatorial Guinea" => "équato-guinéen", "Estonia" => "estonien", "Ethiopia" => "éthiopien",
    "Finland" => "finlandais", "France" => "français", "Gabon" => "gabonais",
    "Gambia" => "gambien", "Georgia" => "géorgien", "Germany" => "allemand",
    "Ghana" => "ghanéen", "Greece" => "grec", "Guinea" => "guinéen",
    "Guinea-Bissau" => "bissau-guinéen", "Honduras" => "hondurien", "Hungary" => "hongrois",
    "Iceland" => "islandais", "Iran" => "iranien", "Iraq" => "irakien",
    "Ireland" => "irlandais", "Israel" => "israélien", "Italy" => "italien",
    "Ivory Coast" => "ivoirien", "Jamaica" => "jamaïcain", "Japan" => "japonais",
    "Jordan" => "jordanien", "Kazakhstan" => "kazakhstanais", "Kenya" => "kényan",
    "Kosovo" => "kosovar", "Kuwait" => "koweïtien", "Latvia" => "letton",
    "Lebanon" => "libanais", "Liberia" => "libérien", "Libya" => "libyen",
    "Lithuania" => "lituanien", "Luxembourg" => "luxembourgeois", "Madagascar" => "malgache",
    "Malawi" => "malawite", "Mali" => "malien", "Malta" => "maltais",
    "Mauritania" => "mauritanien", "Mauritius" => "mauricien", "Mexico" => "mexicain",
    "Moldova" => "moldave", "Montenegro" => "monténégrin", "Morocco" => "marocain",
    "Mozambique" => "mozambicain", "Namibia" => "namibien", "Netherlands" => "néerlandais",
    "New Zealand" => "néo-zélandais", "Nicaragua" => "nicaraguayen", "Niger" => "nigérien",
    "Nigeria" => "nigérian", "Northern Ireland" => "irlandais du Nord", "Norway" => "norvégien",
    "Paraguay" => "paraguayen", "Panama" => "panaméen", "Peru" => "péruvien",
    "Poland" => "polonais", "Portugal" => "portugais", "Romania" => "roumain",
    "Russia" => "russe", "Rwanda" => "rwandais", "Saudi Arabia" => "saoudien",
    "Scotland" => "écossais", "Senegal" => "sénégalais", "Serbia" => "serbe",
    "Sierra Leone" => "sierra-léonais", "Slovakia" => "slovaque", "Slovenia" => "slovène",
    "Somalia" => "somalien", "South Africa" => "sud-africain", "South Korea" => "sud-coréen",
    "South Sudan" => "sud-soudanais", "Spain" => "espagnol", "Sudan" => "soudanais",
    "Sweden" => "suédois", "Switzerland" => "suisse", "Syria" => "syrien",
    "Tanzania" => "tanzanien", "Togo" => "togolais", "Trinidad and Tobago" => "trinidadien",
    "Tunisia" => "tunisien", "Turkey" => "turc", "Uganda" => "ougandais",
    "Ukraine" => "ukrainien", "United Arab Emirates" => "émirati", "Uruguay" => "uruguayen",
    "USA" => "américain", "United States" => "américain", "Uzbekistan" => "ouzbek",
    "Venezuela" => "vénézuélien", "Wales" => "gallois", "Zambia" => "zambien",
    "Zimbabwe" => "zimbabwéen"
  }.freeze

  COUNTRY_FR = {
    "Afghanistan" => "Afghanistan", "Albania" => "Albanie", "Algeria" => "Algérie",
    "Angola" => "Angola", "Argentina" => "Argentine", "Armenia" => "Arménie",
    "Australia" => "Australie", "Austria" => "Autriche", "Azerbaijan" => "Azerbaïdjan",
    "Bahrain" => "Bahreïn", "Belarus" => "Biélorussie", "Belgium" => "Belgique",
    "Benin" => "Bénin", "Bolivia" => "Bolivie", "Bosnia and Herzegovina" => "Bosnie-Herzégovine",
    "Botswana" => "Botswana", "Brazil" => "Brésil", "Bulgaria" => "Bulgarie",
    "Burkina Faso" => "Burkina Faso", "Burundi" => "Burundi", "Cameroon" => "Cameroun",
    "Canada" => "Canada", "Cape Verde" => "Cap-Vert", "Chile" => "Chili",
    "China" => "Chine", "Colombia" => "Colombie", "Congo" => "Congo",
    "Congo DR" => "RD Congo", "Costa Rica" => "Costa Rica", "Croatia" => "Croatie",
    "Cuba" => "Cuba", "Czech Republic" => "Tchéquie", "Czechia" => "Tchéquie",
    "Denmark" => "Danemark", "Dominican Republic" => "République dominicaine", "Ecuador" => "Équateur",
    "Egypt" => "Égypte", "El Salvador" => "Salvador", "England" => "Angleterre",
    "Equatorial Guinea" => "Guinée équatoriale", "Estonia" => "Estonie", "Ethiopia" => "Éthiopie",
    "Finland" => "Finlande", "France" => "France", "Gabon" => "Gabon",
    "Gambia" => "Gambie", "Georgia" => "Géorgie", "Germany" => "Allemagne",
    "Ghana" => "Ghana", "Greece" => "Grèce", "Guinea" => "Guinée",
    "Guinea-Bissau" => "Guinée-Bissau", "Honduras" => "Honduras", "Hungary" => "Hongrie",
    "Iceland" => "Islande", "Iran" => "Iran", "Iraq" => "Irak",
    "Ireland" => "Irlande", "Israel" => "Israël", "Italy" => "Italie",
    "Ivory Coast" => "Côte d'Ivoire", "Jamaica" => "Jamaïque", "Japan" => "Japon",
    "Jordan" => "Jordanie", "Kazakhstan" => "Kazakhstan", "Kenya" => "Kenya",
    "Kosovo" => "Kosovo", "Kuwait" => "Koweït", "Latvia" => "Lettonie",
    "Lebanon" => "Liban", "Liberia" => "Libéria", "Libya" => "Libye",
    "Lithuania" => "Lituanie", "Luxembourg" => "Luxembourg", "Madagascar" => "Madagascar",
    "Malawi" => "Malawi", "Mali" => "Mali", "Malta" => "Malte",
    "Mauritania" => "Mauritanie", "Mauritius" => "Maurice", "Mexico" => "Mexique",
    "Moldova" => "Moldavie", "Montenegro" => "Monténégro", "Morocco" => "Maroc",
    "Mozambique" => "Mozambique", "Namibia" => "Namibie", "Netherlands" => "Pays-Bas",
    "New Zealand" => "Nouvelle-Zélande", "Nicaragua" => "Nicaragua", "Niger" => "Niger",
    "Nigeria" => "Nigéria", "Northern Ireland" => "Irlande du Nord", "Norway" => "Norvège",
    "Paraguay" => "Paraguay", "Panama" => "Panama", "Peru" => "Pérou",
    "Poland" => "Pologne", "Portugal" => "Portugal", "Romania" => "Roumanie",
    "Russia" => "Russie", "Rwanda" => "Rwanda", "Saudi Arabia" => "Arabie saoudite",
    "Scotland" => "Écosse", "Senegal" => "Sénégal", "Serbia" => "Serbie",
    "Sierra Leone" => "Sierra Leone", "Slovakia" => "Slovaquie", "Slovenia" => "Slovénie",
    "Somalia" => "Somalie", "South Africa" => "Afrique du Sud", "South Korea" => "Corée du Sud",
    "South Sudan" => "Soudan du Sud", "Spain" => "Espagne", "Sudan" => "Soudan",
    "Sweden" => "Suède", "Switzerland" => "Suisse", "Syria" => "Syrie",
    "Tanzania" => "Tanzanie", "Togo" => "Togo", "Trinidad and Tobago" => "Trinité-et-Tobago",
    "Tunisia" => "Tunisie", "Turkey" => "Turquie", "Uganda" => "Ouganda",
    "Ukraine" => "Ukraine", "United Arab Emirates" => "Émirats arabes unis", "Uruguay" => "Uruguay",
    "USA" => "États-Unis", "United States" => "États-Unis", "Uzbekistan" => "Ouzbékistan",
    "Venezuela" => "Venezuela", "Wales" => "Pays de Galles", "Zambia" => "Zambie",
    "Zimbabwe" => "Zimbabwe"
  }.freeze

  # "Belgium" → "belge"  (pour "il est belge" — forme masculine)
  def nationality_fr(nat)
    NATIONALITY_ADJECTIVES[nat] || nat
  end

  # "Belgium" → "belge"  (pour "de nationalité belge" — forme féminine accordée avec "nationalité")
  NATIONALITY_ADJ_F_EXCEPTIONS = {
    "Turkey" => "turque",
    "Greece" => "grecque",
  }.freeze

  def nationality_fr_feminine(nat)
    return NATIONALITY_ADJ_F_EXCEPTIONS[nat] if NATIONALITY_ADJ_F_EXCEPTIONS.key?(nat)
    adj = NATIONALITY_ADJECTIVES[nat] || nat
    return adj if adj.end_with?('e')
    return adj.sub(/éen$/, 'éenne') if adj.end_with?('éen')  # sud-coréen→sud-coréenne
    return adj.sub(/ien$/, 'ienne') if adj.end_with?('ien')  # brésilien→brésilienne
    return adj.sub(/ois$/, 'oise')  if adj.end_with?('ois')  # danois→danoise
    return adj.sub(/ain$/, 'aine')  if adj.end_with?('ain')  # américain→américaine
    return adj.sub(/ais$/, 'aise')  if adj.end_with?('ais')  # français→française
    adj + 'e'                                                  # allemand→allemande, etc.
  end

  # "WDLWD" → "2 victoires, 1 nul et 2 défaites"
  def form_to_text(form)
    return nil if form.blank?
    v = form.count("W")
    n = form.count("D")
    d = form.count("L")
    parts = []
    parts << "#{v} victoire#{'s' if v > 1}" if v > 0
    parts << "#{n} nul#{'s' if n > 1}" if n > 0
    parts << "#{d} défaite#{'s' if d > 1}" if d > 0
    return nil if parts.empty?
    parts.length == 1 ? parts.first : "#{parts[0..-2].join(', ')} et #{parts.last}"
  end

  # "192 cm" ou "192" → "1m92"
  def format_height(h)
    return nil unless h.present?
    cm = h.to_s.scan(/\d+/).first&.to_i
    return nil unless cm && cm > 100
    "#{cm / 100}m#{(cm % 100).to_s.rjust(2, '0')}"
  end

  # "88 kg" ou "88" → "88 kg"
  def format_weight(w)
    return nil unless w.present?
    kg = w.to_s.scan(/\d+/).first
    kg ? "#{kg} kg" : nil
  end

  # "Belgium" → "Belgique"  (pour "né à Liège (Belgique)")
  def country_fr(nat)
    COUNTRY_FR[nat] || nat
  end

  # Équipes nationales avec variantes API non couvertes par COUNTRY_FR
  NATIONAL_TEAM_OVERRIDES = {
    "Bosnia & Herzegovina" => "Bosnie-Herzégovine",
    "Cape Verde Islands"   => "Cap-Vert",
    "Türkiye"              => "Turquie",
    "Congo DR"             => "RD Congo",
    "Ivory Coast"          => "Côte d'Ivoire",
    "South Korea"          => "Corée du Sud",
    "USA"                  => "États-Unis",
    "Czech Republic"       => "Tchéquie",
    "New Zealand"          => "Nouvelle-Zélande",
    "South Africa"         => "Afrique du Sud",
    "Saudi Arabia"         => "Arabie saoudite",
  }.freeze

  # Noms d'affichage français pour les clubs (API renvoie des noms abrégés ou anglais)
  TEAM_NAME_OVERRIDES = {
    # Clubs français
    "Marseille"            => "Olympique de Marseille",
    "Lyon"                 => "Olympique Lyonnais",
    "Paris Saint Germain"  => "Paris Saint-Germain",
    "Saint Etienne"        => "AS Saint-Étienne",
    "Stade Brestois 29"    => "Stade Brestois",
    "RED Star FC 93"       => "Red Star FC",
    # Clubs anglais (noms incomplets)
    "West Ham"             => "West Ham United",
    "Newcastle"            => "Newcastle United",
    "Wolves"               => "Wolverhampton",
    # Clubs espagnols
    "Barcelona"            => "FC Barcelone",
    "Atletico Madrid"      => "Atlético Madrid",
    "Sevilla"              => "Séville",
    "Athletic Club"        => "Athletic Club Bilbao",
    # Clubs allemands
    "Bayern München"       => "Bayern Munich",
    # Clubs italiens
    "Inter"                => "Inter Milan",
    "Napoli"               => "Naples",
    # Clubs néerlandais
    "Ajax"                 => "Ajax Amsterdam",
  }.freeze

  # Affiche le nom français d'une équipe :
  # clubs connus → TEAM_NAME_OVERRIDES, équipes nationales → COUNTRY_FR, autres → inchangé
  def team_display_name(name)
    TEAM_NAME_OVERRIDES[name] ||
      NATIONAL_TEAM_OVERRIDES[name] ||
      COUNTRY_FR[name] ||
      name
  end

  # Aliases de recherche (slug DB réel → termes alternatifs)
  # Les slugs sont dérivés des noms tels qu'ils sont stockés en DB (name.parameterize)
  TEAM_SEARCH_ALIASES = {
    # Clubs français (slugs depuis noms DB courts)
    "paris-saint-germain"  => "psg paris",
    "marseille"            => "om olympique de marseille",
    "lyon"                 => "ol olympique lyonnais",
    "saint-etienne"        => "asse verts",
    "lille"                => "losc",
    "nantes"               => "fcn canaris",
    "rennes"               => "srfc stade rennais",
    "lens"                 => "rcl rc lens",
    "nice"                 => "ogcn ogc nice",
    "monaco"               => "asm as monaco",
    "strasbourg"           => "rcsa rc strasbourg",
    "toulouse"             => "tfc",
    "le-havre"             => "hac havre ac",
    "reims"                => "stade de reims",
    "bordeaux"             => "girondins",
    "ajaccio"              => "ac ajaccio",
    "lorient"              => "fc lorient",
    "metz"                 => "fc metz",
    "montpellier"          => "mhsc",
    "auxerre"              => "aj auxerre",
    "laval"                => "stade lavallois",
    "angers"               => "sco angers",
    "caen"                 => "sm caen",
    # Clubs anglais
    "manchester-city"      => "city man city citizens",
    "manchester-united"    => "united man united manu red devils",
    "tottenham"            => "spurs london londres",
    "chelsea"              => "blues london londres",
    "arsenal"              => "gunners london londres",
    "west-ham"             => "hammers london londres west ham united",
    "liverpool"            => "reds kop",
    "aston-villa"          => "villa",
    "newcastle"            => "newcastle united magpies",
    "everton"              => "toffees",
    "brighton"             => "seagulls",
    "wolves"               => "wolverhampton wanderers",
    "nottingham-forest"    => "forest",
    "leeds"                => "leeds united whites",
    "sunderland"           => "black cats",
    # Clubs espagnols
    "barcelona"            => "barca barça fcb blaugrana barcelone",
    "real-madrid"          => "real merengues blancos",
    "atletico-madrid"      => "atletico atm colchoneros",
    "sevilla"              => "seville fc seville",
    "real-betis"           => "betis",
    "real-sociedad"        => "la real txuri-urdin",
    "celta-vigo"           => "celta",
    "villarreal"           => "sous-marin jaune",
    # Clubs allemands
    "borussia-dortmund"    => "bvb signal iduna",
    "bayer-leverkusen"     => "leverkusen werkself",
    "rb-leipzig"           => "leipzig rbl",
    "bayern-munchen"       => "fcb munchen münchen bavière",
    "eintracht-frankfurt"  => "eintracht",
    "vfb-stuttgart"        => "stuttgart vfb",
    "vfl-wolfsburg"        => "wolfsburg",
    "werder-bremen"        => "werder",
    "borussia-monchengladbach" => "gladbach mönchengladbach",
    "1899-hoffenheim"      => "hoffenheim",
    "sc-freiburg"          => "freiburg",
    "union-berlin"         => "union",
    # Clubs italiens
    "juventus"             => "juve bianconeri",
    "inter"                => "nerazzurri inter milan",
    "ac-milan"             => "milan rossoneri",
    "as-roma"              => "roma giallorossi",
    "lazio"                => "ss lazio biancocelesti",
    "atalanta"             => "bergame la dea",
    "napoli"               => "ssc naples naples",
    "fiorentina"           => "la viola florence",
    "torino"               => "granata",
    "bologna"              => "bologne",
    "genoa"                => "genes gênes",
    # Clubs néerlandais
    "ajax"                 => "ajax amsterdam afc",
    "psv-eindhoven"        => "psv eindhoven",
    "feyenoord"            => "de kuip rotterdam",
    "az-alkmaar"           => "az alkmaar",
    "twente"               => "fc twente enschede",
    # Clubs portugais
    "benfica"              => "sl benfica aguias",
    "fc-porto"             => "porto dragons",
    "sporting-cp"          => "sporting lisbonne",
    "sc-braga"             => "braga",
    # Clubs turcs
    "galatasaray"          => "cim bom",
    "fenerbahce"           => "fener sarı kanaryalar",
    "besiktas"             => "kartallar",
    # Équipes nationales (slug = nom anglais parameterizé)
    "brazil"               => "brésil bresil brasil",
    "england"              => "angleterre",
    "germany"              => "allemagne mannschaft",
    "spain"                => "espagne roja",
    "netherlands"          => "pays-bas hollande",
    "ivory-coast"          => "cote d ivoire ivoiriens",
    "south-korea"          => "coree du sud",
    "usa"                  => "etats-unis amerique",
    "cape-verde-islands"   => "cap-vert",
    "saudi-arabia"         => "arabie saoudite",
    "congo-dr"             => "rdc congo",
    "czech-republic"       => "tcheque tchekie",
    "new-zealand"          => "nouvelle-zelande",
    "south-africa"         => "afrique du sud",
    "bosnia-&-herzegovina" => "bosnie herzegovine",
    "mexico"               => "mexique",
    "argentina"            => "argentine albiceleste",
    "belgium"              => "belgique diables rouges",
    "switzerland"          => "suisse",
    "sweden"               => "suede",
    "norway"               => "norvege",
    "scotland"             => "ecosse",
    "senegal"              => "lion teranga",
    "morocco"              => "maroc lions",
    "egypt"                => "egypte",
    "japan"                => "japon",
    "turkiye"              => "turquie",
    "uruguay"              => "celeste",
    "colombia"             => "colombie",
    "ecuador"              => "equateur",
    "canada"               => "les rouges",
    "ghana"                => "black stars",
    "haiti"                => "grenadiers",
    "iraq"                 => "irak",
    "australia"            => "australie socceroos",
    "austria"              => "autriche",
    "uzbekistan"           => "ouzbekistan",
    "tunisia"              => "tunisie aigles",
    "algeria"              => "algerie fennecs",
    "croatia"              => "croatie",
    "portugal"             => "selecao",
    "poland"               => "pologne",
    "serbia"               => "serbie",
    "romania"              => "roumanie",
    "hungary"              => "hongrie",
    "denmark"              => "danemark",
    "austria"              => "autriche",
    "scotland"             => "ecosse",
  }.freeze

  def team_search_aliases(slug)
    TEAM_SEARCH_ALIASES[slug] || ""
  end

  MONTHS_FR = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre].freeze

  # Date en français : 29 mars 2026
  def date_fr(date)
    return '' unless date
    "#{date.day} #{MONTHS_FR[date.month - 1]} #{date.year}"
  end

  def format_date_label(date)
    today = Date.today
    if date == today         then "aujourd'hui"
    elsif date == today + 1  then "demain"
    elsif date == today - 1  then "hier"
    else l(date, format: "%d %B %Y")
    end
  end
end
