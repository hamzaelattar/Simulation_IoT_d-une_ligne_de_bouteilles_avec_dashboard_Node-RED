# Simulation IoT d'une ligne de bouteilles avec dashboard Node-RED

Ce projet simule une ligne industrielle en SVG : génération de bouteilles, remplissage, emballage, contrôle qualité, comptage, traçabilité et tri des produits conformes ou rejetés.

Le dashboard Node-RED reçoit les mesures en temps réel et permet aussi de commander la simulation.

## Démarrage

Node-RED doit être installé :

```powershell
npm install -g node-red
```

Depuis PowerShell, dans le dossier du projet :

```powershell
powershell -ExecutionPolicy Bypass -File .\Start-NodeRED.ps1
```

Ouvrir ensuite :

- Dashboard : <http://127.0.0.1:1880/dashboard>
- Simulation seule : <http://127.0.0.1:1880/simulation>
- Éditeur Node-RED : <http://127.0.0.1:1880>

La simulation SVG est intégrée directement en bas du dashboard.

## Données affichées

- État de la ligne et état de connexion.
- Nombre total de passages, conformes et rejets.
- Taux de défaut et produits par minute.
- Nombre de bouteilles en circulation.
- État et files d'attente des machines.
- Dernier contrôle qualité et niveau de remplissage.
- Historique de traçabilité.
- Courbes de production et de taux de défaut.

## Commandes depuis le dashboard

- Démarrer, Pause, Stop et Reset.
- Simulation d'une panne.
- Vitesse du convoyeur.
- Cadence de la source.
- Temps d'emballage et de contrôle.
- Probabilité de défaut.

## API Node-RED

| Méthode | Route | Usage |
|---|---|---|
| `POST` | `/iot/telemetry` | Réception des mesures de la simulation |
| `GET` | `/iot/status` | Lecture du dernier état et des échantillons |
| `POST` | `/iot/command` | Envoi d'une commande depuis le dashboard |
| `GET` | `/iot/command` | Lecture de la commande par la simulation |
| `GET` | `/dashboard` | Dashboard de supervision |
| `GET` | `/simulation` | Simulation SVG |

Le flow importable se trouve dans `node-red/flows.json`.
