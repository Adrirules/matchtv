# editorial/ — La machine à contenu de Coup d'Envoi TV

## En une phrase
Ce dossier est le cerveau éditorial de coupdenvoi.tv. Tout article passe par ici avant d'être publié dans Rails.

## Structure

```
editorial/
├── README.md                      # ce fichier
├── voice/                         # qui est Adrien, comment il parle, ce qu'il pense
│   ├── voice.md                   # ton, registre, mots interdits, phrase-étalon
│   ├── stats.md                   # chiffres vérifiés (prix, audiences, palmarès)
│   ├── stories.md                 # anecdotes perso d'Adrien (France 98, Vélodrome...)
│   ├── opinions.md                # prises de position, hot takes argumentés
│   └── humour.md                  # mécanismes comiques, running gags, limites
├── seo/
│   ├── rules.md                   # règles SEO non négociables
│   ├── keywords.csv               # mots-clés cibles (volume, KD, intent, statut)
│   ├── marronnier.md              # calendrier éditorial 6 mois
│   └── internal-linking.md       # règles de maillage interne
├── workflow/
│   ├── article-template.md        # squelette d'article avec frontmatter
│   ├── competitor-analysis.md     # template analyse concurrents (1 fichier par article)
│   └── checklist.md               # checklist anti-slop avant publication
├── articles/
│   ├── _drafts/                   # en cours de rédaction par Claude
│   ├── _to-review/                # prêts pour relecture Adrien
│   ├── _approved/                 # validés, prêts pour Rails
│   └── _published/                # archive après publication
└── visuals/
    └── README.md                  # convention nommage visuels libres de droit
```

## Workflow standard (2 articles/jour max)

### Étape 1 - Sélection du mot-clé
Adrien enrichit `seo/keywords.csv` avec ses données SEMrush (volume, KD, intent).
Priorité aux mots-clés transactionnels et commerciaux avant les informationnels.

### Étape 2 - Génération (Claude Code)
```
/new-article [keyword]
```
Claude lit les 5 fichiers voice, analyse les 3 premiers résultats Google, et produit un article dans `_to-review/`.

### Étape 3 - Relecture Adrien
- Lire l'article dans `_to-review/[slug].md`
- Corriger le ton si nécessaire (ajouter une anecdote, ajuster l'humour)
- Vérifier les stats citées (anti-bidonnage)
- Fournir l'URL de l'image (Unsplash ou Pexels)
- Déplacer dans `_approved/` si OK, ou renvoyer en `_drafts/` avec commentaires

### Étape 4 - Publication (Claude Code)
Copier le fichier de `_approved/` dans `app/content/blog/` (vérifier que la date n'est pas en doublon).

### Étape 5 - Archive
Déplacer dans `_published/` pour garder `_approved/` propre.

## Cadence de publication

| Rythme | Détail |
|---|---|
| Cible | 2 articles/jour (1 jour sur 2 = ~45 articles/mois) |
| Max absolu | 2 articles/jour, jamais plus |
| Exception OK | Un article éditorial fort (grosse actualité CdM, etc.) peut s'ajouter ponctuellement |
| Règle d'or | Les dates doivent paraître organiques. Jamais 3+ articles le même jour. |

## Règle absolue : jamais de publication directe depuis `_drafts/`

Adrien relit chaque article. C'est le filtre humain qui fait la différence entre un site SEO et un site de qualité — et ce qui protège le compte AdSense.

## Les 5 fichiers voice (à lire avant chaque article)

1. `voice/voice.md` - le ton, les mots interdits, la phrase-étalon
2. `voice/stories.md` - les anecdotes disponibles (ne JAMAIS en inventer)
3. `voice/opinions.md` - les prises de position sur le sujet
4. `voice/humour.md` - les mécanismes comiques à activer (ou pas)
5. `voice/stats.md` - les chiffres vérifiés à citer

## La ligne éditoriale en 1 phrase (hot take 11, opinions.md)

On fait l'inverse des médias dominants : on parle des jeunes, on évite les rivalités artificielles, on ignore les commérages. On parle de foot.
