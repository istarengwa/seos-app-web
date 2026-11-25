# Modération et supervision

L’accueil de l’administration met en avant les annonces, les membres et les signalements. La modération des annonces et la gestion des demandes d’association et de partenariat sont incluses dans le rôle admin actif et confirmé. Les autres permissions restent attribuées individuellement par un super administrateur. La gestion du site (contenus, catégories, restrictions, Studio et apparence) est réservée aux super admins, même en présence d’anciennes permissions éditoriales.

## Annonces

Le catalogue de modération est paginé à 20 annonces, recherchable par titre ou identifiant et filtrable par membre, statut, signalements ouverts ou blocage de modération. Les brouillons ne sont pas exposés aux admins ordinaires. La fiche présente le contenu public et les photos, avec accès au membre et aux signalements correspondants selon les droits.

`listings.moderate`, automatiquement effectif pour les admins, autorise la suspension, le retrait, la mise en examen et la remise en ligne après examen. Le motif est obligatoire, la transaction journalisée et le propriétaire notifié. La suspension et le retrait posent un blocage qui empêche la republication par l’auteur. Le circuit normal de publication des annonces reste inchangé ; les restrictions de catégories existantes continuent de s’appliquer.

## Membres et avis

`users.read` ouvre la recherche par nom public ou identifiant, les filtres de rôle et de statut, et une fiche contenant la présentation publique, les comptes d’annonces, le score de confiance actuellement publié et les avis déjà révélés. E-mail complet, adresse précise, téléphone et conversations privées ne sont pas présents dans cette fiche. Les calculs de confiance en ombre restent masqués.

Le nouveau droit `users.moderate`, à attribuer avec `users.read`, permet la suspension ou la réactivation d’un compte membre actif ou suspendu. Il ne permet ni changement de rôle, ni sanction d’un admin, ni réactivation d’un compte anonymisé ou en attente. La suspension révoque les sessions actives. Un motif est obligatoire et toute décision est auditée.

`reports.manage`, avec `users.read`, permet de modérer un avis révélé depuis la fiche de son destinataire : masquer/restaurer le texte ou invalider l’avis pour le calcul du score. Les avis différés restent inaccessibles, y compris par identifiant direct. Le rappel de recalcul existant est conservé ; la mise à jour du score est asynchrone. Restaurer le texte d’un avis invalidé ne rétablit pas sa contribution au score.

## Vue d’ensemble

La page d’accueil de l’administration répartit ses contenus en onglets : **Activité**, **Outils de gestion**, **Accès des membres**, **Demandes de données**, puis **Journal d’audit**. Les accès sont réservés aux super administrateurs, les demandes exigent `privacy.manage` et le journal exige `audit.read`. Les URL conservent l’onglet actif ; les filtres et la pagination du journal restent dans leur onglet. Les anciennes URL de supervision redirigent vers cette page, après contrôle du rôle.

L’explorateur de registres et ses exports ont été retirés. Les indicateurs utiles sont réunis dans Activité et renvoient aux outils de gestion correspondants.

Dans Accès des membres, la suspension groupée accepte de 1 à 20 numéros issus de la liste des membres, séparés par virgules, espaces ou points-virgules, avec ou sans #. La prévisualisation affiche les noms et les numéros. La suspension exige toujours la confirmation d’un autre super administrateur dans les 15 minutes et vérifie que les comptes n’ont pas changé. Le blocage temporaire concerne explicitement une adresse e-mail de connexion, avec date de fin et motif. Des exemples et des indications accompagnent les champs.

Les formulaires de purge manuelle ont été retirés. Les demandes de droits sont dans Vue d’ensemble ; les durées de conservation se modifient dans Studio V2 → Documents légaux → Durées de conservation des données. Elles réutilisent les versions, simulations et validations existantes, avec unités en jours et sans JSON dans l’interface. Leur confirmation exige un autre super administrateur après validation juridique. Les anciennes URL de confidentialité redirigent vers l’outil correspondant. Les entrées de menu « Journal & textes légaux » et « Confidentialité » sont supprimées.

## Indexation publique

Les pages publiques sont ouvertes par défaut aux moteurs de recherche et aux robots d’IA. Les consignes sont définies dans le code de `SeoController`, sans réglage dans l’administration ; les anciennes lignes de `CrawlerPolicy` ne changent plus ce comportement. Les espaces privés restent exclus et les aperçus administratifs restent en `noindex`.

## Indicateurs du tableau de bord principal

Admins et super admins disposent d’une vue agrégée sur 7, 30 ou 90 jours : inscriptions (créations de comptes, même non confirmés), premières publications d’annonces et comparaison avec la période précédente. Les comptes présents et les statuts actuels des annonces sont affichés séparément des flux de la période. Les données ne constituent pas une archive des enregistrements définitivement supprimés.

Les séries quotidiennes sont regroupées en SQL par heure UTC, puis réparties dans les jours calendaires de Paris. Les passages à l’heure d’été et d’hiver sont ainsi respectés, sans charger les objets utilisateurs. Le jour courant est incomplet ; le reste de la comparaison utilise la période précédente de même longueur. Les premières publications utilisent published_at et restent comptées si l’annonce a ensuite changé de statut.

Le graphique SVG distingue les courbes par leur couleur et leur tracé. Le survol, le clic ou le curseur clavier permettent de lire un jour précis ; un tableau détaillé est également disponible, y compris sans JavaScript. Les jours sans activité sont affichés à zéro. Aucun nom, adresse ou contenu privé n’est transmis au graphique. Les accès rapides à la modération restent placés avant les indicateurs.

Les super admins disposent en complément des compteurs actuels d’organisations en attente, de missions au statut publié et de signalements ouverts. Les brouillons sont inclus dans leur répartition des annonces et exclus de celle des admins ordinaires.


## Accès des admins aux associations et partenariats

Les droits organizations.read, organizations.manage et partnerships.manage sont inclus dans le rôle admin, sans attribution individuelle. Le tableau de bord propose un accès rapide « Associations et partenariats » et une carte « Gérer les demandes ». Les validations/refus de structures et les décisions sur les propositions réutilisent les workflows audités existants.

La consultation des coordonnées légales privées exige toujours organizations.legal et un motif de révélation. La récupération du propriétaire, le changement de type de structure et l’activation des parcours publics restent réservés aux super admins. La gestion des missions ne devient pas automatiquement incluse.
