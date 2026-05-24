// ⚠️  CONFIGURAÇÃO NECESSÁRIA
//
// Antes de usar autenticação social, configure o Firebase:
//
// 1. Acesse https://console.firebase.google.com
// 2. Crie um projeto → "life-balance-tracker"
// 3. Adicione um app Web (ícone </>) e copie a config aqui
// 4. Em Authentication → Sign-in method, ative:
//    • Google → salve o Client ID
//    • GitHub → crie um GitHub OAuth App e cole o Client ID + Secret
//    • Facebook → crie um app em developers.facebook.com
// 5. Em Authentication → Settings → Authorized domains, adicione:
//    azuos01.github.io
//
// Substitua os valores abaixo com sua configuração real do Firebase.
// NÃO commite este arquivo com valores reais em repositórios públicos!
// Adicione-o ao .gitignore para segurança em produção.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'DefaultFirebaseOptions: plataforma não configurada.',
    );
  }

  // ↓ Substitua com os valores do seu projeto Firebase
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5-oasntAAWrPukeAEecgXXkyWiq2v47c',
    appId: '1:1018118891361:web:67b792d97435bd68098720',
    messagingSenderId: '1018118891361',
    projectId: 'life-balance-tracker-e2980',
    authDomain: 'life-balance-tracker-e2980.firebaseapp.com',
    storageBucket: 'life-balance-tracker-e2980.firebasestorage.app',
  );
}
