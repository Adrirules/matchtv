# rules.md — Règles SEO non négociables

> Ces règles s'appliquent à chaque article publié sur coupdenvoi.tv. Elles ne sont pas négociables. Chaque exception est un risque pour le compte AdSense et le positionnement Google.

---

## 1. L'intention de recherche prime sur tout

Avant d'écrire une ligne, identifier l'intent :
- **Transactionnel** ("où regarder X", "prix de Y") → réponse directe dans les 2 premières phrases, guide pratique, tableau si pertinent
- **Commercial** ("Canal+ vs DAZN", "meilleure offre foot") → comparatif clair, recommandation assumée, pas de "ça dépend" sans suite
- **Informationnel** ("histoire de la LDC", "comment fonctionne la VAR") → contenu de fond, sources, anecdotes
- **Navigationnel** ("numéro chaîne beIN") → réponse en 1 ligne en tout début d'article, puis contexte

**Règle** : si le lecteur n'a pas sa réponse dans les 30 premières secondes de lecture, l'article a raté son intent.

---

## 2. Structure obligatoire

### Frontmatter Rails (format exact)
```yaml
---
title: "Titre SEO complet | Coup d'Envoi TV"
meta_description: "140-160 caractères, mots-clés naturels, cliquable"
slug: mot-cle-principal-angle-specifique-2026
primary_keyword: "mot-clé principal"
content_type: "guide"  # guide | comparatif | editorial | liste
published_at: "2026-MM-DD"
published_time: "14h37"  # format HHhMM, entre 08h00 et 17h00, minutes aléatoires
author: Adrien
image: "https://images.unsplash.com/photo-XXXXX?w=1200"
image_credit: "Photo : Unsplash / Nom Photographe"
excerpt: "1-2 phrases pour la liste /blog"
# updated_at: "DD mois YYYY"  # optionnel, à ajouter si l'article est mis à jour
---
```

### Structure d'article (ordre à respecter)
1. **Intro avec vécu** — anecdote courte ou accroche directe, 2-3 lignes max
2. **Réponse rapide** — encadré ou section courte, snippet-ready Google/IA
3. **Contenu structuré** — H2 par sous-intention, tableau si pertinent
4. **1 micro-anecdote ou opinion** par section (voir voice.md, stories.md, opinions.md)
5. **FAQ** — 4 à 6 questions réelles People Also Ask, réponses 2-3 lignes
6. **Conclusion** — conseil perso d'Adrien, pas de résumé mécanique
7. **Bannière affiliation** — marker au bon endroit (voir section 9)

---

## 3. Règles H1/H2/H3

- **1 seul H1** par article, contient le mot-clé principal
- **H2** = intentions secondaires réelles, jamais du remplissage
- **H3** = sous-sections des H2, optionnel, seulement si nécessaire
- Ne jamais commencer l'article par le H1 — il y a toujours une intro avant

### Patterns de titres valides (varier impérativement)

Guide/transactionnel :
- "Où regarder [championnat] en France en 2026 ?"
- "[Championnat] : sur quelle chaîne et à quel prix ?"
- "Comment regarder [compétition] sans se ruiner ?"

Comparatif :
- "[A] vs [B] : lequel choisir pour regarder le foot ?"
- "[A] ou [B] : le guide pour choisir ton abonnement foot"

Editorial :
- "La [chose] a changé le foot français (et pas en mieux)"
- "[Joueur] : pourquoi il mérite plus de respect"
- "Le [truc] du foot français que personne ne veut admettre"

Jamais :
- ❌ Curiosity gap racoleur ("Ce que les médias ne te disent pas")
- ❌ "Top X raisons de..."
- ❌ Répéter le même pattern sur 2 articles publiés le même mois

---

## 4. Longueur et densité

| Type d'article | Longueur cible |
|---|---|
| Guide transactionnel | 800-1200 mots |
| Comparatif | 1000-1500 mots |
| Article éditorial | 800-1200 mots |
| Article de fond (histoire, club, joueur) | 1200-2000 mots |

**Règle** : la longueur est un moyen, pas une fin. Un article de 800 mots dense bat un article de 2000 mots avec du remplissage. Si tu n'as plus rien à dire d'utile, tu t'arrêtes.

---

## 5. Mots-clés

- **Mot-clé principal** : dans H1 + intro (naturellement) + conclusion
- **Variations sémantiques** : pas de répétition mécanique — varier ("regarder la Ligue 1", "suivre la L1", "accéder aux matchs de Ligue 1", "chaîne Ligue 1")
- **Entités en gras** : noms de chaînes (**Canal+**, **DAZN**, **beIN Sports**), compétitions (**Ligue 1**, **Champions League**), clubs (**OM**, **PSG**)
- **Densité** : naturelle. Si ça sonne répétitif à la lecture orale, c'est trop dense.

---

## 6. Maillage interne obligatoire (minimum 3 liens)

Chaque article doit lier au minimum :
- 1 lien vers `/chaines/[slug]` si une chaîne TV est mentionnée
- 1 lien vers `/competitions/[slug]` si une compétition est mentionnée
- 1 lien vers `/classements/[slug]` si pertinent
- 1 lien vers un autre article blog pertinent

