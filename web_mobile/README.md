# Camera Marketing Web (MVP)

Versão **web mobile** (site/PWA) independente do aplicativo Android/iOS. Abre no Safari/Chrome com **HTTPS**, sem instalação por loja.

## Nesta primeira versão
- Login com as credenciais existentes no **Firebase Authentication**
- Leitura somente de \`users/{uid}\` do **Cloud Firestore** (mesmo cadastro de empresa, categorias e filtros)
- Câmera frontal e traseira, quando o navegador autorizar (via \`getUserMedia\`)
- Seleção de filtro PNG em sobreposição, fotografia ou importação da galeria
- Composição centralizada (crop 9:16) e exportação PNG **1080×1920**
- Download e compartilhamento nativo quando suportados pelo navegador
- Manifest para adicionar atalho na tela inicial

**Ainda não incluído:** gravação/processamento de vídeo, painel administrativo web, salvar direto na galeria do iOS em todos os navegadores, funcionamento offline completo. O aplicativo nativo original permanece inalterado.

## Executando para desenvolvimento

Sirva os arquivos em \`web_mobile/\` por um servidor HTTP(S). Em produção, **HTTPS é obrigatório** para acesso à câmera; o navegador também permite \`localhost\` como exceção de desenvolvimento. Exemplo:

\`\`\`sh
cd web_mobile
python3 -m http.server 8080
\`\`\`

Use \`http://localhost:8080\` no computador. Para testar a câmera no celular, publique em HTTPS; abrir um \`http://192.168...\` local pode impedir a câmera.

Não use \`file://\` para abrir \`index.html\`. O projeto consome os módulos oficiais do Firebase hospedados em gstatic.com e exige internet.

## Implantação no Firebase Hosting — site separado

Para **não sobrescrever** uma aplicação/site já publicado no projeto Firebase, use um site de Hosting independente:

1. Faça login com uma conta autorizada no projeto Firebase \`cameramarketing-91d5a\`: \`firebase login\`
2. Crie um novo site Firebase Hosting no console (ou \`firebase hosting:sites:create ID_DO_NOVO_SITE --project cameramarketing-91d5a\`). O ID precisa ser único e disponível.
3. Associe o site ao target \`cameraMarketingWeb\`:

   \`\`\`sh
   firebase target:apply hosting cameraMarketingWeb ID_DO_NOVO_SITE --project cameramarketing-91d5a
   \`\`\`

4. Da raiz do repositório, faça deploy **apenas** do target web:

   \`\`\`sh
   firebase deploy --only hosting:cameraMarketingWeb --config firebase.web-mobile.json --project cameramarketing-91d5a
   \`\`\`

A URL do site será fornecida pelo Firebase Hosting. **Este branch não está publicado automaticamente.** O target impede publicar inadvertidamente no Hosting default.

## Firebase e segurança
- A configuração Firebase em \`app.js\` é a **configuração pública de cliente web**, já presente em \`lib/firebase_options.dart\`; não é uma credencial administrativa.
- Verifique as regras Firestore: cada conta de loja deve poder ler **somente** \`users/{seu uid}\`, e administradores devem ter escopo autorizado. Evite abrir leitura/escrita geral em \`users/\`.
- Os filtros PNG têm URLs do Firebase Storage. O navegador precisa permitir carregar essas imagens **com CORS** para gerar um PNG sem canvas contaminado. Se aparecer erro de CORS, configure CORS do bucket usado e verifique as permissões de leitura dos arquivos; não remova \`crossorigin=anonymous\`.
- **Não** exponha chaves de conta de serviço/arquivos \`.env\` em \`web_mobile\`. O código web não utiliza função administrativa de criação de empresas.
- Inclua o domínio personalizado em **Authentication > Settings > Authorized domains** se o Firebase Authentication exigir.
- Se o projeto tiver regras que exigem fluxo adicional de autenticação ou App Check, adapte o site antes de disponibilizar ao público.

## Compatibilidade e limitações
- Safari iOS e Chrome Android modernos em HTTPS, com câmera autorizada. Trocar câmera depende do hardware, SO e navegador.
- A exportação funciona via download; no iOS pode ir para Arquivos/Downloads em vez da galeria, dependendo da ação do usuário e do navegador.
- O compartilhamento por Web Share API aparece apenas quando suportado.
- No desktop, é possível subir foto mesmo sem webcam. A foto de saída é sempre 9:16, centro recortado.
- Para processamento de vídeo, há um backend FFmpeg existente em \`functions/src/index.ts\`, mas o fluxo web requer implementação, validação de upload e autorização antes de ser exposto.

## Proximidade com a base Flutter original
Esta versão é uma **implementação HTML/CSS/JS separada**: não compila automaticamente todo o Flutter existente para web, pois \`dart:io\`, gerenciador de arquivos e armazenamento nativo em \`lib/screens/camera.dart\`, \`lib/services/company_service.dart\` e \`lib/utils.dart\` são incompatíveis com uso direto no navegador. Os dados de login, lojas e filtros são compartilhados pelo mesmo Firebase.

### Checklist de aceitação
- [ ] Entrar no site via Safari iPhone e Chrome Android em HTTPS
- [ ] Autenticar loja real e confirmar categorias/filtros
- [ ] Permitir câmera e fotografar com o filtro correto
- [ ] Importar foto da galeria e compor a imagem
- [ ] Baixar/compartilhar PNG e conferir transparência/alinhamento
- [ ] Validar Firestore/Storage rules e CORS
- [ ] Testar lente frontal/traseira e falhas de permissão
- [ ] Validar instalação por atalho na tela inicial

### Próximas etapas
1. Painel administrativo no navegador e marca/ícone definitivos.
2. Captura/processamento de vídeo com filtros (reutilizando backend, após revisão de segurança).
3. Atalhos para empresas, domínio próprio e testes multidevice.
