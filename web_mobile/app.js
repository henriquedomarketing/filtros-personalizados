import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getAuth, onAuthStateChanged, signInWithEmailAndPassword, signOut
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';
import {
  getFirestore, doc, getDoc
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';

// Public Firebase *client* configuration from lib/firebase_options.dart.
// Access control must be enforced by Firebase Auth, Firestore and Storage rules.
const firebaseConfig = {
  apiKey: 'AIzaSyBz7HN1me3Js8XOTeVD7zfTVLI9MUbMc3U',
  authDomain: 'cameramarketing-91d5a.firebaseapp.com',
  projectId: 'cameramarketing-91d5a',
  storageBucket: 'cameramarketing-91d5a.firebasestorage.app',
  messagingSenderId: '389801053746',
  appId: '1:389801053746:web:41d0d7c834d2dc1f1b762b'
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const $ = (id) => document.getElementById(id);
const state = {
  company: null,
  category: null,
  selectedFilter: null,
  overlayImage: null,
  stream: null,
  facingMode: 'environment',
  busy: false,
  resultBlob: null,
  resultUrl: null
};
let toastTimeout;

function toast(message) {
  const box = $('toast');
  box.textContent = message;
  box.classList.add('show');
  clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => box.classList.remove('show'), 4500);
}

function view(viewId) {
  ['loginView', 'categoryView', 'cameraView', 'resultView'].forEach((id) => {
    $(id).classList.toggle('hidden', id !== viewId);
  });
  $('logoutBtn').classList.toggle('hidden', !state.company);
  if (viewId !== 'cameraView') stopCamera();
  window.scrollTo({ top: 0, behavior: 'instant' });
}

function setBusy(busy) {
  state.busy = busy;
  $('loginBtn').disabled = busy;
  $('captureBtn').disabled = busy;
  $('downloadBtn').disabled = busy;
}

function friendlyError(error) {
  const code = error?.code || '';
  if (code.includes('invalid-credential') || code.includes('wrong-password') || code.includes('user-not-found')) {
    return 'E-mail ou senha inválidos.';
  }
  if (code.includes('too-many-requests')) return 'Muitas tentativas. Tente novamente mais tarde.';
  if (code.includes('network-request-failed')) return 'Sem conexão com a internet.';
  if (code.includes('permission-denied')) return 'Você não tem permissão para acessar estes dados.';
  return 'Não foi possível concluir a operação. Tente novamente.';
}

async function loadCompany(user) {
  setBusy(true);
  try {
    const snapshot = await getDoc(doc(db, 'users', user.uid));
    if (!snapshot.exists()) {
      throw new Error('Cadastro da empresa não encontrado no Firebase.');
    }
    const data = snapshot.data();
    state.company = {
      uid: user.uid,
      name: String(data.name || 'Sua empresa'),
      admin: data.admin === true,
      filters: Array.isArray(data.filters)
        ? data.filters.filter((f) => f && typeof f.category === 'string' && typeof f.url === 'string')
        : []
    };
    state.category = null;
    state.selectedFilter = null;
    state.overlayImage = null;
    $('companyName').textContent = state.company.name;
    $('loginError').textContent = '';
    if (state.company.admin) {
      toast('O painel administrativo web ainda não está incluído nesta primeira versão.');
    }
    renderCategories();
    view('categoryView');
  } catch (error) {
    console.error('Falha ao carregar empresa:', error);
    state.company = null;
    view('loginView');
    $('loginError').textContent = error.message?.includes('Cadastro')
      ? error.message
      : friendlyError(error);
  } finally {
    setBusy(false);
  }
}

onAuthStateChanged(auth, (user) => {
  if (user) {
    loadCompany(user);
  } else {
    state.company = null;
    state.category = null;
    state.selectedFilter = null;
    state.overlayImage = null;
    view('loginView');
  }
});

$('loginForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  setBusy(true);
  $('loginError').textContent = '';
  try {
    await signInWithEmailAndPassword(
      auth,
      $('email').value.trim(),
      $('password').value
    );
    $('password').value = '';
    // onAuthStateChanged loads the company and opens its categories.
  } catch (error) {
    $('loginError').textContent = friendlyError(error);
  } finally {
    setBusy(false);
  }
});

$('logoutBtn').addEventListener('click', async () => {
  stopCamera();
  try {
    await signOut(auth);
  } catch (error) {
    toast(friendlyError(error));
  }
});

