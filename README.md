# Simulation IoT d’une ligne de bouteilles avec Node-RED

Simulation interactive d’une ligne de production en HTML/SVG, avec supervision des données dans un dashboard Node-RED pleine page.

La ligne simule le parcours **Source → Emballage → Contrôle qualité → Comptage → Tri**. Le navigateur envoie un instantané des indicateurs à Node-RED chaque seconde.

## Fichiers du projet

| Fichier | Utilisation |
| --- | --- |
| [SimulationTest.html](SimulationTest.html) | Simulateur à ouvrir dans le navigateur |
| [node-red-flow.json](node-red-flow.json) | Flow final complet à importer dans Node-RED, dashboard inclus |
| [node-red-dashboard-template.html](node-red-dashboard-template.html) | Copie du template pour personnaliser l’affichage |

Le fichier HTML du dashboard utilise AngularJS : il doit être placé dans un nœud `ui_template`. L’import du JSON suffit pour une première installation ; le template y est déjà intégré.

## Prérequis

- Node-RED installé et démarré, accessible par défaut sur `http://localhost:1880`.
- Le module **node-red-dashboard**, version **3.6.6** utilisée dans le flow fourni. Dans Node-RED, ouvrir **☰ → Gérer la palette → Installer**, rechercher `node-red-dashboard` et installer le module s’il manque.
- Un navigateur récent prenant en charge CSS `:has()` pour l’affichage pleine page.

Ce flow utilise le dashboard classique (`ui_template`, `ui_group`, `ui_tab`) et sa syntaxe AngularJS.

## Installation et démarrage

1. Télécharger ou cloner ce dépôt, puis démarrer Node-RED.
2. Ouvrir **http://localhost:1880**.
3. Désactiver ou supprimer tout ancien flow qui expose déjà `POST /api/telemetry` pour éviter les routes en double.
4. Ouvrir **☰ → Importer → sélectionner un fichier à importer**, choisir **node-red-flow.json**, puis cliquer sur **Importer**.
5. Cliquer sur **Déployer**. Si des nœuds sont inconnus, vérifier l’installation de `node-red-dashboard`.
6. Ouvrir **SimulationTest.html** dans le navigateur, puis cliquer sur **Démarrer**.
7. Vérifier le message **Node-RED : connecté** au-dessus de la simulation.
8. Ouvrir **http://localhost:1880/ui** pour consulter le dashboard **Bouteilles**. Le nœud Debug **Données reçues** affiche les mêmes indicateurs dans l’éditeur.

Le dashboard occupe toute la page et recouvre le menu de navigation du dashboard classique. Il défile verticalement sur les petits écrans. La touche **F11** permet également de masquer les barres du navigateur sur les systèmes qui la prennent en charge.

## Utilisation du simulateur

- **Démarrer** : lancer ou relancer la production.
- **Pause / Reprendre** : suspendre puis reprendre la ligne.
- **Stop** : arrêter la production.
- **Reset compteur** : remettre les compteurs et l’historique à zéro ; les bouteilles en cours restent sur la ligne.
- **Simuler une panne** : déclencher un arrêt machine.
- **Mode défi** : commencer une nouvelle simulation avec un objectif de 100 bouteilles conformes en 10 minutes.

Les curseurs règlent la vitesse du convoyeur, l’intervalle de création des bouteilles, les durées d’emballage et de contrôle, et la probabilité de défaut. La ligne déclenche une panne si le taux de rejet dépasse 30 % après au moins 5 passages. Les premiers passages apparaissent après le trajet jusqu’au poste de comptage.

## Indicateurs du dashboard

| Champ | Signification |
| --- | --- |
| `statut` | Arrêtée, en production, en pause ou en panne |
| `passages` | Nombre de bouteilles comptabilisées |
| `conformes` / `rejets` | Résultats du contrôle pour les bouteilles comptabilisées |
| `emballes` | Nombre de bouteilles dont l’emballage est terminé |
| `tauxDefaut` | Pourcentage de rejets parmi les passages |
| `produitsParMinute` | Nombre de passages sur les 60 dernières secondes |
| `vitesse` | Consigne du convoyeur en px/s, même si la ligne est arrêtée |
| `attenteEmballage` / `attenteControle` | Bouteilles dans les files d’attente, hors bouteille en traitement |
| `timestamp` | Date de réception ajoutée par Node-RED |

