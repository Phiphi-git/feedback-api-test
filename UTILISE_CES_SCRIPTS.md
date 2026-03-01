# GUIDE SIMPLE - Utilise CES scripts

Oups! Les anciens scripts avaient des problemes d'encodage avec les caracteres speciaux (emojis).

J'ai cree de NOUVEAUX scripts qui marchent correctement. Utilise CEUX-CI:

---

## UTILISE CES 3 SCRIPTS (NON les anciens)

### ETAPE 1: Ouvre PowerShell

Ouvre l'Explorateur Windows et va au dossier:

```
C:\Users\HP\Downloads\feedback-api-test
```

Puis tape dans la barre d'adresse: `powershell` et appuie sur Entree.

### ETAPE 2: Lance le premier script

Tape cette commande:

```powershell
.\train-ml-model-simple.ps1
```

Attends ~2 minutes.

### ETAPE 3: Lance le deuxieme script (optionnel)

Tape:

```powershell
.\test-local-simple.ps1
```

Attends ~3-5 minutes (ou 30 secondes si Docker est deja chaud).

### ETAPE 4: Lance le troisieme script

Tape (remplace 294468132567 par TON Project ID):

```powershell
.\deploy-to-cloud-simple.ps1 -ProjectId 294468132567
```

Attends ~10-15 minutes.

---

## NOUVEAUX SCRIPTS

Voici les fichiers a utiliser:

1. `train-ml-model-simple.ps1` <- UTILISE CELUI-CI
2. `test-local-simple.ps1` <- UTILISE CELUI-CI  
3. `deploy-to-cloud-simple.ps1` <- UTILISE CELUI-CI

(Les anciens scripts avec emojis ne marchent pas - ignore-les)

---

## TU DOIS AVOIR

- Python 3.x installe
- Docker Desktop actif
- gcloud CLI installe (pour le deploiement)
- Ton Project ID Google Cloud

---

## C'EST TOUT

Les 3 scripts font tout le travail. Toi tu as juste a les lancer dans l'ordre.
