/* One Results document, four native captures, ack, cancellation and recovery. */
const fs=require('fs'),path=require('path'),assert=require('assert'),cp=require('child_process');
const {chromium}=require(process.env.MZRJ_PLAYWRIGHT);
const root=process.env.MZRJ_TEST_ROOT,work=process.env.MZRJ_TEST_WORK;
const core=process.env.MZRJ_CORE||path.resolve(root,'../jamovi-src');
const nativeResizeScript=require('./native_resize_browser.cjs')(core);
async function engine(folder,action,mode,prefix){
 await new Promise((resolve,reject)=>{
  const child=cp.spawn(process.env.MZRJ_RSCRIPT||'Rscript',['--vanilla',root+'/tests/barber_johnson_lifecycle.R',root,folder,action,mode,prefix]);
  let output='';child.stdout.on('data',v=>output+=v);child.stderr.on('data',v=>output+=v);
  child.on('error',reject);child.on('exit',code=>{fs.appendFileSync(work+'/ENGINE.log',output);if(code)reject(Error(output));else resolve();});
 });
 const state=JSON.parse(fs.readFileSync(folder+'/manifest.json','utf8'));
 if(typeof state.images==='string')state.images=[state.images];return state;
}
(async()=>{
 fs.mkdirSync(work,{recursive:true});
 const browser=await chromium.launch({headless:true,executablePath:process.env.MZRJ_CHROME});
 try{for(const prefix of (process.env.MZRJ_ONE_CASE?['Rj']:['Rj','Rjp']))for(const mode of (process.env.MZRJ_ONE_CASE?['bundled']:['bundled','external'])){
  const folder=work+'/'+prefix+'_'+mode, page=await browser.newPage({viewport:{width:1400,height:1100}}),errors=[],captures=[];
  page.on('pageerror',e=>errors.push(e.message));await page.route('**/*',r=>r.abort());
  await page.exposeFunction('reportCapture',(name,text)=>captures.push(JSON.parse(text)));
  await page.setContent('<script>window.setOption=(name,text)=>window.reportCapture(name,text);</script><main id="results"></main>');
  // The desktop loads this declared Html script resource separately.
  await page.addScriptTag({content:fs.readFileSync(root+'/inst/extdata/d3.min.js','utf8')});
  async function render(items){await page.evaluate(items=>{
   const host=document.getElementById('results');host.replaceChildren();
   for(const item of items){const node=document.createElement('div');node.className='jmv-results-html';node.dataset.name=item.name;node.innerHTML=item.content;host.append(node);}
   for(const old of host.querySelectorAll('script')){const s=document.createElement('script');s.textContent=old.textContent;document.head.append(s);s.remove();old.remove();}
  },items);}
  let state=await engine(folder,'init',mode,prefix);assert.equal(state.pending.length,4);await render(state.pending);
  await page.waitForFunction(()=>document.querySelectorAll('[data-mzrj-image-ready=true]').length===4);
  await page.waitForTimeout(200);
  assert.equal(captures.length,1,'only one PNG may be in flight');
  assert.ok((await page.locator('[data-image-status]').allTextContents()).every(v=>!v));
  const bytes=await page.evaluate(()=>Array.from(window.mzRjNativeImageQueue.entries.values()).reduce((s,v)=>s+v.content.length,0));
  assert.ok(bytes>1500000,'must exercise the formerly rejected aggregate size');
  let processed=0;
  while(state.pending.length){
   const deadline=Date.now()+15000;while(captures.length<=processed&&Date.now()<deadline)await new Promise(r=>setTimeout(r,20));
   assert.ok(captures.length>processed);const payload=captures[processed++];assert.equal(payload.images.length,1);
   assert.ok(JSON.stringify(payload).length<1100000);fs.writeFileSync(folder+'/capture.json',JSON.stringify(payload));
   const before=state.pending.length;state=await engine(folder,'capture',mode,prefix);
   assert.equal(state.pending.length,before-1);assert.equal(state.runs,1);assert.equal(state.tables,1);
   await page.evaluate(name=>{const node=Array.from(document.querySelectorAll('#results>div')).find(n=>n.dataset.name===name);node.replaceChildren(document.createTextNode('Native Image acknowledged'));},payload.images[0].name);
  }
  assert.equal(state.images.length,4);await page.waitForFunction(()=>window.mzRjNativeImageQueue.entries.size===0&&window.mzRjNativeImageQueue.ackTimers.size===0);
  const bases=structuredClone(state.imageDetails),tableData=structuredClone(state.tableData);
  await page.addStyleTag({content:fs.readFileSync(core+'/client/resultsview/main.css','utf8')});
  await page.addScriptTag({content:nativeResizeScript});
  await page.evaluate(details=>{
   window.resizeMessages=[];window.setParam=(address,values)=>window.resizeMessages.push({name:address[0],width:values.widthScale,height:values.heightScale});
   const host=document.getElementById('results');host.replaceChildren();
   details.forEach((v,i)=>{
    const owner=document.createElement('div');owner.className='jmv-results-image';owner.id='native-'+i;owner.tabIndex=0;
    const image=document.createElement('div');image.className='jmv-results-image-image';image.style.width=v.width+'px';image.style.height=v.height+'px';
    image.style.backgroundImage='url(data:image/png;base64,'+v.png+')';image.style.backgroundSize=v.width+'px';
    owner.append(image);host.append(owner);window.installNativeImageResize(owner,image,v);
   });
  },state.imageDetails.map(v=>({...v,png:fs.readFileSync(folder+'/resources/'+v.path).toString('base64')})));
  // Every release of a native Image grip sends only result width/height scales.
  for(const [index,scale]of [[0,[1.2,.85]],[1,[.8,1.15]],[2,[1.1,.9]],[3,[.9,.8]],[0,[1.4,1.1]],[0,[1,1]]]){
   const previous=structuredClone(state.imageDetails),name=bases[index].name;
   const owner=page.locator('#native-'+index);await owner.focus();const grip=owner.locator('.resize-handle');await grip.scrollIntoViewIfNeeded();
   const box=await grip.boundingBox(),before=await owner.locator('.jmv-results-image-image').boundingBox();
   const desired=[Math.round(bases[index].widthM*scale[0]),Math.round(bases[index].heightM*scale[1])];
   await page.mouse.move(box.x+10,box.y+10);await page.mouse.down();
   await page.mouse.move(box.x+10+desired[0]-before.width,box.y+10+desired[1]-before.height,{steps:6});await page.mouse.up();
   const message=await page.evaluate(()=>window.resizeMessages.at(-1));assert.equal(message.name,name);
   fs.writeFileSync(folder+'/resize.json',JSON.stringify(message));
   state=await engine(folder,'resize',mode,prefix);
   assert.equal(state.runs,1,'native Image resize must not execute R');
   assert.equal(state.pending.length,0,'native Image resize must not restart capture');assert.equal(state.images.length,4);
   assert.deepEqual(state.tableData,tableData,'the native table must remain byte-identical');
   for(let i=0;i<4;i++){
    const actual=state.imageDetails[i];assert.equal(actual.stateHash,bases[i].stateHash,'PNG source state must survive');
    if(i===index){assert.ok(Math.abs(actual.width-desired[0])<=1);assert.ok(Math.abs(actual.height-desired[1])<=1);assert.equal(actual.widthM,bases[i].widthM);assert.equal(actual.heightM,bases[i].heightM);}
    else assert.deepEqual(actual,previous[i],'unrelated Image must not change or regenerate');
   }
   await page.evaluate(({index,element,png})=>{
    const owner=document.getElementById('native-'+index),image=owner.querySelector('.jmv-results-image-image');
    owner.nativeResize.model.attributes.element=element;
    image.style.width=element.width+'px';image.style.height=element.height+'px';image.style.backgroundSize=element.width+'px';image.style.backgroundImage='url(data:image/png;base64,'+png+')';
   },{index,element:state.imageDetails[index],png:fs.readFileSync(folder+'/resources/'+state.imageDetails[index].path).toString('base64')});
  }
  console.log(prefix,mode,'six native Image resize releases: one R run, no recapture, stable bases, other rasters/table unchanged PASSED');
  state=await engine(folder,'html',mode,prefix);assert.equal(state.html.length,4);assert.equal(state.runs,2);await render(state.html);
  assert.equal(await page.locator('.mz-bj-point').count(),48);
  // Start another Image run, then switch to Html before acknowledging any PNG.
  state=await engine(folder,'image',mode,prefix);assert.equal(state.runs,3);await render(state.pending);
  await page.waitForFunction(()=>window.mzRjNativeImageQueue.inFlight!==null);
  state=await engine(folder,'html',mode,prefix);assert.equal(state.runs,4);await render(state.html);
  await page.waitForFunction(()=>window.mzRjNativeImageQueue.entries.size===0&&window.mzRjNativeImageQueue.ackTimers.size===0);
  assert.equal(await page.locator('.mz-bj-point').count(),48);
  state=await engine(folder,'error',mode,prefix);assert.equal(state.runs,5);assert.ok(state.error.includes('Intentional recovery probe'));
  state=await engine(folder,'html',mode,prefix);assert.equal(state.runs,6);assert.equal(state.html.length,4);await render(state.html);
  assert.equal(await page.locator('.mz-bj-point').count(),48);assert.deepEqual(errors,[]);
  await page.close();console.log(prefix,mode,'four Images acknowledged individually; Html recovery, cancellation, runtime-error recovery and same-instance Run PASSED');
 }}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
