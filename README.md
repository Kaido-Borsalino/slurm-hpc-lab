# KoReader → Anki

Transforme automatiquement tes annotations KoReader en cartes Anki **cloze** avec définitions, phonétique, traduction française et audio — grâce à Claude AI et Google Text-to-Speech.

![Python](https://img.shields.io/badge/Python-3.9+-blue)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

> Built by a Linux/HPC engineer learning English through reading — because the best tools are the ones you build yourself.

---

## Ce que ça fait

1. Tu lis sur ta liseuse, tu soulignes des mots et expressions
2. Tu glisses ton fichier `.lua` dans l'app
3. Claude génère automatiquement pour chaque expression :
   - Une phrase à trou (**cloze**) pour forcer le recall actif
   - Un indice vague pour aider sans trahir la réponse
   - La phonétique IPA
   - La définition en anglais
   - La traduction française
   - L'audio de prononciation (Google TTS)
4. Les cartes arrivent directement dans Anki, taguées par livre

---

## Prérequis

### 1. Clé API Anthropic
Utilisée pour générer les cartes (définition, cloze, phonétique, traduction).

1. Va sur [console.anthropic.com](https://console.anthropic.com)
2. **API Keys → Create Key**
3. Copie la clé (`sk-ant-...`)

> Coût estimé : ~0.01$ pour 100 cartes avec Claude Sonnet.

---

### 2. Clé API Google Text-to-Speech *(optionnel mais recommandé)*
Utilisée pour générer l'audio de **toutes** les expressions — y compris les phrases et expressions idiomatiques. Sans cette clé, seuls les mots simples auront de l'audio.

1. Va sur [console.cloud.google.com](https://console.cloud.google.com)
2. Crée un projet
3. Recherche **"Cloud Text-to-Speech API"** → **Activer**
4. **APIs & Services → Credentials → Create Credentials → API Key**
5. Copie la clé (`AIza...`)

> Coût : **gratuit jusqu'à 1 million de caractères/mois** (WaveNet). Ton usage réel sera de quelques milliers de caractères par livre — tu ne dépasseras probablement jamais le tier gratuit.

---

### 3. Anki + AnkiConnect
1. Installe [Anki](https://apps.ankiweb.net/)
2. Dans Anki : **Outils → Extensions → Parcourir et installer**
3. Entre le code `2055492159` → Redémarre Anki
4. Anki doit rester **ouvert** pendant la génération

---

## Installation (une seule fois)

```bash
git clone https://github.com/Kaido-Borsalino/koreader-anki.git
cd koreader-anki
bash install.sh
```

Un raccourci **KoReader Anki** apparaît sur ton Bureau. Double-clique pour lancer.

---

## Utilisation

1. Lance l'app depuis le Bureau
2. Entre ta **clé API Anthropic** (`sk-ant-...`)
3. Entre ta **clé Google TTS** (`AIza...`) — optionnel
4. Branche ta liseuse en USB → copie ton fichier `.lua` sur le Mac
5. Glisse le fichier dans l'app
6. Vérifie le nom du deck Anki
7. Clique **Générer les cartes**
8. Ouvre Anki — tes cartes sont là ✓

Les deux clés sont **sauvegardées automatiquement** — tu ne les entres qu'une seule fois.

---

## Formats supportés

| Format | Description |
|--------|-------------|
| `.lua` | Fichier metadata KoReader (annotations de livre) |
| `.lua` | `vocabulary_builder.lua` (constructeur de vocabulaire) |
| `.sqlite` | Base de données vocabulary builder |
| `.csv` | Export CSV avec colonne `word` |

---

## Structure des cartes Anki

**Recto** — La phrase avec le mot remplacé par un blanc + un indice vague

**Verso** — Le mot, sa phonétique, sa définition, la phrase complète avec le mot en évidence, la traduction française, l'audio

---

## Pipeline complet

```
Liseuse (lire + souligner)
    ↓ USB
fichier .lua sur le Mac
    ↓ KoReader Anki app
Claude génère les cartes
    ↓ AnkiConnect
Anki (révision SRS quotidienne)
    ↓ une fois par semaine
Session production sur Claude.ai
```

---

## Licence

MIT
