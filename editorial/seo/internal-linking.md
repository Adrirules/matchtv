# internal-linking.md — Règles de maillage interne

> Le maillage interne est le deuxième levier SEO le plus important après le contenu lui-même. Il distribue le PageRank, guide Google dans la compréhension de la structure du site, et augmente le dwell time (pages vues par visite).

---

## Règle fondamentale : 3 liens minimum par article

Chaque article publié doit contenir au minimum :
1. **1 lien vers une page `/chaines/[slug]`** si une chaîne est mentionnée
2. **1 lien vers une page `/competitions/[slug]`** si une compétition est mentionnée
3. **1 lien vers un autre article blog** pertinent

Les liens `/classements/[slug]` et `/equipes/[slug]` sont un bonus à ajouter dès que c'est naturel.

---

## Pages cibles et leurs slugs

### Chaînes TV (`/chaines/`)

| Chaîne | Slug | Quand lier |
|---|---|---|
| Canal+ | `/chaines/canal-plus` | Dès que Canal+ est mentionné (droits LDC, PL, Top 14, F1) |
| beIN Sports | `/chaines/bein-sports` | La Liga, beIN, numéro de chaîne |
| DAZN | `/chaines/dazn` | Ligue 1+, Serie A, Eredivisie, Bundesliga |
| Amazon Prime Video | `/chaines/amazon-prime` | Option Ligue 1+, abonnements alternatifs |
| RMC Sport | `/chaines/rmc-sport` | UFC, NBA, Ligue 1 (saisons précédentes) |
| France TV | `/chaines/france-tv` | Coupe de France, équipe de France, CdM (matchs gratuits) |
| TF1 | `/chaines/tf1` | Equipe de France, CdM 2018/2022 (archives) |
| M6 | `/chaines/m6` | CdM 2026 (54 matchs gratuits), équipe de France |

### Compétitions (`/competitions/`)

| Compétition | Slug | Quand lier |
|---|---|---|
| Ligue 1 | `/competitions/ligue-1` | Toujours quand L1 est mentionnée |
| Ligue 2 | `/competitions/ligue-2` | Foot populaire, montées-relégations |
| Champions League | `/competitions/champions-league` | LDC, C1, Coupes d'Europe |
| Europa League | `/competitions/europa-league` | C3, groupes européens |
| Conference League | `/competitions/conference-league` | C4 |
| Premier League | `/competitions/premier-league` | PL, foot anglais |
| La Liga | `/competitions/la-liga` | Liga, foot espagnol |
| Bundesliga | `/competitions/bundesliga` | Foot allemand |
| Serie A | `/competitions/serie-a` | Foot italien, DAZN |
| Coupe de France | `/competitions/coupe-de-france` | CF, amateurs, France TV |
| Coupe du Monde | `/competitions/coupe-du-monde-2026` | CDM 2026 |
| D1 Féminine | `/competitions/d1-feminine` | Foot féminin |
| National | `/competitions/national` | D3, foot régional |

### Classements (`/classements/`)

| Classement | Slug | Quand lier |
|---|---|---|
| Ligue 1 | `/classements/ligue-1` | Articles OM, PSG, L1 en cours |
| Champions League | `/classements/champions-league` | Articles LDC |
| Premier League | `/classements/premier-league` | Articles PL |
| La Liga | `/classements/la-liga` | Articles La Liga |
| Bundesliga | `/classements/bundesliga` | Articles Bundesliga |
| Serie A | `/classements/serie-a` | Articles Serie A |

### Articles blog publiés (liens croisés)

