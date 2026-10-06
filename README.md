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
- Un broker MQTT local, par exemple **Mosquitto**, pour alimenter le dashboard par MQTT sur `localhost:1883`.
- Un navigateur récent prenant en charge CSS `:has()` pour l’affichage pleine page.

Ce flow utilise le dashboard classique (`ui_template`, `ui_group`, `ui_tab`) et sa syntaxe AngularJS.

## Installation et démarrage

1. Télécharger ou cloner ce dépôt, puis démarrer Node-RED.
2. Ouvrir **http://localhost:1880**.
3. Désactiver ou supprimer tout ancien flow de test si vous réimportez le projet.
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
  └─ MQTT over WebSocket ws://localhost:9001
       └─ topic ligne/bouteilles/telemetry
            └─ Broker Mosquitto
                 └─ Node-RED MQTT in « MQTT télémétrie bouteilles »
                      └─ Function « Valider MQTT »
                           └─ ui_template + Debug
```

Le simulateur transmet du JSON par MQTT. La Function **Valider MQTT** décode le message avec `JSON.parse`, vérifie les valeurs numériques, ajoute `timestamp`, puis envoie les données vers le dashboard et le debug.

### Tester avec MQTT

Le flow importé contient déjà un nœud **MQTT in** qui écoute le broker local `localhost:1883` sur le topic :

```text
ligne/bouteilles/telemetry
```

Sur Linux/Debian/Ubuntu, installer et démarrer Mosquitto :

```sh
sudo apt update
sudo apt install mosquitto mosquitto-clients
mosquitto -c mosquitto-websockets.conf -v
```

Cette commande lance un broker local de test avec deux ports : `1883` pour Node-RED et `9001` en WebSocket pour le simulateur HTML. Laissez ce terminal ouvert pendant la simulation.

Après import du flow et déploiement dans Node-RED, publier un message de test :

```sh
mosquitto_pub -h localhost -p 1883 -t ligne/bouteilles/telemetry -m '{"passages":10,"conformes":9,"rejets":1,"emballes":12,"tauxDefaut":10,"produitsParMinute":10,"vitesse":90,"statut":"EN PRODUCTION","attenteEmballage":2,"attenteControle":1}'
```

Le dashboard `/ui` et le debug **Données reçues** doivent afficher les valeurs reçues. Si le broker est sur une autre machine, modifier la configuration du broker dans le nœud **Broker MQTT local** et remplacer `localhost` par l’adresse IP du broker.

Important : dans MQTT, le broker ne crée pas les données lui-même. Un appareil, un script ou un simulateur publie les messages vers le broker ; Node-RED s’abonne au topic et reçoit ces messages.

### Node-RED ou broker sur une autre machine

Dans `SimulationTest.html`, remplacer l’adresse WebSocket :

```javascript
ws://localhost:9001
```

par l’adresse accessible depuis le navigateur, par exemple `ws://192.168.1.10:9001`. Dans Node-RED, modifier aussi la configuration du broker MQTT si Mosquitto n’est pas sur la même machine que Node-RED. Une page du simulateur servie en HTTPS nécessite une URL WebSocket sécurisée `wss://...` pour éviter le blocage du contenu mixte.

## Personnaliser le dashboard

1. Modifier `node-red-dashboard-template.html`.
2. Copier tout son contenu dans le champ **Template** du nœud **Indicateurs ligne** (`ui_template`).
3. Cliquer sur **Terminé → Déployer**, puis recharger `/ui`.
4. Pour partager ces changements, exporter à nouveau le flow vers `node-red-flow.json` : modifier le fichier HTML seul ne met pas à jour le JSON.

## Dépannage

| Symptôme | Vérification |
| --- | --- |
| Aucun message dans Debug | Vérifier Mosquitto, le topic `ligne/bouteilles/telemetry`, le déploiement du flow et l’activation du nœud Debug |
| MQTT in déconnecté | Vérifier que Mosquitto écoute sur `localhost:1883` et que le broker du nœud Node-RED pointe vers le bon hôte |
| Simulateur non connecté | Vérifier que Mosquitto écoute en WebSocket sur `ws://localhost:9001` |
| JSON MQTT invalide | Vérifier que le message publié est un objet JSON et que les compteurs sont des nombres positifs ou nuls |
| Erreur réseau navigateur | Vérifier le port WebSocket, l’adresse `ws://localhost:9001` et le chargement de MQTT.js |
| Dashboard vide ou nœuds inconnus | Vérifier `node-red-dashboard`, le groupe du template et la réception dans Debug |
| Ancienne interface affichée | Recharger avec Ctrl+F5 après le déploiement |

Pour tester indépendamment du navigateur, exécuter la commande suivante ; elle envoie des valeurs de démonstration qui apparaîtront dans le dashboard :

```sh
mosquitto_pub -h localhost -p 1883 -t ligne/bouteilles/telemetry -m '{"passages":10,"conformes":9,"rejets":1,"emballes":12,"tauxDefaut":10,"produitsParMinute":10,"vitesse":90,"statut":"EN PRODUCTION","attenteEmballage":2,"attenteControle":1}'
```
