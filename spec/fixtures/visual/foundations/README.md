# Références visuelles de l’application

## Revue du 16 novembre 2026

Décision : à la demande de mise à jour des tests, prendre comme référence l’interface actuellement implémentée. Les anciens PNG de septembre représentaient la première navigation et un catalogue qui ont depuis été remplacés. Les contrôles métier, d’accessibilité, d’absence de débordement et le seuil de différence de 0,5 % sont conservés.

Les 16 candidats ont été générés explicitement, puis les vues mobile et bureau de l’accueil, de la connexion et du catalogue ont été examinées avant adoption. L’accueil conserve son contenu de secours en l’absence de version publiée ; les tests du Studio vérifient séparément l’accueil composé et publié en V2. La revue constate le menu actuel, le footer à quatre rubriques et sa vague, le champ de mot de passe avec visibilité, et le nouveau catalogue avec recherche, filtres et carte d’annonce. Aucun élément tronqué ni débordement horizontal constaté. Les liens de chaîne déjà présents dans le footer sont conservés.

| Capture | Ancienne hauteur | Nouvelle hauteur |
| --- | ---: | ---: |
| Accueil 375 px | 2365 px | 2998 px |
| Accueil 1440 px | 1947 px | 2233 px |
| Connexion 375 px | 1275 px | 1920 px |
| Connexion 1440 px | 1201 px | 1497 px |
| Catalogue 375 px | 1722 px | 3535 px |
| Catalogue 1440 px | 1416 px | 2180 px |

Les largeurs testées restent 320, 375, 414, 768, 1024, 1280 et 1440 px pour l’accueil et la connexion, et 375/1440 px pour le catalogue. Les comparaisons suivantes lisent ces références sans les modifier.

### Navigation et mot de passe — seconde revue du 16 novembre

À la demande explicite de correction de l’interface : suppression du dégradé, du flou et de la bordure de la navbar ; les en-têtes composés remontent derrière elle. Sur les pages claires sans en-tête illustré, les liens restent foncés. Le raccourci « Modifier cette page » est retiré du site public. Le bouton du mot de passe mesure 44 × 44 px, reste centré et affiche un œil fermé tant que le texte est masqué.

Les 16 candidats ont été recapturés explicitement et les vues connexion/catalogue/accueil ont été examinées sur mobile et ordinateur, ainsi que les en-têtes communauté, voyage et le canevas publié V2. Les hauteurs des 16 références restent identiques à celles de la revue précédente ; les différences attendues concernent la navigation et le champ de mot de passe. Le seuil reste 0,5 %. Les tests navigateur vérifient en plus la transparence calculée, le départ des en-têtes à 0 px, l’absence de chevauchement des titres et les deux états de l’œil au clavier et à la souris.

## Historique

Captures du 5 septembre 2026 : accueil F-001 et connexion Devise, thème de base SEOS, viewport de 1000 px de haut et capture de la page entière. Linux, Chrome for Testing/ChromeDriver 151.0.7922.77, DPR 1, polices WOFF2 du lockfile Yarn. Les fichiers nommés 320/375/414/768/1024/1280/1440 ont la largeur indiquée.

Ces références portent sur le premier socle implémenté. Elles ne remplacent pas les futures références exhaustives de `docs/maquette.html` : l’accueil complet, les annonces et les composants métier ne sont pas encore intégrés. Elles restent à examiner dans la revue de cette première livraison.

Les tests lisent ces PNG et produisent les images obtenues/diffs dans `tmp/screenshots`. Ils échouent si une référence manque ou si l’écart dépasse 0,5 %. Le mode explicite `CAPTURE_VISUAL_CANDIDATES=1` écrit seulement des candidats dans `tmp/`, jamais ici, et est interdit en CI. Toute modification d’une référence existante doit documenter la décision produit et la revue avant/après.

Les références ont fait l’objet d’une [revue explicite le 5 septembre](../../../../docs/16-revue-visuelle-decouverte.md) pour les liens de navigation et du footer. Deux références du catalogue ont été ajoutées aux largeurs 375 et 1440. Les tests n’écrivent jamais ces fichiers.

Revue du 6 septembre 2026 (phase 7) : ajout du lien public « Confidentialité et cookies » dans le footer. Les 16 captures ont été recapturées explicitement et les différences localisées au footer ; le mobile 320 px gagne 39 px de hauteur. Voir [le suivi de phase 7](../../../../docs/21-suivi-phase-7.md). Le seuil de comparaison reste 0,5 %.