function renderCategories() {
  const root = $('categoryList');
  root.replaceChildren();
  const categories = [...new Set(state.company.filters.map((f) => f.category))];
  if (!categories.length) {
    const empty = document.createElement('p');
    empty.textContent = 'Nenhuma categoria disponível para esta empresa.';
    root.appendChild(empty);
    return;
  }
  categories.forEach((category) => {
    const count = state.company.filters.filter((f) => f.category === category).length;
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'category-button';
    const name = document.createElement('span');
    name.textContent = category;
    const info = document.createElement('small');
    info.textContent = count === 1 ? '1 filtro' : count + ' filtros';
    const arrow = document.createElement('span');
    arrow.className = 'arrow';
    arrow.textContent = '›';
    button.append(name, info, arrow);
    button.addEventListener('click', () => openCategory(category));
    root.appendChild(button);
  });
}

async function openCategory(category) {
  state.category = category;
  state.selectedFilter = null;
  state.overlayImage = null;
  $('categoryTitle').textContent = category;
  $('filterOverlay').classList.add('hidden');
  renderFilters();
  view('cameraView');
  await startCamera();
}

function renderFilters() {
  const root = $('filterList');
  root.replaceChildren();
  const filters = state.company.filters.filter((f) => f.category === state.category);
  if (!filters.length) {
    const empty = document.createElement('p');
    empty.textContent = 'Nenhum filtro disponível.';
    root.appendChild(empty);
    return;
  }
  filters.forEach((filter, index) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'filter-item';
    button.setAttribute('aria-pressed', String(filter === state.selectedFilter));
    button.setAttribute('aria-label', filter.name?.trim() || 'Filtro ' + (index + 1));
    if (filter === state.selectedFilter) button.classList.add('selected');
    const image = document.createElement('img');
    image.src = filter.url;
    image.alt = '';
    image.loading = 'lazy';
    image.referrerPolicy = 'no-referrer';
    const name = document.createElement('span');
    name.textContent = filter.name?.trim() || 'Filtro ' + (index + 1);
    button.append(image, name);
    button.addEventListener('click', () => selectFilter(filter));
    root.appendChild(button);
  });
}

function loadImage(url, crossOrigin = false) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    if (crossOrigin) image.crossOrigin = 'anonymous';
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error('Imagem indisponível ou bloqueada pelo navegador.'));
    image.src = url;
  });
}

async function selectFilter(filter) {
  state.selectedFilter = filter;
  state.overlayImage = null;
  $('filterOverlay').classList.add('hidden');
  renderFilters();
  toast('Carregando filtro...');
  try {
    const image = await loadImage(filter.url, true);
    if (state.selectedFilter !== filter) return;
    state.overlayImage = image;
    $('filterOverlay').src = filter.url;
    $('filterOverlay').classList.remove('hidden');
  } catch (error) {
    console.error('Filtro indisponível:', error);
    if (state.selectedFilter === filter) {
      toast('Não foi possível carregar o filtro. Verifique permissões e CORS do Storage.');
    }
  }
}

async function startCamera() {
  stopCamera();
  if (!navigator.mediaDevices?.getUserMedia) {
    $('cameraPlaceholder').classList.remove('hidden');
    toast('Câmera indisponível neste navegador. Use a foto da galeria.');
    return;
  }
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: false,
      video: {
        facingMode: { ideal: state.facingMode },
        width: { ideal: 1920 },
        height: { ideal: 1080 }
      }
    });
    if ($('cameraView').classList.contains('hidden')) {
      stream.getTracks().forEach((track) => track.stop());
      return;
    }
    state.stream = stream;
    const video = $('cameraVideo');
    video.srcObject = stream;
    video.classList.toggle('mirrored', state.facingMode === 'user');
    await video.play();
    $('cameraPlaceholder').classList.add('hidden');
    $('activateCamera').classList.add('hidden');
  } catch (error) {
    console.error('Não foi possível abrir a câmera:', error);
    $('cameraPlaceholder').classList.remove('hidden');
    $('activateCamera').classList.remove('hidden');
    toast('Autorize o uso da câmera. Se necessário, use uma foto da galeria.');
  }
}

function stopCamera() {
  if (state.stream) state.stream.getTracks().forEach((track) => track.stop());
  state.stream = null;
  const video = $('cameraVideo');
  video.pause();
  video.srcObject = null;
  $('cameraPlaceholder').classList.remove('hidden');
  $('activateCamera').classList.remove('hidden');
}

$('activateCamera').addEventListener('click', startCamera);
$('switchCamera').addEventListener('click', async () => {
  state.facingMode = state.facingMode === 'user' ? 'environment' : 'user';
  await startCamera();
});
$('backToCategories').addEventListener('click', () => view('categoryView'));
$('backToCamera').addEventListener('click', async () => {
  view('cameraView');
  await startCamera();
});

