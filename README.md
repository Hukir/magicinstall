Make it executable:
sudo chmod +x magicinstall.sh

Run it: 
./magicinstall.sh



# Cheat Sheet — Tchou Magic Installer

Référence rapide de tout ce que `magicinstall.sh` configure.

## Zsh — alias

| Alias | Action |
|---|---|
| `zconfig` | Ouvre `~/.zshrc` dans Neovim |
| `zreload` | Recharge `~/.zshrc` dans la session courante |
| `tconfig` | Ouvre `~/.tmux.conf` dans Neovim |
| `treload` | Recharge `~/.tmux.conf` dans la session tmux courante |
| `pypy`    | Active le virtualenv Python (`~/.venv`) — les deux font la même chose |


## Zsh — fonction

**`tname <nom>`** — change le nom affiché dans le prompt Starship et la barre tmux. Met à jour la variable pour la session en cours, patche `~/.zshrc` pour que ce soit permanent, et si tu es déjà dans tmux, met à jour la barre tout de suite (sans besoin de `treload`).

## Zsh — variables custom

| Variable | Valeur par défaut | Usage |
|---|---|---|
| `$tip` | `10.10.10.10` | Raccourci perso, à toi de t'en servir comme bon te semble |
| `$turl` | `domaine.com` | Idem |
| `$MY_TERM_NAME` | ce que tu as entré à l'installation | Nom affiché dans le prompt et la barre tmux |

## Zsh — plugins installés

