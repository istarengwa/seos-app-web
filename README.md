# SEOS France

SEOS est une application d’entraide locale en **version de développement**, construite avec Rails 8.1. Elle permet de publier des annonces de services, organiser des échanges, suivre les Points Services, parrainer des membres et participer à des actions associatives.

L’administration comprend la modération, les organisations, les quêtes, les témoignages, les chaînes d’entraide, les demandes de confidentialité et un **éditeur visuel V2 basé sur GrapesJS**.

## Démarrer en développement

### Prérequis

| Outil | Version ou usage |
| --- | --- |
| Ruby | 3.4.7, défini dans `.ruby-version` |
| Bundler | 2.7.2 |
| Node.js | 24.8.0 |
| Yarn Classic | 1.22.22 |
| SQLite 3 | Base locale et tests habituels |
| libvips | Traitement des images |
| FFmpeg et FFprobe | Traitement des vidéos |

Depuis la racine du dépôt :

```sh
bin/setup --skip-server
bin/dev
```

Ouvrir **http://localhost:3000**. `bin/setup` installe les dépendances, prépare la base, charge les données de développement sur une base neuve et compile les assets. `bin/dev` lance Rails et la compilation JavaScript/CSS en continu.

Aucun fichier `.env` n’est nécessaire pour utiliser la démonstration locale. Les e-mails sont enregistrés dans **`tmp/mail/`**, sans envoi externe. Après une inscription, ouvrir le lien de confirmation contenu dans le fichier mail.

Pour mettre à jour une base locale existante et compléter ses données de démonstration :

```sh
bin/rails db:migrate
bin/rails db:seed
yarn build
```

Les seeds ne réinitialisent pas les mots de passe ou les contenus déjà personnalisés. Redémarrer Rails après une modification des routes ou de la configuration. La base et les téléversements locaux sont conservés dans `storage/`.

### Comptes de démonstration

Connexion : **http://localhost:3000/auth/connexion**. Mot de passe initial commun : **`SeosDemo2026!`**.

| E-mail | Parcours de démonstration |
| --- | --- |
| `membre@seos.test` | Compte personnel et annonces |
| `association@seos.test` | Responsable de l’association vérifiée « Entraide solidaire — Démo » |
| `admin@seos.test` | Modération et droits administratifs de démonstration |
| `partenaire@seos.test` | Membre lié à une organisation en attente de vérification |
| `superadmin@seos.test` | Administration complète, permissions et éditeur du site |

Ces comptes sont actifs et confirmés. Le jeu local comprend aussi des profils, catégories, annonces illustrées, missions solidaires, quêtes, barèmes de points et contenus de présentation. Il est réservé au développement.

## Utiliser l’application

| Espace | Accès et fonctions |
| --- | --- |
| Site public | `/` ; annonces `/annonces` ; communauté `/communaute` ; associations `/associations` ; missions `/voyage-solidaire` |
| Compte membre | `/compte` : profil, annonces, échanges, favoris, notifications et réglages |
| Engagement | `/compte/points`, `/compte/engagement`, `/compte/chaines` et `/compte/confiance` |
| Organisations | `/compte/organisations` : présentation, équipe et missions selon le rôle du membre |
| Administration | `/admin` : modération, membres, activité et outils accessibles selon les permissions |
| Éditeur du site | `/admin/site`, réservé au super-admin |
| Confidentialité | `/preferences-confidentialite` et `/compte/confidentialite` |

Les échanges peuvent se faire sous forme de don, de troc ou de Points Services. Les transferts de points accompagnent la confirmation de l’échange ; les récompenses et les ajustements sont enregistrés dans le portefeuille. Le parrainage actuel utilise un lien personnel permanent, accessible depuis l’espace Confiance.

### Modifier le site avec le Studio V2

1. Se connecter avec le super-admin, ouvrir **Administration → Outils → Éditeur visuel**.
2. Choisir la page dans le sélecteur du constructeur.
3. Ajouter une composition ou un élément, puis sélectionner les éléments pour modifier leur texte, leur apparence et leur disposition.
4. Cliquer sur **Enregistrer** pour conserver un brouillon privé.
5. Cliquer sur **Vérifier et publier**, relire l’aperçu pleine page, régler sa largeur avec le curseur ou les boutons d’appareil, puis confirmer avec **Enregistrer et publier**.

