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
    "Torino"               => "Torino (Turin)",
    "Bologna"              => "Bologne",
    "Genoa"                => "Gênes",
    "Fiorentina"           => "Fiorentina (Florence)",
    # Clubs néerlandais
    "Ajax"                 => "Ajax Amsterdam",
    # Clubs grecs
    "AEK Athens FC"        => "AEK Athènes",
    "Olympiakos Piraeus"   => "Olympiakos",
    "Panathinaikos"        => "Panathinaïkos",
    "PAOK"                 => "PAOK Salonique",
    "Aris Thessalonikis"   => "Aris Thessalonique",
    # Clubs écossais
    "Celtic"               => "Celtic Glasgow",
    "Rangers"              => "Rangers Glasgow",
    # Clubs portugais
    "Sporting CP"          => "Sporting Lisbonne",
    "SC Braga"             => "Braga",
    # Clubs belges
    "Club Brugge KV"       => "Club Bruges",
    "Union St. Gilloise"   => "Union Saint-Gilloise",
    "Anderlecht"           => "RSC Anderlecht",
    # Clubs néerlandais compléments
    "PSV Eindhoven"        => "PSV",
    "Feyenoord"            => "Feyenoord Rotterdam",
    "AZ Alkmaar"           => "AZ",
    # Clubs croates / est-européens
    "Dinamo Zagreb"        => "Dinamo Zagreb",
    "HNK Hajduk Split"     => "Hajduk Split",
    # Clubs turcs
    "Beşiktaş"             => "Besiktas",
    "Başakşehir"           => "Istanbul Basaksehir",
    "Göztepe"              => "Göztepe",
  }.freeze

  # Affiche le nom français d'une équipe :
  # clubs connus → TEAM_NAME_OVERRIDES, équipes nationales → COUNTRY_FR, autres → inchangé
  def team_display_name(name)
    result = TEAM_NAME_OVERRIDES[name] ||
             NATIONAL_TEAM_OVERRIDES[name] ||
             COUNTRY_FR[name] ||
             name
    # Remplace le suffixe anglais " W" (Women) par " F" (Féminin)
    result.sub(/ W$/, ' F')
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
    "atalanta"             => "bergame la dea atalante",
    "napoli"               => "ssc naples",
    "fiorentina"           => "la viola florence fiorentina",
    "torino"               => "turin granata",
    "bologna"              => "bologne fc bologne",
    "genoa"                => "genes gênes fc genes",
    "udinese"              => "udine",
    "cagliari"             => "sardaigne",
    "lecce"                => "giallorossi salento",
    "como"                 => "como 1907",
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
    # Clubs grecs
    "aek-athens-fc"        => "aek athenes grece",
    "olympiakos-piraeus"   => "olympiakos le piree",
    "panathinaikos"        => "pao athenes",
    "paok"                 => "salonique thessalonique",
    "aris-thessalonikis"   => "aris thessalonique",
    # Clubs écossais
    "celtic"               => "celtic glasgow",
    "rangers"              => "rangers glasgow ibrox",
    "aberdeen"             => "dons",
    "hibernian"            => "hibs edinburgh",
    # Clubs belges
    "club-brugge-kv"       => "bruges club de bruges",
    "anderlecht"           => "rsc anderlecht bruxelles",
    "union-st-gilloise"    => "union saint-gilloise bruxelles",
    "genk"                 => "racing genk",
    # Clubs portugais (entrées uniques — ne pas dupliquer avec la section précédente)
    "guimaraes"            => "vitoria guimaraes",
    "rio-ave"              => "rio ave fc",
    "famalicao"            => "famalicao fc",
    # Clubs suisses / autrichiens
    "bsc-young-boys"       => "young boys berne ybe",
    "fc-basel-1893"        => "bale fc bale",
    "red-bull-salzburg"    => "salzburg rbs autriche",
    # Clubs turcs
    "galatasaray"          => "cim bom istanbul",
    "fenerbahce"           => "fener istanbul sarı kanaryalar",
    "besiktas"             => "besiktas kartallar istanbul",
    "trabzonspor"          => "trabzon",
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
    "scotland"             => "ecosse highlanders",
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
    "austria"              => "autriche wunderteam",
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
  }.freeze

  def team_search_aliases(slug)
    TEAM_SEARCH_ALIASES[slug] || ""
  end

  MONTHS_FR = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre].freeze

  # Mapping chaîne TV → slug /chaines/:slug
  CHANNEL_SLUG_MAP = {
    "canal+"                    => "canal-plus",
    "canal+ sport"              => "canal-plus",
    "canal+ live"               => "canal-plus",
    "canal+ décalé"             => "canal-plus",
    "canal+ foot"               => "canal-plus",
    "bein sports"               => "bein-sports",
    "bein sports 1"             => "bein-sports",
    "bein sports 2"             => "bein-sports",
    "bein sports 3"             => "bein-sports",
    "dazn"                      => "dazn",
    "dazn 1"                    => "dazn",
    "dazn 2"                    => "dazn",
    "dazn 3"                    => "dazn",
    "amazon prime"              => "amazon-prime",
    "amazon prime video"        => "amazon-prime",
    "amazon prime video sport"  => "amazon-prime",
    "rmc sport"                 => "rmc-sport",
    "rmc sport 1"               => "rmc-sport",
    "rmc sport 2"               => "rmc-sport",
    "france 2"                  => "france-tv",
    "france 3"                  => "france-tv",
    "france 4"                  => "france-tv",
    "france tv"                 => "france-tv",
    "francetv sport"            => "france-tv",
    "tf1"                       => "tf1",
    "m6"                        => "m6",
  }.freeze

  def channel_slug_for(channel_name)
    CHANNEL_SLUG_MAP[channel_name.downcase.strip]
  end

  # Cards blog contextuelles pour une page match
  # Retourne un Array de { path:, label:, image:, excerpt: }
  BLOG_CARDS_META = {
    "ligue-1-chaine-tv-2026" => {
      label: "Ligue 1 à la TV : sur quelle chaîne ?",
      image: "https://images.unsplash.com/photo-1642171729073-303524bbfb31",
      excerpt: "Ligue 1+ et beIN Sports se partagent les droits TV de la Ligue 1."
    },
    "champions-league-chaine-tv-france" => {
      label: "Champions League : quelle chaîne TV ?",
      image: "https://images.pexels.com/photos/34625036/pexels-photo-34625036.jpeg",
      excerpt: "Canal+ diffuse toute la Ligue des Champions en France."
    },
    "ou-regarder-premier-league-france" => {
      label: "Où regarder la Premier League en France ?",
      image: "https://images.unsplash.com/photo-1665413813191-3143ec934960",
      excerpt: "La Premier League passe exclusivement sur Canal+ jusqu'en 2028."
    },
    "ou-regarder-serie-a-france" => {
      label: "Où regarder la Serie A en France ?",
      image: "https://images.unsplash.com/photo-1629368858587-7ebd70d20946",
      excerpt: "DAZN diffuse tous les matchs de Serie A en 2025-2026."
    },
    "ou-regarder-liga-france" => {
      label: "Où regarder la Liga en France ?",
      image: "https://images.unsplash.com/photo-1769348193442-6d3b1655266d",
      excerpt: "La Liga passe sur beIN Sports en France."
    },
    "bundesliga-chaine-tv-france" => {
      label: "Bundesliga à la TV en France",
      image: "https://images.unsplash.com/photo-1634467599303-d123a536e7fe",
      excerpt: "DAZN détient l'exclusivité de la Bundesliga en France."
    },
    "europa-league-chaine-tv-france" => {
      label: "Europa League : Canal+ ou beIN Sports ?",
      image: "https://images.pexels.com/photos/35781789/pexels-photo-35781789.jpeg",
      excerpt: "Canal+ détient l'intégralité des droits de la Ligue Europa."
    },
    "conference-league-chaine-tv-2026" => {
      label: "Conference League : date et chaîne TV",
      image: "https://images.unsplash.com/photo-1675848758961-e25a8d08e374",
      excerpt: "La Conference League 2025-2026 se regarde sur Canal+."
    },
    "match-psg-ce-soir-chaine" => {
      label: "Match du PSG : chaîne et horaire",
      image: "https://images.unsplash.com/photo-1753188558508-288762d742a6",
      excerpt: "Prochain match du PSG : l'heure et la chaîne TV."
    },
    "prochain-match-om-diffusion" => {
      label: "Prochain match de l'OM : chaîne et horaire",
      image: "https://images.pexels.com/photos/1884574/pexels-photo-1884574.jpeg",
      excerpt: "Prochain match de l'OM : l'heure et la chaîne TV."
    },
    "abonnement-foot-2026-quelle-chaine-choisir" => {
      label: "Le guide complet des abonnements foot 2026",
      image: "https://images.unsplash.com/photo-1522778119026-d647f0596c20",
      excerpt: "Canal+, DAZN, beIN Sports : on a tout comparé pour vous."
    },
  }.freeze

  def match_blog_links(match)
    slugs = []
    comp = match.competition.to_s
    teams = [match.home_team.to_s, match.away_team.to_s]

    # Slugs par compétition
    comp_map = {
      "Ligue 1"           => %w[ligue-1-chaine-tv-2026],
      "Champions League"  => %w[champions-league-chaine-tv-france],
      "Premier League"    => %w[ou-regarder-premier-league-france],
      "Serie A"           => %w[ou-regarder-serie-a-france],
      "La Liga"           => %w[ou-regarder-liga-france],
      "Bundesliga"        => %w[bundesliga-chaine-tv-france],
      "Europa League"     => %w[europa-league-chaine-tv-france],
      "Conference League" => %w[conference-league-chaine-tv-2026],
    }
    slugs.concat(comp_map[comp]) if comp_map[comp]

    # Slugs par équipe
    if teams.any? { |t| t.include?("Paris Saint Germain") || t.include?("Paris Saint-Germain") }
      slugs << "match-psg-ce-soir-chaine"
    end
    if teams.any? { |t| t.include?("Marseille") }
      slugs << "prochain-match-om-diffusion"
    end

    # Universel
    slugs << "abonnement-foot-2026-quelle-chaine-choisir"

    slugs.uniq.filter_map do |slug|
      meta = BLOG_CARDS_META[slug]
      next unless meta
      { path: "/blog/#{slug}", label: meta[:label], image: meta[:image], excerpt: meta[:excerpt] }
    end
  end

  # Date en français : 29 mars 2026
  # Optimise les URLs d'images pour réduire le poids (Pexels & Unsplash)
  def optimized_image_url(url, width: 800, height: 200)
    return url if url.blank?
    if url.include?('images.pexels.com')
      base = url.split('?').first
      "#{base}?auto=compress&cs=tinysrgb&w=#{width}&h=#{height}&fit=crop&dpr=1"
    elsif url.include?('images.unsplash.com')
      base = url.split('?').first
      "#{base}?w=#{width}&h=#{height}&q=80&auto=format&fit=crop"
    else
      url
    end
  end

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

  # ── Badges chaînes colorés — design system v2 ───────────────────────────────
  CHANNEL_BADGE_COLORS = {
    'Canal+'          => { bg: '#dc314e', text: '#fff' },
    'Canal+ Foot'     => { bg: '#dc314e', text: '#fff' },
    'Canal+ Live 1'   => { bg: '#dc314e', text: '#fff' },
    'Canal+ Live 2'   => { bg: '#dc314e', text: '#fff' },
    'Canal+ Live 3'   => { bg: '#dc314e', text: '#fff' },
    'Canal+ Live 4'   => { bg: '#dc314e', text: '#fff' },
    'Canal+ Sport'    => { bg: '#dc314e', text: '#fff' },
    'beIN Sports'     => { bg: '#00843D', text: '#fff' },
    'beIN Sports 1'   => { bg: '#00843D', text: '#fff' },
    'beIN Sports 2'   => { bg: '#00843D', text: '#fff' },
    'beIN Sports 3'   => { bg: '#00843D', text: '#fff' },
    'beIN Sports 4'   => { bg: '#00843D', text: '#fff' },
    'beIN Sports 5'   => { bg: '#00843D', text: '#fff' },
    'beIN Sports 7'   => { bg: '#00843D', text: '#fff' },
    'beIN Sports 10'  => { bg: '#00843D', text: '#fff' },
    'DAZN'            => { bg: '#111111', text: '#F4E100', border: '1px solid #F4E100' },
    'Amazon Prime'    => { bg: '#00A8E0', text: '#fff' },
    'TF1'             => { bg: '#003B8E', text: '#fff' },
    'M6'              => { bg: '#FF7A00', text: '#fff' },
    'France TV'       => { bg: '#1A3A6E', text: '#fff' },
    'France 2'        => { bg: '#1A3A6E', text: '#fff' },
    'France 3'        => { bg: '#1A3A6E', text: '#fff' },
    'RMC Sport'       => { bg: '#E5001E', text: '#fff' },
    'RMC Sport 1'     => { bg: '#E5001E', text: '#fff' },
    'Apple TV+'       => { bg: '#1c1c1e', text: '#fff' },
  }.freeze

  CHANNEL_BADGE_LABELS = {
    'Canal+ Foot'    => 'C+ Foot',
    'Canal+ Live 1'  => 'C+ Live 1',
    'Canal+ Live 2'  => 'C+ Live 2',
    'Canal+ Live 3'  => 'C+ Live 3',
    'Canal+ Live 4'  => 'C+ Live 4',
    'Canal+ Sport'   => 'C+ Sport',
    'beIN Sports 1'  => 'beIN 1',
    'beIN Sports 2'  => 'beIN 2',
    'beIN Sports 3'  => 'beIN 3',
    'beIN Sports 4'  => 'beIN 4',
    'beIN Sports 5'  => 'beIN 5',
    'beIN Sports 7'  => 'beIN 7',
    'beIN Sports 10' => 'beIN 10',
    'Amazon Prime'   => 'Prime',
    'France TV'      => 'FranceTV',
  }.freeze

  def channel_badge(channel_name, small: false)
    return ''.html_safe if channel_name.blank?
    channel  = channel_name.to_s.split(',').first.strip
    col      = CHANNEL_BADGE_COLORS[channel] || { bg: '#6b7280', text: '#fff' }
    label    = CHANNEL_BADGE_LABELS[channel] || channel
    padding  = small ? '2px 5px' : '3px 8px'
    fs       = small ? '9px' : '11px'
    style    = "display:inline-flex;align-items:center;background:#{col[:bg]};color:#{col[:text]};"
    style   += "border:#{col[:border]};" if col[:border]
    style   += "border-radius:4px;padding:#{padding};font-size:#{fs};font-weight:700;"
    style   += "font-family:'DM Sans',sans-serif;letter-spacing:0.02em;white-space:nowrap;line-height:1.4;"
    content_tag(:span, label, style: style)
  end

  # --- Orphelinage joueurs thin ---

  def hide_thin_player_links?
    ENV.fetch('HIDE_THIN_PLAYER_LINKS', 'true') == 'true'
  end

  # Décide si un joueur mérite un lien interne.
  # player : objet Player (DB). Si nil, pas de lien.
  # Quand le toggle est off ou le joueur indexable → lien.
  # Sinon → texte brut (le bloc est rendu sans <a>).
  def player_linkable?(player)
    return true unless hide_thin_player_links?
    return false if player.nil?

    player.team_active?
  end
end
