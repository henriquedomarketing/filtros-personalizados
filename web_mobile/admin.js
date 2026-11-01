import { initializeApp, deleteApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import { getAuth, createUserWithEmailAndPassword, signOut } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';
import { getDocs, query, collection, where, doc, getDoc, setDoc, updateDoc, arrayUnion } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';
import { getStorage, ref as storageRef, uploadBytes, getDownloadURL, deleteObject } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-storage.js';

// Admin UI alone is not security. Database/Storage rules MUST authorize changes.
export function mountAdmin({ firebaseConfig, auth, db, state, view, toast }) {
  const $ = id => document.getElementById(id);
  const storage = getStorage();
  let companies = [], pngBlob = null, pngUrl = null, busy = false;

  const requireAdmin = () => {
    if (!state.company?.admin || auth.currentUser?.uid !== state.company.uid)
      throw Error('Esta operação exige um administrador autenticado.');
  };
  function message(text, error=false) {
    const el=$('adminNotice');
    el.textContent=text;
    el.classList.remove('hidden');
    el.classList.toggle('error-notice',error);
    if (!error) toast(text);
  }
  function adminError(e) {
    console.error(e);
    const c=e?.code||'';
    if(c.includes('permission-denied')||c.includes('unauthorized')) return 'O Firebase bloqueou a operação. Verifique as regras de acesso do administrador.';
    if(c.includes('email-already-in-use'))return 'Este e-mail já tem um cadastro.';
    if(c.includes('weak-password'))return 'Senha muito fraca. Escolha uma mais forte.';
    if(c.includes('invalid-email'))return 'E-mail inválido.';
    if(c.includes('operation-not-allowed'))return 'Habilite login por e-mail/senha no Firebase Authentication.';
    if(c.includes('network-request-failed'))return 'Sem conexão com a internet.';
    return 'Não foi possível concluir. Confira a configuração do Firebase.';
  }
  function setBusy(v){
    busy=v;
    for(const id of ['adminCreateUserBtn','adminSaveCategoryBtn','adminUploadFilterBtn']) $(id).disabled=v;
  }
  function categories(company){
    return [...new Set([...(Array.isArray(company?.categories)?company.categories:[]),...(company?.filters||[]).map(f=>f.category)].filter(x=>typeof x==='string'&&x.trim()))];
  }
  function tab(name){
    for(const section of ['overview','company','category','filter'])
      $('admin'+section.charAt(0).toUpperCase()+section.slice(1)).classList.toggle('hidden',section!==name);
    $('adminNotice').classList.add('hidden');
    if(name==='category'||name==='filter') refresh().catch(e=>message(adminError(e),true));
  }
  async function refresh(preferUid=''){
    requireAdmin();
    const snaps=await getDocs(query(collection(db,'users'),where('admin','==',false)));
    companies=snaps.docs.map(s=>({...s.data(),uid:s.id})).sort((a,b)=>String(a.name).localeCompare(String(b.name),'pt-BR'));
    $('adminCompanyCount').textContent=String(companies.length);
    for(const select of [$('adminCategoryCompany'),$('adminFilterCompany')]){
      const before=preferUid||select.value;
      select.replaceChildren(new Option('Selecione uma empresa',''));
      for(const co of companies)select.add(new Option(co.name||co.login||co.uid,co.uid));
      if(companies.some(c=>c.uid===before))select.value=before;
    }
    const list=$('adminCompanyList');list.replaceChildren();
    for(const co of companies){
      const button=document.createElement('button');button.type='button';button.className='company-row';
      const data=document.createElement('span'),name=document.createElement('strong'),note=document.createElement('small');
      name.textContent=co.name||co.uid;note.textContent=(co.login||'')+' · '+(co.filters||[]).length+' filtro(s)';
      data.append(name,note);
      const action=document.createElement('span');action.textContent='Gerenciar ›';
      button.append(data,action);
      button.addEventListener('click',()=>{tab('filter');$('adminFilterCompany').value=co.uid;updateFilterView();});
      list.append(button);
    }
    if(!companies.length){const p=document.createElement('p');p.className='muted';p.textContent='Nenhuma empresa cadastrada ou acessível.';list.append(p);}
    updateFilterView();
  }
  function updateFilterView(){
    const co=companies.find(c=>c.uid===$('adminFilterCompany').value);
    const select=$('adminFilterCategory'),before=select.value;
    select.replaceChildren(new Option('Selecione uma categoria',''));
    for(const cat of categories(co))select.add(new Option(cat,cat));
    if([...select.options].some(o=>o.value===before))select.value=before;
    const filters=co?.filters||[];
    $('adminFilterCount').textContent=String(filters.length)+' filtro(s) cadastrado(s)';
    const gallery=$('adminExistingFilters');gallery.replaceChildren();
    for(const f of filters){
      const tile=document.createElement('div');tile.className='admin-filter-tile';
      const img=document.createElement('img');img.src=f.url;img.alt=f.name||'Filtro';
      const block=document.createElement('div'),name=document.createElement('strong'),detail=document.createElement('small');
      name.textContent=f.name||'Filtro';detail.textContent=f.category||'Sem categoria';
      block.append(name,detail);tile.append(img,block);gallery.append(tile);
    }
  }
  async function createCompany(e){
    e.preventDefault();if(busy)return;requireAdmin();
    const name=$('adminCompanyName').value.trim(),email=$('adminCompanyEmail').value.trim().toLowerCase(),password=$('adminCompanyPassword').value;
    if(!name||!email||password.length<8){message('Informe nome, e-mail e senha com pelo menos 8 caracteres.',true);return;}
    setBusy(true);
    let childApp=null,createdUid=null;
    try{
      // Secondary Firebase app keeps the administrator logged in while creating the client.
      childApp=initializeApp(firebaseConfig,'new-company-'+Date.now());
      const childAuth=getAuth(childApp);
      const created=await createUserWithEmailAndPassword(childAuth,email,password);
      createdUid=created.user.uid;
      // Must be protected by Firestore security rules against non-admin writes.
      await setDoc(doc(db,'users',createdUid),{uid:createdUid,name,login:email,admin:false,categories:[],filters:[]});
      await signOut(childAuth);
      $('adminCreateCompanyForm').reset();
      await refresh(createdUid);
      $('adminCategoryCompany').value=createdUid;
      $('adminFilterCompany').value=createdUid;
      updateFilterView();
      tab('category');
      message('Empresa cadastrada! Crie uma categoria para ela.');
    }catch(error){
      if(createdUid)message('Login criado, mas o cadastro da empresa foi bloqueado. NÃO tente criar a mesma conta novamente. UID: '+createdUid+'. Verifique regras de acesso.',true);
      else message(adminError(error),true);
    }finally{
      if(childApp)try{await deleteApp(childApp);}catch(e){console.warn(e);}
      setBusy(false);
    }
  }
  async function createCategory(e){
    e.preventDefault();if(busy)return;requireAdmin();
    const uid=$('adminCategoryCompany').value,category=$('adminNewCategory').value.trim();
    if(!uid||!category||category.length>80){message('Escolha uma empresa e uma categoria com até 80 caracteres.',true);return;}
    const co=companies.find(c=>c.uid===uid);
    if(categories(co).some(c=>c.toLocaleLowerCase('pt-BR')===category.toLocaleLowerCase('pt-BR'))){message('Essa categoria já existe.',true);return;}
    setBusy(true);
    try{
      await updateDoc(doc(db,'users',uid),{categories:arrayUnion(category)});
      $('adminNewCategory').value='';
      await refresh(uid);
      $('adminFilterCompany').value=uid;updateFilterView();
      $('adminFilterCategory').value=category;
      tab('filter');
      message('Categoria salva! Agora envie um PNG para ela.');
    }catch(error){message(adminError(error),true);}
    finally{setBusy(false);}
  }
  async function normalizePng(file){
    if(!file||file.type!=='image/png')throw Error('Selecione um PNG transparente.');
    if(file.size>12*1024*1024)throw Error('O arquivo deve ter até 12 MB.');
    const url=URL.createObjectURL(file);
    try{
      const image=await new Promise((resolve,reject)=>{
        const i=new Image();i.onload=()=>resolve(i);i.onerror=()=>reject(Error('PNG inválido.'));i.src=url;
      });
      const canvas=document.createElement('canvas');canvas.width=1080;canvas.height=1920;
      const ctx=canvas.getContext('2d',{willReadFrequently:true});
      ctx.clearRect(0,0,1080,1920);ctx.drawImage(image,0,0,1080,1920);
      const data=ctx.getImageData(0,0,1080,1920).data;
      let hasOpaque=false,hasTransparent=false;
      for(let i=3;i<data.length;i+=4*20){if(data[i]>10)hasOpaque=true;if(data[i]<245)hasTransparent=true;if(hasOpaque&&hasTransparent)break;}
      if(!hasOpaque)throw Error('O PNG parece vazio, sem elementos visíveis.');
      if(!hasTransparent)throw Error('PNG sem transparência: retire o fundo antes de enviar.');
      const blob=await new Promise((resolve,reject)=>canvas.toBlob(b=>b?resolve(b):reject(Error('Não foi possível preparar PNG.')),'image/png'));
      return {blob,width:image.naturalWidth,height:image.naturalHeight};
    }finally{URL.revokeObjectURL(url);}
  }
  $('adminFilterPng').addEventListener('change',async e=>{
    pngBlob=null;
    $('adminPngPreview').classList.add('hidden');
    if(pngUrl){URL.revokeObjectURL(pngUrl);pngUrl=null;}
    const file=e.target.files?.[0];if(!file)return;
    try{
      const result=await normalizePng(file);pngBlob=result.blob;
      pngUrl=URL.createObjectURL(result.blob);
      $('adminPngPreview').src=pngUrl;$('adminPngPreview').classList.remove('hidden');
      $('adminPngInfo').textContent=result.width+' × '+result.height+' → 1080 × 1920 · PNG transparente';
      if(result.width!==1080||result.height!==1920)toast('PNG ajustado para 1080 × 1920. Confira a prévia.');
    }catch(error){$('adminFilterPng').value='';$('adminPngInfo').textContent='Arquivo PNG transparente obrigatório.';message(error.message,true);}
  });
  async function uploadFilter(e){
    e.preventDefault();if(busy)return;requireAdmin();
    const uid=$('adminFilterCompany').value,category=$('adminFilterCategory').value,name=$('adminFilterName').value.trim();
    const co=companies.find(c=>c.uid===uid);
    if(!co||!categories(co).includes(category)||!name||!pngBlob){message('Escolha empresa, categoria, nome e PNG transparente.',true);return;}
    setBusy(true);
    let reference=null,uploaded=false;
    try{
      // Original Flutter app uses the "filtros" folder in Firebase Storage.
      reference=storageRef(storage,'filtros/'+uid+'_'+Date.now()+'_'+Math.random().toString(36).slice(2,8)+'.png');
      await uploadBytes(reference,pngBlob,{contentType:'image/png'});uploaded=true;
      const url=await getDownloadURL(reference);
      await updateDoc(doc(db,'users',uid),{filters:arrayUnion({name,category,url})});
      $('adminUploadFilterForm').reset();pngBlob=null;
      if(pngUrl){URL.revokeObjectURL(pngUrl);pngUrl=null;}
      $('adminPngPreview').classList.add('hidden');
      $('adminPngInfo').textContent='PNG transparente · 1080 × 1920 recomendado';
      await refresh(uid);
      message('Filtro publicado para '+co.name+'! O cliente pode atualizar o site e usar.');
    }catch(error){
      if(uploaded&&reference)try{await deleteObject(reference);}catch(e){console.warn('Upload não removido',e);}
      message(adminError(error),true);
    }finally{setBusy(false);}
  }
  $('adminOpenCompany').addEventListener('click',()=>tab('company'));
  $('adminOpenCategory').addEventListener('click',()=>tab('category'));
  $('adminOpenFilter').addEventListener('click',()=>tab('filter'));
  document.querySelectorAll('[data-admin-back]').forEach(el=>el.addEventListener('click',()=>{if(!busy)tab('overview');}));
  $('adminRefreshCompanies').addEventListener('click',async()=>{try{await refresh();message('Empresas atualizadas.');}catch(e){message(adminError(e),true);}});
  $('adminCreateCompanyForm').addEventListener('submit',createCompany);
  $('adminCreateCategoryForm').addEventListener('submit',createCategory);
  $('adminUploadFilterForm').addEventListener('submit',uploadFilter);
  $('adminFilterCompany').addEventListener('change',updateFilterView);
  return {show:async()=>{requireAdmin();view('adminView');tab('overview');try{await refresh();}catch(e){message(adminError(e),true);}}};
}