Les modifications deviennent publiques après cette dernière confirmation. Les contenus dynamiques, comme les annonces ou les missions, sont alimentés par l’application. Les anciennes URL d’ouverture de l’éditeur redirigent vers la V2.

Les réglages courants sont présentés en français dans **Style** ; les propriétés CSS détaillées restent dans **Avancé → Réglages techniques**. Les vagues existantes se sélectionnent dans la page ou dans **Structure** : direction, courbure, hauteur, couleur et inclinaison sont réglables. Les boutons miroir retournent aussi les autres éléments. Un changement de page enregistre les modifications en cours ; une erreur d’enregistrement maintient la page ouverte.

Pour les CGU, la confidentialité, les cookies et les mentions légales, ouvrir **Documents légaux**. Chaque document a son titre, son résumé et un texte avec boutons de mise en forme. Les textes restent privés jusqu’à la publication du Studio, qui crée des versions légales séparées et auditées. **Reprendre la version publique** remplace le brouillon local du document sélectionné par le contenu public actuel. Une publication devenue obsolète est refusée pour préserver les corrections faites entre-temps.

## Configuration d’environnement

**Le seul modèle de configuration est [`.env.example`](.env.example), à la racine.** Il présente les variables utilisées par le déploiement de production et les options facultatives de l’application.

```sh
cp .env.example .env
```

Remplacer les valeurs `REPLACE_WITH_…` avant de démarrer le Compose. Le fichier `.env` est ignoré par Git et exclu de l’image Docker.

- **Docker Compose** charge automatiquement `.env` depuis la racine. Un autre fichier peut être choisi avec `--env-file /chemin/seos.env`.
- **Coolify** reçoit ces variables dans son interface de configuration ; ne pas ajouter les secrets au dépôt.
- **Rails en développement** utilise les variables exportées dans le terminal. `bin/dev` ne charge pas le `.env` de production. Pour activer une option locale, exporter uniquement les variables utiles avant de le lancer.

### Messagerie et connexion Google

| Usage | Variables |
| --- | --- |
| Expéditeur des e-mails de l’application | `SEOS_MAIL_FROM` |
| Envoi par l’API Gmail en production | `SEOS_MAIL_DELIVERY=gmail`, `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`, `GMAIL_REFRESH_TOKEN` |
| Connexion facultative avec Google | `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` |
| Fond de carte facultatif | `MAP_TILE_URL`, avec les paramètres `{z}`, `{x}`, `{y}` |

L’expéditeur doit être la boîte Gmail autorisée ou l’un de ses alias autorisés. Les identifiants `GMAIL_*` proviennent de Google OAuth. Les mêmes paramètres d’expéditeur sont utilisés pour les notifications et les mails de confirmation/réinitialisation. En développement, l’envoi reste local dans `tmp/mail/` tant que le mode Gmail n’est pas explicitement activé.

Le jeton Gmail doit autoriser `gmail.send` et `gmail.readonly` : le second scope permet de retrouver un message après une réponse réseau incertaine et d’éviter un double envoi. Obtenir un jeton de renouvellement OAuth avec accès hors ligne pour la boîte expéditrice. Pour la connexion des membres, déclarer séparément le callback `https://VOTRE_HOTE/auth/auth/google_oauth2/callback` dans le client OAuth Google.

## Bases et initialisation

| Environnement | Base | Seeds |
| --- | --- | --- |
| Développement | SQLite | Toutes les données et démonstrations locales |
| Test | SQLite par défaut ; PostgreSQL pour le contrôle de compatibilité CI | Références métier lorsqu’un test demande les seeds |
| Production | PostgreSQL | Uniquement l’accueil publié et ses dix sections de base |

`db/seeds.rb` sélectionne le fichier approprié dans `db/seeds/`. Au premier `db:prepare` d’une nouvelle production, l’accueil est initialisé dans une transaction. Un marqueur `SeedRun` empêche toute nouvelle création : un redémarrage ou même un `db:seed` manuel ne remplace ni ne recrée un accueil déjà initialisé, y compris après sa suppression.

Les bases existantes sont préservées lors de la mise à niveau. Aucun compte, annonce, quête, barème ou document légal de démonstration n’est créé par les seeds de production.