function drawCover(ctx, source, width, height, mirror = false) {
  const sourceWidth = source.videoWidth || source.naturalWidth || source.width;
  const sourceHeight = source.videoHeight || source.naturalHeight || source.height;
  if (!sourceWidth || !sourceHeight) throw new Error('A imagem ainda não está pronta.');
  const sourceRatio = sourceWidth / sourceHeight;
  const destRatio = width / height;
  let cropX = 0, cropY = 0, cropWidth = sourceWidth, cropHeight = sourceHeight;
  if (sourceRatio > destRatio) {
    cropWidth = sourceHeight * destRatio;
    cropX = (sourceWidth - cropWidth) / 2;
  } else {
    cropHeight = sourceWidth / destRatio;
    cropY = (sourceHeight - cropHeight) / 2;
  }
  ctx.save();
  if (mirror) {
    ctx.translate(width, 0);
    ctx.scale(-1, 1);
  }
  ctx.drawImage(source, cropX, cropY, cropWidth, cropHeight, 0, 0, width, height);
  ctx.restore();
}

async function composeImage(source, mirror = false) {
  if (state.busy) return;
  if (!state.selectedFilter || !state.overlayImage) {
    toast('Selecione um filtro e aguarde o carregamento antes de continuar.');
    return;
  }
  setBusy(true);
  try {
    const canvas = document.createElement('canvas');
    canvas.width = 1080;
    canvas.height = 1920;
    const ctx = canvas.getContext('2d', { alpha: false });
    if (!ctx) throw new Error('Não foi possível criar a imagem.');
    drawCover(ctx, source, canvas.width, canvas.height, mirror);
    ctx.drawImage(state.overlayImage, 0, 0, canvas.width, canvas.height);
    const blob = await new Promise((resolve, reject) => {
      try {
        canvas.toBlob(
          (b) => b ? resolve(b) : reject(new Error('Não foi possível gerar o PNG.')),
          'image/png'
        );
      } catch (e) { reject(e); }
    });
    if (state.resultUrl) URL.revokeObjectURL(state.resultUrl);
    state.resultBlob = blob;
    state.resultUrl = URL.createObjectURL(blob);
    $('resultImage').src = state.resultUrl;
    view('resultView');
  } catch (error) {
    console.error('Erro ao gerar a foto:', error);
    if (error?.name === 'SecurityError') {
      toast('O Storage bloqueou a composição da imagem. Configure o CORS do bucket.');
    } else {
      toast('Não foi possível gerar a foto. Tente outra imagem.');
    }
  } finally {
    setBusy(false);
  }
}

$('captureBtn').addEventListener('click', () => {
  const video = $('cameraVideo');
  if (!state.stream || video.readyState < HTMLMediaElement.HAVE_CURRENT_DATA) {
    toast('Ative a câmera ou use uma foto da galeria.');
    return;
  }
  composeImage(video, state.facingMode === 'user');
});

$('photoInput').addEventListener('change', async (event) => {
  const file = event.target.files?.[0];
  event.target.value = '';
  if (!file) return;
  if (!file.type.startsWith('image/')) {
    toast('Selecione uma imagem válida.');
    return;
  }
  const objectUrl = URL.createObjectURL(file);
  try {
    const image = await loadImage(objectUrl);
    await composeImage(image);
  } catch (error) {
    console.error('Não foi possível importar a imagem:', error);
    toast('Não foi possível abrir a foto selecionada.');
  } finally {
    URL.revokeObjectURL(objectUrl);
  }
});

$('downloadBtn').addEventListener('click', () => {
  if (!state.resultUrl) return;
  const link = document.createElement('a');
  link.href = state.resultUrl;
  link.download = 'camera-marketing-' + Date.now() + '.png';
  document.body.appendChild(link);
  link.click();
  link.remove();
  toast('Download solicitado! Verifique seus arquivos ou downloads.');
});

$('shareBtn').addEventListener('click', async () => {
  if (!state.resultBlob) return;
  const file = new File([state.resultBlob], 'camera-marketing.png', { type: 'image/png' });
  try {
    if (navigator.canShare?.({ files: [file] })) {
      await navigator.share({ files: [file], title: 'Camera Marketing' });
    } else {
      toast('Compartilhamento direto não disponível. Use "Baixar foto".');
    }
  } catch (error) {
    if (error?.name !== 'AbortError') toast('Não foi possível compartilhar a imagem.');
  }
});
