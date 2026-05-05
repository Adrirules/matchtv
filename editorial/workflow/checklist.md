# checklist.md — Anti-slop avant publication

> À passer sur chaque article avant déplacement de `_to-review/` vers `_approved/`. Binaire : ✅ ou ❌. Un seul ❌ = l'article retourne en `_drafts/`.

---

## 🔴 Bloquants absolus (1 seul suffit à bloquer)

- [ ] **Aucun em-dash (—)** dans tout le fichier (chercher "—" → 0 résultats)
- [ ] **Aucun mot interdit** de la liste voice.md section 5 ("pépite", "glané", "incontournable", "emblématique", "il est important de noter", "en effet", "livrer une copie sérieuse"...)
- [ ] **Aucune anecdote inventée** — chaque "je me souviens" ou "j'étais..." est dans stories.md
- [ ] **Aucune stat inventée** — chaque chiffre cité est dans stats.md ou a été vérifié via web_search
- [ ] **Frontmatter complet** — tous les champs remplis, URL image fournie par Adrien
- [ ] **1 seul H1** dans tout le document
- [ ] **Tutoiement partout** — aucun "vous" ni "l'amateur de football"
- [ ] **Minimum 3 liens internes** avec ancres descriptives
- [ ] **FAQ présente** avec 4-6 questions (sauf article < 500 mots)
- [ ] **Aucune référence à un concurrent** (FootMercato, L'Équipe, RMC, etc.)
- [ ] **Aucun commérage** (tweets, vies privées, clashs réseaux sociaux)

---

## 🟠 Qualité de fond (à vérifier attentivement)

- [ ] **La réponse principale est dans les 2 premières phrases** — le lecteur obtient l'info sans scroller
- [ ] **Le titre ne crée pas de frustration** — le lecteur sait ce qu'il va trouver avant de cliquer
- [ ] **H2 = intentions secondaires réelles** — pas du remplissage, pas du SEO mécanique
- [ ] **Paragraphes courts** — 2-4 lignes max, jamais de mur de texte
- [ ] **1 tableau minimum** si le sujet s'y prête (comparatifs, prix, classements)
- [ ] **1 analogie au moins** pour les articles > 600 mots
- [ ] **Marker affiliation** placé au bon endroit (après 2ème ou 3ème H2, jamais dans la FAQ)

---

## 🟡 Voix et ton (le test Adrien)

- [ ] **Mélange de registres** — au moins 2 registres sur 3 (Sud / classique français / moderne)
- [ ] **L'intro ne commence pas par** "Le football est...", "Il existe plusieurs...", "Quand on parle de..."
- [ ] **Les transitions** utilisent "Sauf que...", "Le truc c'est que...", "Bon.", "Mais attends..." — pas "De plus", "Par ailleurs", "En outre"
- [ ] **L'humour est proportionné** au type d'article (voir humour.md tableau de calibrage)
- [ ] **Si humour présent** : passe les 4 tests (surprend ? moque un faible ? nécessite explication ? sonne LLM ?)
- [ ] **Test final** : "Est-ce qu'un pote qui connaît Adrien dirait : c'est lui qui a écrit ça ?"

---

## 🔵 SEO technique

- [ ] **Mot-clé principal** dans H1 + intro (naturellement) + conclusion
- [ ] **Entités en gras** : noms de chaînes, compétitions, clubs, chiffres importants
- [ ] **Slug** : mot-clé en premier, minuscules, sans accents, max 6-7 mots
- [ ] **Meta description** : 140-160 caractères (compter), cliquable, contient le mot-clé
- [ ] **published_time** : entre 08h00 et 17h00, format HHhMM, minutes non-rondes
- [ ] **Date de publication** : prochain slot libre (vérifier les articles existants)
- [ ] **FAQ** : réponses courtes (2-3 lignes), aucun lien dans les réponses, aucun humour

---

## ⚪ À noter pour Adrien (pas bloquant, mais à relire)

- [ ] Les statistiques citées correspondent bien au stats.md (ou ont été ajoutées dedans)
- [ ] Les anecdotes piochées dans stories.md sont amenées naturellement (varier les entrées : "À l'époque...", "Tiens, ça me rappelle...", "Y a un truc que j'oublierai jamais...")
- [ ] L'opinion d'Adrien présente est cohérente avec opinions.md
- [ ] Le marker affiliation est cohérent avec le contenu (pas de banner DAZN dans un article critique de DAZN)
- [ ] L'article n'est pas une répétition d'un article déjà publié (vérifier `_published/`)

---

## Résultat

| Catégorie | Statut |
|---|---|
| 🔴 Bloquants | ✅ / ❌ |
| 🟠 Qualité de fond | ✅ / ❌ |
| 🟡 Voix et ton | ✅ / ❌ |
| 🔵 SEO technique | ✅ / ❌ |

**Décision** : [ ] Approuvé → `_approved/` / [ ] À retravailler → `_drafts/` avec commentaires

**Commentaires pour Adrien** :
[Laisser vide si tout est OK. Sinon noter ce qui doit être corrigé ou ce qui mérite attention.]