Le schéma standard est **`db/schema.rb`**. Les migrations fonctionnent sur SQLite et PostgreSQL sans renommage des fichiers historiques. Les règles métier sont écrites en Ruby, avec transactions et verrouillages ; les clés étrangères, index uniques et contraintes simples restent dans la base. Les écritures SQL directes et les méthodes qui ignorent les callbacks ne bénéficient pas des protections des modèles Rails.

## Vérifier les changements

```sh
yarn build
yarn build:check
bundle exec rspec
bin/check-ledger-concurrency
bin/check-exchange-concurrency
bin/rails zeitwerk:check
bin/rubocop
```

RSpec couvre les modèles, services, requêtes HTTP et parcours navigateur. **Compiler les assets avant les tests** : un build absent ou périmé est refusé. Pour travailler sur un groupe ciblé sans appliquer les seuils globaux de couverture :

```sh
COVERAGE=0 bundle exec rspec spec/requests/studio_builder_v2_spec.rb
```

Les tests navigateur utilisent Chrome for Testing et ChromeDriver, à la version inscrite dans `.chrome-version`. Selenium peut les installer ; `CHROME_BIN` et `CHROMEDRIVER_BIN` permettent d’utiliser une installation existante. Les captures et rapports restent dans `tmp/`. Les références visuelles et leur procédure de revue sont décrites dans `spec/fixtures/visual/foundations/README.md`.

`bin/ci` regroupe les vérifications locales. Les workflows GitHub vérifient aussi PostgreSQL, les migrations et le Compose. Les seuils de couverture sont définis dans `spec/spec_helper.rb` ; les audits de dépendances et `bin/brakeman` complètent les tests fonctionnels.

## Production avec Docker Compose et Coolify

Le [`docker-compose.yml`](docker-compose.yml) construit le code du dépôt et regroupe tous les services dans **une seule application Coolify**, sans `include:`.

| Service | Fonction |
| --- | --- |
| `postgres` | PostgreSQL 17 ; bases principale, cache, queue et cable |
| `migrate` | `bin/rails db:prepare`, puis arrêt normal avec code 0 |
| `web` | Rails/Puma derrière Thruster, port interne 80 |
| `jobs` | Solid Queue, traitement asynchrone et tâches planifiées |

Solid Cache et Solid Cable utilisent PostgreSQL. Les services et dépendances actuels ne nécessitent ni Redis ni Sidekiq. Le worker charge les tâches de `config/recurring.yml` : confidentialité, points, confiance, expiration des annonces et nettoyage des tâches terminées. Ne pas activer un second worker Solid Queue dans Puma avec cette configuration.

### Préparer les variables

Générer séparément le mot de passe PostgreSQL, `SECRET_KEY_BASE` et les trois clés `ACTIVE_RECORD_ENCRYPTION_*`, par exemple avec cinq exécutions de :

```sh
openssl rand -hex 32
```

Conserver ces valeurs entre les redéploiements et les sauvegarder séparément des données. Les clés de chiffrement d’origine sont nécessaires à la restauration des données chiffrées. `RAILS_MASTER_KEY` est nécessaire uniquement si des secrets sont lus dans les credentials Rails chiffrés.

Renseigner l’hôte public sans protocole ni chemin, l’expéditeur autorisé et les trois identifiants Gmail. Ne pas définir `DATABASE_URL` pour cette stack : les quatre bases sont configurées avec les variables `POSTGRES_*`. Modifier `POSTGRES_PASSWORD` ne change pas le mot de passe d’un rôle PostgreSQL déjà créé dans un volume existant.

### Déployer dans Coolify

1. Créer une **Application depuis le dépôt Git**, sélectionner la branche et choisir le build pack **Docker Compose**.
2. Définir **Base Directory** sur `/` et **Docker Compose Location** sur `/docker-compose.yml`. Garder le mode Raw Compose désactivé.
3. Recharger la configuration et vérifier les quatre services et les deux volumes persistants.
4. Saisir les variables de `.env.example` dans Coolify, en remplaçant toutes les valeurs d’exemple.
5. Affecter le domaine HTTPS au seul service **web**, avec le port interne **80** : par exemple `https://seos.example.org:80` dans le champ Coolify. L’URL publique reste `https://seos.example.org`.
6. Déployer. PostgreSQL devient sain, `migrate` termine avec code 0, puis `web` et `jobs` démarrent.

