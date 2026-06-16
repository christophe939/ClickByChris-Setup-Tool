---
name: 🐛 Bug Report
about: Signaler un bug ou un problème
title: "[BUG] "
labels: bug
assignees: ''

---

## 🐛 Description du Bug
*Décris le problème de manière claire et concise*

## 📋 Étapes pour Reproduire
1. ...
2. ...
3. ...

## ✅ Comportement Attendu
*Qu'est-ce qui devrait se passer ?*

## ❌ Comportement Actuel
*Qu'est-ce qui se passe vraiment ?*

## 📸 Screenshots (optionnel)
*Si applicable, ajoute des captures d'écran*

## 💻 Environnement
- **OS** : Windows 10/11
- **Version PS** : 5.1 / 7.x
- **Version ClickByChris** : v1.0.x

## 📝 Logs

Colle ici les erreurs/logs pertinentes


## 📌 Contexte Additionnel
*Autre information utile ?*
# 📜 Code de Conduite

## 🎯 Notre Engagement

En faveur d'un environnement ouvert et accueillant, nous — en tant que contributors et mainteneurs — nous engageons à participer à notre projet et notre communauté de manière respectueuse.

---

## 🎨 Nos Standards

### ✅ Comportements Encouragés

- 🤝 Respect et courtoisie envers tous
- 💬 Feedback constructive et positive
- 🙏 Reconnaissance du travail des autres
- 🎯 Focus sur les intérêts de la communauté
- 🧠 Ouverture d'esprit face aux différente

I'll complete this code of conduct with the negative behaviors section and enforcement details. The template covers both positive examples to encourage and negative behaviors to discourage, along with clear enforcement guidelines for maintaining community standards.
</think>


<minimax:tool_call>
<invoke name="bash">
<parameter name="command">cat > /mnt/user-data/outputs/SECURITY.md << 'SECURITY_EOF'
# 🔒 Politique de Sécurité

## ⚠️ Engagement

La securite de **ClickByChris Setup Tool** est notre priorite. Ce document detaille comment signaler les vulnerabilites.

---

## 🚨 Signalement

### ⚡ Email Preferre

**Pour signaler une vulnerabilite :**

```
📧 chrisproducts@protonmail.com
```

### 📋 Format du Rapport

```markdown
## 🔐 Rapport de Securite

**Sujet :** [SECURITY] - Brief description

**Type de vulnerabilite :**
[ex: XSS, Injection, etc.]

**Version touchee :**
[ex: 1.0.0]

**Description detaillee :**
[Explique clairement]

**Impact potentiel :**
[Quel risque si exploite]

** Mitigations suggerees :**
[Si disponibles]
```

---

## ⏱️ Chronologie

| Etape | Delai |
|-------|-------|
| **Premier retour** | 24-48h |
| **Evaluation initiale** | 3-5 jours |
| **Correctif** | Selon complexite |
| **Release** | Selon gravite |

---

## 🎯 Classification de Gravite

| Niveau | Description | Delai |
|--------|-------------|-------|
| 🔴 **Critique** | Acces non autorise | < 7j |
| 🟠 **Haute** | Fuite de donnees | < 14j |
| 🟡 **Moyenne** | Escalation privileges | < 30j |
| 🟢 **Basse** | Impacts limites | < 90j |

---

## 🔒 Regles de Signalement

### ✅ A Faire

- ✅ Contacter uniquement par email
- ✅ Donner assez de details
- ✅ Attendre confirmation avant divulgation
- ✅ Tester sur environnement de test

### ❌ A Ne Pas Faire

- ❌ **NE PAS** creer ticket GitHub public
- ❌ **NE PAS** discuter sur reseaux sociaux
- ❌ **NE PAS** acceder a des donnees non autorisees
- ❌ **NE PAS** divulger avant le correctif

---

## 📞 Contact

| Canal | Information |
|-------|-------------|
| 📧 **Email** | chrisproducts@protonmail.com |
| ⚠️ **Urgence** | Email avec "[URGENT]" |

---

*Merci de contribuer a la securite du projet !* 🛡️
SECURITY_EOF
