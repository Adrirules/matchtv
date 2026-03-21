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

  # "Belgium" → "belge"  (pour "De nationalité belge")
  def nationality_fr(nat)
    NATIONALITY_ADJECTIVES[nat] || nat
  end

  # "Belgium" → "Belgique"  (pour "né à Liège (Belgique)")
  def country_fr(nat)
    COUNTRY_FR[nat] || nat
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