Le proxy Coolify termine HTTPS. `SEOS_ASSUME_SSL=true` configure Rails pour cet accès. Les bases et le worker ne publient aucun port sur l’hôte.

Pour lancer la même stack hors Coolify, depuis la racine avec un `.env` rempli :

```sh
docker compose config --quiet
docker compose up --build -d
```

Un proxy HTTPS ou un override de publication du port web est nécessaire pour y accéder. Pour un essai local en HTTP, définir aussi `SEOS_ASSUME_SSL=false`.

### Premier compte et vérifications

La production ne contient aucun compte de démonstration. Créer un compte par inscription, confirmer son e-mail, puis initialiser le premier super-admin depuis le conteneur :

```sh
docker compose exec -e EMAIL=adresse-du-compte@example.org web bin/rails seos:bootstrap_super_admin
```

Cette commande refuse de s’exécuter si un super-admin existe déjà. Elle journalise l’action et révoque les sessions du compte : se reconnecter ensuite.

```sh
docker compose ps -a
docker compose logs migrate web jobs
curl --fail https://seos.example.org/up
docker compose exec web bin/rails runner 'puts ActiveRecord::Base.connection.adapter_name'
docker compose exec jobs bin/rails runner 'p SolidQueue::Process.pluck(:kind, :last_heartbeat_at)'
docker compose exec jobs bin/rails runner 'p SolidQueue::RecurringTask.pluck(:key)'
```

Vérifier PostgreSQL, une réponse HTTP 200, des processus actifs et les cinq tâches récurrentes, puis une inscription avec confirmation et un parcours de sauvegarde/publication V2. L’initialisation vise une nouvelle production PostgreSQL ; aucune ancienne base SQLite n’est importée automatiquement.

### Persistance et sauvegardes

- `postgres_data` conserve les quatre bases PostgreSQL.
- `app_storage`, partagé par le web et le worker, conserve les téléversements et fichiers privés.

Conserver l’identité de ces volumes lors des redéploiements. Ne pas utiliser `docker compose down -v` pour une mise à jour.

`bin/backup create-production` exporte les quatre bases avec `pg_dump`, copie les fichiers et crée un manifeste SHA-256. Arrêter les écritures et le worker pendant la sauvegarde. Sur l’hôte, préparer un dossier `backups` accessible à l’UID/GID **1000**, utilisé par l’image Rails, puis :

```sh
docker compose stop web jobs
docker compose run --rm --no-deps -e SEOS_WRITERS_STOPPED=1 \
  -v "$PWD/backups:/backups" web \
  bin/backup create-production /rails/storage /backups/instantane
docker compose start web jobs
```

Choisir un nouveau dossier pour chaque instantané et copier les sauvegardes hors de l’hôte. Les commandes suivantes vérifient une sauvegarde et préparent une copie de restauration sans écraser une base active :

```sh
bin/backup verify DOSSIER
bin/backup restore SOURCE NOUVEAU_DOSSIER
```

Pour restaurer réellement : créer quatre bases vides compatibles, charger chaque archive `primary.dump`, `cache.dump`, `queue.dump` et `cable.dump` avec `pg_restore --no-owner --no-privileges --dbname=BASE ARCHIVE.dump`, restaurer le dossier `storage` avec l’UID/GID 1000 et remettre les secrets d’origine. Relancer ensuite `db:prepare`, le web et le worker. Le marqueur d’initialisation est sauvegardé avec la base principale.

Le client PostgreSQL est inclus dans l’image. Les commandes SQLite de `bin/backup` restent disponibles pour les données locales. Les migrations qui retirent les anciennes protections SQL sont irréversibles : garder une sauvegarde avant une mise à niveau réelle. Une montée de version majeure de PostgreSQL demande une migration dédiée.

## Documentation complémentaire

Les documents de conception et suivis de livraison se trouvent dans [`docs/`](docs/README.md). Le présent README décrit les commandes et parcours de la version actuelle. Les réglages métier, contenus légaux et identifiants des services externes doivent être renseignés pour l’instance exploitée.