| Article | Slug | Quand lier |
|---|---|---|
| Guide abonnements foot 2026 | `/blog/abonnement-foot-2026-quelle-chaine-choisir` | Tout article "où regarder", comparatifs |
| Canal+ numéro de chaîne box | `/blog/canal-plus-numero-chaine-box` | Articles Canal+ |
| beIN numéro de chaîne box | `/blog/bein-sports-numero-chaine-box` | Articles beIN |
| Ligue 1 chaîne TV 2026 | `/blog/ligue-1-chaine-tv-2026` | Articles Ligue 1 |
| Champions League chaîne TV | `/blog/champions-league-chaine-tv-france` | Articles LDC |
| Europa League chaîne TV | `/blog/europa-league-chaine-tv-france` | Articles EL |
| Premier League en France | `/blog/ou-regarder-premier-league-france` | Articles PL |
| La Liga en France | `/blog/ou-regarder-liga-france` | Articles La Liga |
| Serie A en France | `/blog/ou-regarder-serie-a-france` | Articles Serie A |
| Bundesliga en France | `/blog/bundesliga-chaine-tv-france` | Articles Bundesliga |
| D1 Féminine chaîne TV | `/blog/d1-feminine-arkema-chaine-tv` | Articles foot féminin |

---

## Règles d'ancrage

### Ancres descriptives (obligatoire)

L'ancre doit décrire la page de destination, pas l'action de cliquer.

| ❌ Interdit | ✅ Correct |
|---|---|
| "clique ici" | "le programme complet de la Ligue 1" |
| "voir ici" | "notre guide des abonnements foot 2026" |
| "en savoir plus" | "le classement de Ligue 1 en direct" |
| "lire la suite" | "la page Canal+ avec tous les matchs diffusés" |
| "Canal+" (seul, sans contexte) | "la page de **Canal+** sur Coup d'Envoi TV" |

### Ancres variées sur le même lien

Si un même lien revient dans plusieurs articles, varier les ancres :
- `/competitions/champions-league` → "la Ligue des Champions", "le programme LDC", "la C1", "les matchs de Champions League"
- `/chaines/canal-plus` → "Canal+", "la page Canal+", "l'offre Canal+", "Canal+ Sport"

### 1 lien par paragraphe max

Pas de paragraphe avec 3 liens. Ça dilue l'UX et le signal PageRank. Si nécessaire, répartir sur l'article.

---

## Maillage selon le type d'article

### Article "Où regarder [championnat]"
Liens obligatoires :
- `/chaines/[chaîne-principale]` — chaîne qui diffuse la compétition
- `/competitions/[compétition]` — la compétition concernée
- `/classements/[compétition]` — si classement disponible
- `/blog/abonnement-foot-2026-quelle-chaine-choisir` — toujours

### Article comparatif abonnements
Liens obligatoires :
- `/chaines/canal-plus`
- `/chaines/dazn`
- `/chaines/bein-sports`
- Au moins 2 articles "où regarder X" déjà publiés

### Article éditorial (hot take, histoire, joueur)
Liens recommandés :
- Pages équipes des clubs mentionnés (`/equipes/[slug]`)
- Pages compétitions concernées
- 1 article blog thématiquement proche

### Article Coupe du Monde
Liens obligatoires :
- `/competitions/coupe-du-monde-2026`
- `/chaines/m6` (matchs gratuits)
- `/chaines/bein-sports` (intégralité)
- `/blog/abonnement-foot-2026-quelle-chaine-choisir`

---

## Fréquence et placement

- **Premier lien** : idéalement dans les 200 premiers mots
- **Dernier lien** : dans la conclusion ou juste avant la FAQ
- **FAQ** : pas de liens dans les réponses FAQ (casse le rendu schema)
- **Spacing** : au moins 150-200 mots entre deux liens
- **Maximum** : 6-8 liens internes par article (au-delà ça sature)

---

## Audit de maillage (à faire tous les 2 mois)

Vérifier que les articles les plus importants reçoivent des liens entrants depuis les nouveaux articles :

| Page cible prioritaire | Liens entrants visés |
|---|---|
| `/blog/abonnement-foot-2026-quelle-chaine-choisir` | Tous les articles "où regarder" |
| `/competitions/ligue-1` | Tous les articles L1 |
| `/competitions/champions-league` | Tous les articles LDC |
| `/chaines/canal-plus` | Articles Canal+, LDC, PL, Top 14 |
| `/chaines/dazn` | Articles Ligue 1, Serie A, Bundesliga |
