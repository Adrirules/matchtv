# visuals/ — Conventions pour les visuels

> Ce dossier peut contenir les images locales si on décide d'héberger les visuels sur le serveur. En attendant, on utilise des URLs Unsplash/Pexels directement dans le frontmatter.

---

## Sources approuvées

| Source | URL | Licence |
|---|---|---|
| Unsplash | https://unsplash.com | Libre de droit commercial |
| Pexels | https://www.pexels.com | Libre de droit commercial |

**Jamais** : Getty Images, AFP, Reuters, images Google Images → risque juridique immédiat.

---

## Format URL Unsplash recommandé

```
https://images.unsplash.com/photo-[ID]?w=1200&q=80
```

- `w=1200` : largeur 1200px pour un bon rendu desktop
- `q=80` : qualité 80% (bon ratio taille/qualité)

---

## Recherches Unsplash par thème

| Thème | Termes de recherche Unsplash |
|---|---|
| Football générique | "soccer", "football", "stadium" |
| Supporters en tribune | "soccer fans", "football crowd", "stadium crowd" |
| Match en direct | "soccer match", "football game" |
| Télévision / streaming | "watching tv", "tv remote", "streaming" |
| Stade vide | "empty stadium", "soccer field" |
| Trophée / coupe | "trophy", "champions cup" |
| Équipe de France | rechercher "french football" - vérifier que c'est bien les Bleus |

---

## Convention de nommage (si hébergement local futur)

```
[slug-article]-[description-courte].jpg
```

Exemples :
- `ou-regarder-ligue-1-2026-supporters.jpg`
- `canal-plus-vs-dazn-telecommande.jpg`
- `coupe-du-monde-2026-trophee.jpg`

---

## Workflow image

1. **Adrien fournit l'URL** Unsplash ou Pexels dans le thread
2. **Claude ajoute l'URL** dans le frontmatter `image:` de l'article
3. **Crédit photo** : récupérer le nom du photographe sur Unsplash et l'ajouter dans `image_credit: "Photo : Unsplash / Nom Photographe"`
4. **Vérifier** que l'image est pertinente avec le sujet (pas de foot américain pour un article Ligue 1)
