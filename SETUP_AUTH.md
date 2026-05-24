# Configuração de Autenticação Social

## Visão Geral

O app suporta login via **Google**, **GitHub**, **LinkedIn** e **Facebook**.  
Google, GitHub e Facebook usam **Firebase Authentication**.  
LinkedIn usa **OAuth2 PKCE** (sem backend necessário).

---

## PASSO 1 — Criar projeto Firebase

1. Acesse https://console.firebase.google.com
2. Clique **"Criar projeto"** → nome: `life-balance-tracker`
3. Desative o Google Analytics (opcional) → **Criar**

---

## PASSO 2 — Registrar app Web no Firebase

1. No painel do projeto → clique no ícone **`</>`** (Web)
2. Apelido do app: `life-balance-tracker-web`
3. Copie o objeto `firebaseConfig` que aparecer
4. Abra o arquivo `lib/firebase_options.dart` e substitua os valores:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSy...',          // ← apiKey
  appId: '1:123456:web:abc...',  // ← appId
  messagingSenderId: '123456789', // ← messagingSenderId
  projectId: 'life-balance-tracker',  // ← projectId
  authDomain: 'life-balance-tracker.firebaseapp.com',
  storageBucket: 'life-balance-tracker.appspot.com',
);
```

---

## PASSO 3 — Ativar provedores no Firebase

Vá em **Authentication → Sign-in method**:

### 🔵 Google
- Clique em **Google** → Ative
- Escolha o e-mail de suporte → **Salvar**

### 🐙 GitHub
1. Acesse https://github.com/settings/developers → **New OAuth App**
2. Application name: `Life Balance Tracker`
3. Homepage URL: `https://azuos01.github.io/life-balance-tracker/`
4. Authorization callback URL: `https://SEU_PROJETO.firebaseapp.com/__/auth/handler`
5. Copie o **Client ID** e **Client Secret**
6. No Firebase → GitHub → Cole Client ID + Secret → **Salvar**

### 📘 Facebook
1. Acesse https://developers.facebook.com → **Create App**
2. Use case: **Authenticate and request data from users**
3. Em **Facebook Login** → adicione plataforma Web
4. Site URL: `https://azuos01.github.io/life-balance-tracker/`
5. Copie **App ID** e **App Secret**
6. No Firebase → Facebook → Cole App ID + App Secret → **Salvar**
7. No painel Facebook → Adicione URI de redirecionamento OAuth:  
   `https://SEU_PROJETO.firebaseapp.com/__/auth/handler`

### 🔷 LinkedIn
1. Acesse https://www.linkedin.com/developers/apps → **Create app**
2. Nome: `Life Balance Tracker`
3. Em **Auth** → adicione Redirect URL:  
   `https://azuos01.github.io/life-balance-tracker/`
4. Em **Products** → solicite **Sign In with LinkedIn using OpenID Connect**
5. Copie o **Client ID** e abra `lib/services/auth_service.dart`:

```dart
const String _linkedInClientId = 'SEU_CLIENT_ID_AQUI';
```

> **Nota**: LinkedIn usa OAuth2 PKCE — não precisa de Client Secret nem backend.  
> A troca do code por token via `https://www.linkedin.com/oauth/v2/accessToken`  
> pode ter restrição de CORS no browser. Se ocorrer, use uma Firebase Function como proxy.

---

## PASSO 4 — Authorized domains no Firebase

Em **Authentication → Settings → Authorized domains**, adicione:
```
azuos01.github.io
```

---

## PASSO 5 — Deploy

```bash
git add lib/firebase_options.dart lib/services/auth_service.dart
git commit -m "config: Firebase Auth configurado"
git push
```

O GitHub Actions fará o deploy automaticamente.

---

## Teste rápido (sem configurar Firebase)

Use o **Modo Demo** na tela de login para testar o app sem configurar nenhum provedor.

---

## Solução de problemas

| Erro | Causa | Solução |
|------|-------|---------|
| `auth/invalid-api-key` | firebase_options.dart com valores placeholder | Substitua com config real |
| `auth/popup-closed-by-user` | Usuário fechou o popup | Normal — não é erro |
| `auth/operation-not-allowed` | Provedor não ativado no Firebase | Ative em Authentication → Sign-in method |
| `auth/unauthorized-domain` | Domínio não autorizado | Adicione em Authentication → Settings |
| LinkedIn CORS error | Browser bloqueia request ao token endpoint | Implemente Firebase Function proxy |