| Plugin | Ce qu'il fait concrètement |
|---|---|
| **fzf** | `Ctrl+R` : recherche floue dans l'historique des commandes (remplace le `Ctrl+R` basique de zsh par une interface interactive). `Ctrl+T` : recherche floue de fichiers, insère le chemin choisi à l'endroit du curseur. `Alt+C` : recherche floue de dossiers et `cd` dedans directement |
| **zoxide** | Remplace/complète `cd` par la commande `z` — `z motcle` te saute dans un dossier déjà visité dont le nom contient "motcle", en se basant sur ta fréquence/récence de visite (pas besoin du chemin complet). `zi` ouvre une sélection interactive via fzf si plusieurs résultats correspondent |
| `zsh-autosuggestions` | Pendant que tu tapes, suggère en gris la fin de la commande basée sur ton historique — flèche droite (`→`) ou `End` pour l'accepter |
| `zsh-syntax-highlighting` | Colore la commande en temps réel : vert si elle existe/est valide, rouge si typo ou commande introuvable — avant même d'appuyer sur Entrée |
| `zsh-completions` | Ajoute des définitions de complétion (`Tab`) pour beaucoup plus d'outils que ce que zsh connaît par défaut |
| `fzf-tab` | Remplace le menu de complétion `Tab` classique par une interface fzf : tu peux taper pour filtrer les résultats au lieu de naviguer une liste figée |
| `you-should-use` | Si tu tapes une commande complète alors qu'un alias existant fait la même chose, t'envoie un rappel (ex : tu tapes `git status`, il te rappelle que `gst` existe si c'est aliasé) |
| `git` *(oh-my-zsh)* | Charge une grosse liste d'alias git (`gst`=`git status`, `gco`=`git checkout`, `gaa`=`git add --all`, `gp`=`git push`, etc.) |
| `docker` *(oh-my-zsh)* | Complétion `Tab` pour les sous-commandes et options Docker |
| `sudo` *(oh-my-zsh)* | Appuyer deux fois sur `Échap` rajoute `sudo ` devant la commande tapée (ou la précédente si la ligne est vide) |
| `command-not-found` *(oh-my-zsh)* | Si tu tapes une commande qui n'existe pas, suggère le paquet `apt install` qui la fournirait |
| `extract` *(oh-my-zsh)* | Une seule commande, `extract fichier.tar.gz` (ou `.zip`, `.rar`, etc.), qui détecte le format et décompresse, peu importe lequel |

Prompt : **Starship** (a remplacé Powerlevel10k, qui est en maintenance).

## Tmux

- **Préfixe : `Ctrl+a`** (pas le `Ctrl+b` par défaut)
- Souris activée (`mouse on`) — sélectionner du texte à la souris copie automatiquement vers le presse-papier système via **xclip**, si une session X11 est active (sinon ça ne fait juste rien, sans planter)
- Shell par défaut : zsh
- Barre de statut en haut, affiche l'heure et `$MY_TERM_NAME`

### Piège à connaître : le mode copie

Scroller avec la molette dans une pane fait automatiquement entrer tmux en **mode copie**. Dans ce mode, les touches ne vont plus au programme en cours :
- `Ctrl+C` n'envoie pas d'interruption, il **annule le mode copie** (comportement par défaut de tmux)
- Indice visuel : un repère de position en bas à droite de la pane
- Pour sortir : `q` ou `Échap`

## Neovim

- Build perso (AppImage, dernière version), pas le paquet apt
- Thème : **Catppuccin Mocha**
- Gestionnaire de plugins : **lazy.nvim**
- LSP : **pyright** (Python), complétion via nvim-cmp (`Tab`/`Enter` pour valider)
- Presse-papier : via **xclip**, auto-détecté par nvim si une session X11 est active (sinon nvim affiche juste un avertissement et utilise son registre interne, sans planter)
  - `p` / `y` en mode normal et visuel vont directement dans le registre système (`"+`)
  - Sélection à la souris (relâcher le clic en mode visuel) copie automatiquement
  - `Ctrl+V` en mode insertion colle depuis le presse-papier système (le `Ctrl+V` en mode normal reste le raccourci natif de sélection visuelle par bloc, inchangé)

## Python

`~/.venv` — activé via `pypy` ou `pyv`. Contient `pyright`, `black`, `ruff`.

## Docker

Installé depuis le dépôt officiel Docker (pas le paquet de la distro). Ton utilisateur est ajouté au groupe `docker` — **il faut se déconnecter/reconnecter** (ou redémarrer la session) pour que ça prenne effet sans avoir à utiliser `sudo` à chaque commande `docker`.

## Presse-papier (xclip + détection $DISPLAY)

Le script est pensé pour tourner sur n'importe quelle install Debian/Ubuntu/Kali, avec ou sans bureau graphique :
- Si une session X11 est active (`$DISPLAY` défini), `xclip` fait le lien avec le presse-papier système — souris dans tmux, `p`/`y`/`Ctrl+V` dans nvim, `Ctrl+V` dans zsh fonctionnent tous via le presse-papier réel
- Si pas de session X11 (machine headless, ou simple accès terminal), ces mécanismes ne font juste rien silencieusement — aucune erreur, aucun plantage, ils dégradent proprement
- `setxkbmap` a été entièrement retiré du script (il avait le même genre de dépendance à X11, et n'apportait rien sans bureau graphique)

## Si tu es sur Windows Terminal

Deux bugs/comportements à connaître :
- **`Ctrl+C` copie au lieu d'interrompre** s'il y a une sélection active dans le terminal — désactivable en ajoutant `{ "command": "unbound", "keys": "ctrl+c" }` dans `settings.json`
- **Bug confirmé de Windows Terminal avec le collage dans tmux** (marqueur de fin corrompu, bloque la session) — contourné en désactivant `zle_bracketed_paste` côté zsh. Contrepartie : un collage multi-lignes s'exécute ligne par ligne plutôt que d'être inséré tel quel

## Désinstallation

`magicuninstall.sh` retire tout ce qui précède. Il laisse volontairement intacts : `git`/`curl`/`python3-venv` (d'autres outils peuvent en dépendre), `~/journal` (peut contenir du vrai contenu), et `~/.zshrc.pre-oh-my-zsh` (ta sauvegarde d'origine, si elle existe).
