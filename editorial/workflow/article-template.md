# article-template.md — Squelette d'article

> Copier ce template dans `_drafts/[slug].md` avant de rédiger. Remplacer tous les placeholders `[...]`. Ne pas modifier la structure sauf si le sujet l'impose vraiment.

---

## Frontmatter (à compléter en premier)

```yaml
---
title: "[Titre SEO complet, 50-60 caractères] | Coup d'Envoi TV"
meta_description: "[140-160 caractères. Contient le mot-clé. Cliquable sans être racoleur.]"
slug: "[mot-cle-principal-angle-2026]"
primary_keyword: "[mot-clé principal exact]"
content_type: "[guide | comparatif | editorial | liste]"
published_at: "[YYYY-MM-DD]"
published_time: "[HHhMM]"
author: Adrien
image: "[URL Unsplash ou Pexels - fournie par Adrien]"
image_credit: "Photo : Unsplash / [Nom Photographe]"
excerpt: "[1-2 phrases pour la liste /blog. Accrocheur, sans spoiler.]"
---
```

**Checklist frontmatter :**
- [ ] `title` : 50-60 caractères, mot-clé en tête, se termine par "| Coup d'Envoi TV"
- [ ] `meta_description` : 140-160 caractères (compter)
- [ ] `slug` : mot-clé en premier, minuscules, sans accents, max 6-7 mots, tirets
- [ ] `published_at` : prochain jour sans article existant (vérifier `app/content/blog/`)
- [ ] `published_time` : entre 08h00 et 17h00, minutes aléatoires (pas pile)
- [ ] `image` : URL fournie par Adrien (ne pas inventer)

---

## Structure de l'article

### Intro (2-4 lignes)

[Accroche directe : question rhétorique, affirmation forte, entrée à l'oral ou souvenir de stories.md si pertinent. PAS de "Le football est un sport qui...". Tutoiement. 2-4 lignes max.]

---

### Réponse rapide

> **En bref :** [Réponse en 1-2 phrases. Snippet-ready. La réponse principale avant tout développement.]

---

### [H2 : Sous-intention principale]

[Contenu : 150-300 mots. Tableau si le sujet s'y prête. 1 opinion ou anecdote naturellement glissée (opinions.md ou stories.md). 1 lien interne vers /chaines/ ou /competitions/.]

<!-- BANNIÈRE : si article Canal+ → CANAL_BANNER / si article DAZN/L1 → DAZN_BANNER / si article beIN → RAT_SPORT_BANNER -->

---

### [H2 : Sous-intention secondaire]

[Contenu : 150-300 mots. Inclure au moins 1 chiffre sourcé de stats.md. 1 lien interne.]

---

### [H2 : Sous-intention tertiaire - si nécessaire]

[Contenu : 100-200 mots. Peut inclure un tableau comparatif si article comparatif.]

---

### [H2 : Conseil pratique / comment faire]

[Contenu actionnable. Listes à puces si plusieurs étapes. C'est ici qu'on glisse hot take 2 (abonnements stratèges) si pertinent.]

---

### Questions fréquentes

**[Question réelle People Also Ask ?]**
[Réponse courte, 2-3 lignes. Aucun humour. Snippet-ready.]

**[Question 2 ?]**
[Réponse.]

**[Question 3 ?]**
[Réponse.]

**[Question 4 ?]**
[Réponse.]

---

### [Conclusion / recommandation d'Adrien]

[Conseil perso. Pas de résumé mécanique. 3-5 lignes max. Peut se terminer par "Allez l'OM !" (1 article sur 5 environ).]

---

## Placement des markers affiliation

À insérer dans le corps de l'article (après le 2ème ou 3ème H2, pas avant le premier contenu) :

```
<!-- CANAL_BANNER -->      → pour Canal+, LDC, Europa, Conference, PL, Top 14
<!-- DAZN_BANNER -->       → pour DAZN, Ligue 1, Serie A, Eredivisie, Bundesliga
<!-- RAT_SPORT_BANNER -->  → pour beIN Sports, La Liga, Bundesliga (si pas DAZN)
<!-- CANAL_PLUS_CARD -->   → encart présentation Canal+ (comparatifs)
<!-- DAZN_CARD -->         → encart présentation DAZN (comparatifs)
```

---

## Checklist avant déplacement en `_to-review/`

**Intention & réponse**
- [ ] La réponse principale est dans les 2 premières phrases
- [ ] Pas de blabla avant la réponse utile

**Structure**
- [ ] 1 seul H1 (le titre de l'article)
- [ ] H2 = intentions secondaires réelles, pas du remplissage
- [ ] Paragraphes courts (2-4 lignes max)
- [ ] Listes à puces là où c'est pertinent
- [ ] 1 tableau minimum si le sujet s'y prête
- [ ] 1 analogie au moins (pour articles > 600 mots)

**Mots-clés & entités**
- [ ] Mot-clé principal dans H1 + intro + conclusion
- [ ] Entités importantes en **gras** (noms de chaînes, compétitions, clubs)
- [ ] Pas de répétition mécanique du même mot-clé

**E-E-A-T & voix humaine**
- [ ] Aucun em-dash (—) - chercher "—" dans le fichier, doit retourner 0 résultats
- [ ] Aucun mot de la liste interdite (voice.md section 5)
- [ ] Ton Adrien reconnaissable (tutoiement, registres mélangés)
- [ ] Vécu ou anecdote présente si article éditorial (pioché dans stories.md)

**Maillage interne (minimum 3 liens)**
- [ ] Lien vers /chaines/* si chaîne mentionnée
- [ ] Lien vers /competitions/* si compétition mentionnée
- [ ] Lien vers /classements/* si pertinent
- [ ] Lien vers 1 article blog existant
- [ ] Ancres descriptives (pas "clique ici")

**FAQ**
- [ ] 4 à 6 questions réelles
- [ ] Réponses 2-3 lignes max
- [ ] Aucun humour dans la FAQ
- [ ] Aucun lien dans les réponses FAQ

**Frontmatter**
- [ ] Tous les champs remplis
- [ ] published_time entre 08h00 et 17h00 (format HHhMM)
- [ ] Date de publication = prochain slot libre
- [ ] URL image fournie par Adrien (pas d'URL inventée)
- [ ] Marker affiliation au bon endroit dans le contenu