### Ancres : jamais "clique ici", toujours descriptif
- ✅ "le programme complet de la Ligue 1"
- ✅ "notre guide des abonnements foot 2026"
- ✅ "le classement de Ligue 1 en direct"
- ❌ "clique ici", "voir ici", "en savoir plus"

### Pages cibles prioritaires
```
/chaines/canal-plus       → Canal+
/chaines/bein-sports      → beIN Sports
/chaines/dazn             → DAZN
/chaines/amazon-prime     → Amazon Prime
/chaines/rmc-sport        → RMC Sport
/chaines/france-tv        → France TV
/competitions/ligue-1     → Ligue 1
/competitions/champions-league → LDC
/competitions/premier-league   → PL
/competitions/la-liga          → La Liga
/competitions/serie-a          → Serie A
/competitions/bundesliga       → Bundesliga
/competitions/europa-league    → Europa League
/competitions/ligue-2          → Ligue 2
/classements/ligue-1           → Classement L1
```

---

## 7. FAQ : règles strictes

- **4 à 6 questions** (People Also Ask réels, pas inventés)
- **Réponses courtes** : 2-3 lignes maximum
- **Snippet-ready** : la réponse tient en une phrase si possible
- **Aucun humour dans la FAQ** (voir humour.md - calibrage par type)
- **Pas de lien dans les réponses FAQ** (ça casse le rendu schema)
- **Format JSON-LD FAQPage** dans chaque article (géré par le layout Rails si `schema: true`)

---

## 8. E-E-A-T : signaux obligatoires

- **Auteur nommé** : "Adrien" dans le frontmatter (author: Adrien)
- **Date de publication** visible (gérée automatiquement par le layout)
- **Date de mise à jour** si l'article est actualisé (champ `updated_at`)
- **Stats sourcées** : toujours mentionner la source quand on cite un chiffre ("selon DAZN", "d'après Médiamétrie")
- **Pas de stats inventées** : voir stats.md — règle absolue
- **Pas d'anecdotes inventées** : voir stories.md — règle absolue

---

## 9. Bannières affiliation — markers à placer dans le contenu

Les bannières s'insèrent via des markers dans le Markdown. Le layout Rails les remplace automatiquement par le bon partial.

| Marker | Quand l'utiliser |
|---|---|
| `<!-- CANAL_BANNER -->` | Article sur LDC, Europa, Conference, Premier League, Top 14 |
| `<!-- DAZN_BANNER -->` | Article sur Ligue 1, Serie A, Eredivisie, Bundesliga |
| `<!-- RAT_SPORT_BANNER -->` | Article sur beIN Sports, La Liga, Bundesliga (si pas DAZN) |
| `<!-- CANAL_PLUS_CARD -->` | Encart carte de présentation Canal+ (comparatifs) |
| `<!-- DAZN_CARD -->` | Encart carte de présentation DAZN (comparatifs) |

**Règle de placement** : après le 2ème ou 3ème H2, jamais avant le premier contenu. Jamais dans la FAQ.

**Cohérence éditoriale** : ne pas mettre une bannière DAZN dans un article qui dit que DAZN est mauvais, et vice versa.

---

## 10. Slug : règles strictes

- Minuscules, tirets, sans accents
- **Mot-clé principal EN PREMIER** : `canal-plus-dazn-comparatif-2026`
- Inclure l'année si le contenu est daté
- Pas de mots vides (le, la, les, de, du, pour...) sauf si indispensable
- Max 6-7 mots
- ✅ `ou-regarder-ligue-1-2026`
- ✅ `canal-plus-vs-dazn-lequel-choisir`
- ❌ `article-sur-les-plateformes-de-streaming-pour-regarder-le-football-en-france`

---

## 11. Meta description : règles strictes

- **140-160 caractères** (ni plus, ni moins)
- Contient le mot-clé principal
- Est **cliquable** (donne envie d'aller lire) sans être racoleur
- Répond à la question avant même le clic
- Ne commence jamais par le nom du site
- ✅ "Canal+ diffuse la Ligue des Champions jusqu'en 2031. Voici le prix, les matchs inclus et si ça vaut vraiment le coup en 2026."
- ❌ "Coup d'Envoi TV vous explique tout sur Canal+ et les droits TV du foot français."

---

## 12. Ce qu'on ne fait JAMAIS

- ❌ Publier un article sans avoir lu les 5 fichiers voice
- ❌ Inventer une stat (voir stats.md)
- ❌ Inventer une anecdote perso (voir stories.md)
- ❌ Modifier le texte d'Adrien (sauf fautes évidentes)
- ❌ Publier directement depuis `_drafts/` sans validation Adrien
- ❌ Mettre un em-dash (—) n'importe où dans l'article
- ❌ Plagier la structure ou les phrases d'un site concurrent
- ❌ Citer un concurrent par son nom
- ❌ 2 articles le même jour sauf exception validée par Adrien
- ❌ Modifier une URL déjà publiée sans redirect 301