Les files deviennent orange à partir de 3 bouteilles en attente. L’envoi continue en pause ou à l’arrêt tant que la page reste ouverte ; un navigateur peut ralentir les temporisateurs des onglets en arrière-plan. Après fermeture du simulateur, le dashboard conserve les dernières valeurs : vérifier la date de réception.

## Communication avec Node-RED

```text
SimulationTest.html
  └─ POST /api/telemetry
       └─ Function « Valider et répondre »
            ├─ sortie 1 → ui_template + Debug
            └─ sortie 2 → HTTP Response
```

Le simulateur transmet du JSON avec `Content-Type: text/plain` pour éviter le prévol CORS lié au type `application/json`. La Function le décode avec `JSON.parse`, vérifie les valeurs numériques et conserve `msg.req` et `msg.res` pour répondre. Une réception valide retourne HTTP 200 avec `{"ok":true}` ; des données invalides retournent HTTP 400.

Le simulateur ne lance qu’une requête à la fois et abandonne une requête après 5 secondes. L’erreur est affichée sur la page et dans la console du navigateur. La réponse autorise les origines croisées avec `Access-Control-Allow-Origin: *` : cette configuration convient à une démonstration locale sans authentification et doit être adaptée avant exposition publique.

### Node-RED sur une autre machine

Dans `SimulationTest.html`, remplacer l’adresse de `fetch` :

```javascript
http://localhost:1880/api/telemetry
```

par l’adresse accessible depuis le navigateur, par exemple `http://192.168.1.10:1880/api/telemetry`. Ouvrir aussi le dashboard sur cette machine : `http://192.168.1.10:1880/ui`. Adapter le port ou le préfixe de chemin si la configuration Node-RED diffère. Une page du simulateur servie en HTTPS nécessite une URL Node-RED HTTPS pour éviter le blocage du contenu mixte.

## Personnaliser le dashboard

1. Modifier `node-red-dashboard-template.html`.
2. Copier tout son contenu dans le champ **Template** du nœud **Indicateurs ligne** (`ui_template`).
3. Cliquer sur **Terminé → Déployer**, puis recharger `/ui`.
4. Pour partager ces changements, exporter à nouveau le flow vers `node-red-flow.json` : modifier le fichier HTML seul ne met pas à jour le JSON.

## Dépannage

| Symptôme | Vérification |
| --- | --- |
| Aucun message dans Debug | Vérifier l’adresse dans `fetch`, le déploiement du flow et l’activation du nœud Debug |
| HTTP 404 | Vérifier la route `POST /api/telemetry` et l’absence de préfixe personnalisé |
| HTTP 400 | Vérifier que le flow contient `JSON.parse(data)` et que les compteurs sont des nombres positifs ou nuls |
| Délai dépassé | Vérifier que la sortie 2 de la Function rejoint HTTP Response et conserve le message HTTP original |
| Erreur réseau ou CORS | Vérifier le serveur, le port, les autorisations du navigateur, le type `text/plain` et les en-têtes de réponse |
| Dashboard vide ou nœuds inconnus | Vérifier `node-red-dashboard`, le groupe du template et la réception dans Debug |
| Ancienne interface affichée | Recharger avec Ctrl+F5 après le déploiement |

Dans les outils développeur du navigateur (**F12 → Réseau / Console**), le POST doit retourner HTTP 200. Pour tester indépendamment du navigateur, exécuter la commande suivante ; elle envoie des valeurs de démonstration qui apparaîtront dans le dashboard :

```sh
curl -i http://localhost:1880/api/telemetry \
  -H 'Content-Type: text/plain' \
  --data '{"passages":10,"conformes":9,"rejets":1,"emballes":12,"tauxDefaut":10,"produitsParMinute":10,"vitesse":90,"statut":"EN PRODUCTION","attenteEmballage":2,"attenteControle":1}'
```
