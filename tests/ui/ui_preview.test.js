const fs = require('fs'), path = require('path'), assert = require('assert');

const {chromium} = require(process.env.MZRJ_PLAYWRIGHT || 'playwright');

const root = path.resolve(__dirname, '../..');

const output = process.env.MZRJ_UI_OUTPUT || path.join(require('os').tmpdir(), 'mzrj-ui-preview');

fs.mkdirSync(output, {recursive:true});

(async () => {

 const browser = await chromium.launch({headless:true, executablePath:process.env.MZRJ_CHROME || undefined});

 try {

  for (const kind of ['Rj','Rjp']) {

   const page = await browser.newPage({viewport:{width:1000,height:720}});

   const errors=[]; page.on('pageerror', error=>errors.push(error.message));

   await page.setContent('<meta charset="utf-8"><style>body{margin:0;font:16px sans-serif;--main-background-color:#e6e6e6;background:var(--main-background-color)}.silky-options-content{padding-top:15px}.top-level{margin-bottom:20px}#app{box-sizing:border-box;width:min(560px,100%);height:100vh;display:flex;flex-direction:column}</style><div class="jmv-options-block"><div class="silky-options-header" style="display:flex;align-items:center;height:48px"><span class="silky-options-title">Rj Editor</span><button class="silky-sp-back-button">Back</button></div><div id="app" class="silky-options-content"><div class="top-level"></div></div></div>');

   await page.addScriptTag({content:'window.module={exports:{}};'});

   for(const file of ['node_modules/brace/index.js','node_modules/brace/mode/r.js','node_modules/brace/ext/language_tools.js'])

    await page.addScriptTag({path:path.join(root,'jamovi/js',file)});

   const modules={};

   for(const name of ['main','css','suggest','suggesticons','funcs','mzRj_settings','mzRj_editor_files','mzRj_variables','mzRj_omv_files','mzRj_i18n','mzRj_version'])modules[name]=fs.readFileSync(path.join(root,'jamovi/js',name+'.js'),'utf8');

   await page.evaluate(({modules,kind})=>{

    window.name='Rj-'+kind;

    const cache={};

    function load(name){

     if(name==='brace')return window.ace.acequire('ace/ace');

     if(name.startsWith('brace/'))return {};

     name=name.replace(/^\.\//,'');

     if(cache[name])return cache[name].exports;

     const module={exports:{}};cache[name]=module;

     new Function('require','module','exports',modules[name])(load,module,module.exports);

     return module.exports;

    }

    const store={code:'summary(data)',R:'bundled',vars:['group'],output:'noEcho',figWidth:'',figHeight:'',toggle:false,editorState:{},saveEditorScript:false,editorCleared:false,omvFile:null,dataextInfo:{json:'{}'},previewDataext:false,previewDataextRequest:false,saveOmvFile:false};

    const writes=[];let batches=0;const listeners={};

    const ui={view:{el:document.querySelector('#app'),model:{options:{beginEdit(){batches++;},endEdit(){},getOption(name){return {on(event,fn){listeners[name]=fn;}};}}}}};

    for(const key of Object.keys(store))ui[key]={value:()=>store[key],setValue:value=>{writes.push({key,value});store[key]=value;}};

    const ctx=Object.assign({requestData:async()=>({columns:[{name:'Filter 1'},{name:'Sepal.Length'},{name:'group'}]})},load('main'));

    if(kind==='Rjp') {

     document.querySelector('#app').insertAdjacentHTML('beforeend','<div id="variables-row"><div id="accordion"></div><div id="supplier-row"><jmv-selectgrid class="silky-variable-supplier"></jmv-selectgrid><div class="jmv-toolbar arrow-right"><button class="jmv-variable-transfer"><span class="jmv-toolbar-button-icon"></span></button></div><div id="variables-target"><span class="column-ghost-label">optional — becomes data in your code</span></div></div></div>');

     ui.rjpAccordion={el:document.querySelector('#accordion')};ui.vars.el=document.querySelector('#variables-target');

    }

    const fileCell=document.createElement('div');fileCell.className='silky-layout-cell';
    fileCell.innerHTML='<label>OMV input</label><div class="jmv-file-selector"><button class="jmv-file-selector-button">Browse</button></div>';
    ui.view.el.append(fileCell);ui.omvFile.body=fileCell.querySelector('.jmv-file-selector');ui.omvFile.label=fileCell.querySelector('label');
    ctx.loaded(ui);ctx.update(ui,{id:1});ctx.editor.session.setUseWorker(false);

    window.fixture={store,writes,ui,ctx,batches:()=>batches,listeners,translate:load('mzRj_i18n'),reset(){writes.length=0;batches=0;}};

   },{modules,kind});

   assert.strictEqual(await page.locator('#editor-kind').count(),0);
   assert.strictEqual(await page.locator('#editor-filename').textContent(),'Untitled');
   assert.strictEqual(await page.locator('#app').evaluate(el=>parseFloat(getComputedStyle(el).paddingTop)),kind==='Rj'?7.5:15);
   assert.strictEqual(await page.locator('#app > .top-level').evaluate(el=>parseFloat(getComputedStyle(el).marginBottom)),10);
   assert.strictEqual(await page.locator('#scripts-label').evaluate(el=>getComputedStyle(el).backgroundColor),'rgb(230, 230, 230)');
   for(const button of ['#clear-script','#load-script','#save-script','#config','#run']) {
    const box=await page.locator(button).boundingBox();assert.strictEqual(box.width,32);assert.strictEqual(box.height,32);
   }
   await page.screenshot({path:path.join(output,kind+'_toolbar.png')});
   assert.strictEqual(await page.locator('#rj-module-version').textContent(),'Rj v'+fs.readFileSync(path.join(root,'DESCRIPTION'),'utf8').match(/^Version:\s*(.+)$/m)[1].trim());
   assert.strictEqual(await page.locator('#omv-files .jmv-file-selector-button').textContent(),'Read…');
   assert(await page.locator('#save-omv').isDisabled());
   await page.evaluate(()=>{
    fixture.store.dataextInfo={json:JSON.stringify({ready:true,name:'test.omv',rows:3,columns:2})};fixture.listeners.dataextInfo();
    const box=document.querySelector('#preview-dataext');box.checked=true;box.dispatchEvent(new Event('change'));
   });
   assert(!await page.locator('#save-omv').isDisabled());
   assert(await page.evaluate(()=>fixture.store.previewDataext&&fixture.store.previewDataextRequest));
   assert(!await page.evaluate(()=>fixture.writes.some(w=>w.key==='toggle'||w.key==='code')));
   await page.evaluate(()=>{window._=key=>'IT['+key+']';});
   assert.strictEqual(await page.evaluate(()=>fixture.translate('Settings')),'IT[Settings]');
   await page.evaluate(()=>{delete window._;fixture.reset();});
   if(kind==='Rjp') {

    assert(await page.locator('.silky-options-title .mzrj-editor-plus').isVisible());

    assert(await page.locator('.rj-vs-source').count()===1);
    assert(await page.locator('.rj-vs-target.rj-vs-filled').count()===1);

    await page.evaluate(()=>{fixture.store.vars=[];fixture.ctx.onChange_vars(fixture.ui);fixture.reset();});

    assert(await page.locator('.rj-vs-target.rj-vs-empty').count()===1);

    await page.locator('#accordion').click();

    assert.strictEqual(await page.locator('#accordion').getAttribute('aria-expanded'),'false');

    assert(await page.locator('#supplier-row').evaluate(el=>el.inert));

    await page.locator('#accordion').press('Enter');

    assert.strictEqual(await page.locator('#accordion').getAttribute('aria-expanded'),'true');

    assert.deepStrictEqual(await page.evaluate(()=>fixture.writes),[]);

   }

   assert(await page.locator('.silky-options-header #load-service').isVisible());

   assert.strictEqual(await page.locator('#app #service-bar').count(),0);

   assert(await page.locator('input[value="bundled"]').isChecked());

   await page.locator('#config').click();

   const entering=await page.locator('#menu').evaluate(async el=>{

    const a=el.getAnimations().find(a=>a.transitionProperty==='transform');a.pause();a.currentTime=0;const start=el.getBoundingClientRect().x;

    a.currentTime=140;const middle=el.getBoundingClientRect().x;

    a.finish();await a.finished;const end=el.getBoundingClientRect().x;

    return {start,middle,end};

   });

   assert(entering.start>entering.middle&&entering.middle>entering.end,'Opening must slide right to left');

   assert(await page.locator('#menu').isVisible());

   await page.locator('#figure-width').focus();await page.keyboard.press('Escape');

   await page.locator('#menu').waitFor({state:'hidden'});assert(await page.locator('#config').evaluate(el=>el===document.activeElement));

   assert.deepStrictEqual(await page.evaluate(()=>fixture.writes),[]);

   await page.locator('#config').click();await page.locator('input[value="external"]').check();

   assert.deepStrictEqual(await page.evaluate(()=>fixture.writes),[{key:'R',value:'external'}]);

   await page.evaluate(()=>{fixture.store.R='bundled';fixture.ctx.update(fixture.ui,{id:1});fixture.reset();});

   assert(await page.locator('input[value="bundled"]').isChecked());

   await page.mouse.click(800,650);await page.locator('#menu').waitFor({state:'hidden'});

   assert.deepStrictEqual(await page.evaluate(()=>fixture.writes),[]);

   await page.evaluate(()=>{

    const f=fixture;f.ctx.currentSession.setValue("cat('draft one')");f.store.code="cat('analysis two')";f.store.editorState={};f.ctx.update(f.ui,{id:2});

    window.secondDraft=f.ctx.currentSession.getValue();f.store.code='summary(data)';f.ctx.update(f.ui,{id:1});

   });

   assert.strictEqual(await page.evaluate(()=>fixture.ctx.currentSession.getValue()),"cat('draft one')");

   assert.strictEqual(await page.evaluate(()=>window.secondDraft),"cat('analysis two')");

   await page.evaluate(()=>{fixture.reset();fixture.ctx.editor.setValue('# (Sepal.Length)\nsummary(data)',-1);});

   await page.locator('#run').click();

   await page.waitForFunction(()=>fixture.writes.some(w=>w.key==='toggle'));

   assert.strictEqual(await page.evaluate(()=>fixture.batches()),1);

   const vars=await page.evaluate(()=>fixture.writes.filter(w=>w.key==='vars'));

   assert.deepStrictEqual(vars,kind==='Rj'?[{key:'vars',value:['Sepal.Length']}]:[]);

   if(kind==='Rj') {

    await page.evaluate(async()=>{

     const f=fixture;f.reset();f.ctx.requestData=()=>new Promise(resolve=>window.resolveColumns=resolve);

     const pending=f.ctx.run(f.ui);f.store.code='cat(2)';f.store.editorState={};f.ctx.update(f.ui,{id:2});

     resolveColumns({columns:[{name:'wrong analysis'}]});await pending;

    });

    assert.deepStrictEqual(await page.evaluate(()=>fixture.writes),[]);

   }

   await page.setInputFiles('#editor-file',{name:'loaded.R',mimeType:'text/plain',buffer:Buffer.from("cat('loaded')\r\n")});

   await page.locator('#cancel-script').click();

   assert.notStrictEqual(await page.evaluate(()=>fixture.ctx.editor.getValue()),"cat('loaded')\n");

   await page.setInputFiles('#editor-file',{name:'loaded.R',mimeType:'text/plain',buffer:Buffer.from("cat('loaded')\r\n")});

   await page.locator('#replace-script').click();

   assert.strictEqual(await page.evaluate(()=>fixture.ctx.editor.getValue()),"cat('loaded')\n");

   await page.setInputFiles('#service-file',{name:'helpers.R',mimeType:'text/plain',buffer:Buffer.from('helper <- function() 42')});

   await page.waitForFunction(()=>fixture.store.editorState.serviceName==='helpers.R');

   await page.evaluate(()=>fixture.reset());

   await page.locator('#save-script').click();

   assert(await page.evaluate(()=>fixture.store.saveEditorScript));

   assert(!await page.evaluate(()=>fixture.writes.some(w=>w.key==='toggle')));

   await page.locator('#clear-script').click();

   assert.strictEqual(await page.evaluate(()=>fixture.ctx.editor.getValue()),'');

   assert.strictEqual(await page.evaluate(()=>fixture.store.editorState.serviceName),'helpers.R');

   assert.strictEqual(await page.evaluate(()=>fixture.store.editorCleared),true);

   await page.locator('#config').click();

   await page.locator('#menu').evaluate(el=>Promise.all(el.getAnimations().map(a=>a.finished)));

   const box=await page.locator('#menu').boundingBox();assert(box.x>=0&&box.y>=0&&box.x+box.width<=1000&&box.y+box.height<=720);

   await page.evaluate(()=>document.body.style.zoom='1.75');

   await page.locator('#config').click();await page.locator('#config').click();

   await page.locator('#menu').evaluate(el=>Promise.all(el.getAnimations().map(a=>a.finished)));

   const zoomed=await page.locator('#menu').boundingBox();

   assert(zoomed.width<510,'Popup should match Pj dimensions at 175% zoom');
   assert(await page.locator('#menu').evaluate(el=>el.scrollHeight<=el.clientHeight+1),'At 175% zoom the complete OMV panel should fit without scrolling');

   assert(zoomed.x>=0&&zoomed.y>=0&&zoomed.x+zoomed.width<=1000&&zoomed.y+zoomed.height<=720);

   const handle=await page.locator('#menu-drag').boundingBox();

   await page.mouse.move(handle.x+20,handle.y+8);await page.mouse.down();await page.mouse.move(handle.x-30,handle.y+38);await page.mouse.up();

   const moved=await page.locator('#menu').boundingBox();assert(Math.abs(moved.x-zoomed.x)>15||Math.abs(moved.y-zoomed.y)>15);

   await page.screenshot({path:path.join(output,kind+'_settings.png')});

   await page.evaluate(()=>document.body.style.zoom='1');



   await page.setViewportSize({width:320,height:180});

   await page.waitForFunction(()=>{const b=document.querySelector('#menu').getBoundingClientRect();return b.x>=0&&b.y>=0&&b.right<=innerWidth&&b.bottom<=innerHeight;});

   const small=await page.locator('#menu').boundingBox();assert(small.x>=0&&small.y>=0&&small.x+small.width<=320&&small.y+small.height<=180);

   assert(await page.locator('#menu').evaluate(el=>el.scrollHeight>el.clientHeight));

   await page.keyboard.press('Escape');

   const exiting=await page.locator('#menu').evaluate(async el=>{

    const a=el.getAnimations().find(a=>a.transitionProperty==='transform');a.pause();a.currentTime=0;const start=el.getBoundingClientRect().x;

    a.currentTime=140;const middle=el.getBoundingClientRect().x;const hiddenHalfway=getComputedStyle(el).visibility==='hidden';

    a.finish();await Promise.all(el.getAnimations().map(a=>{a.finish();return a.finished;}));return {start,middle,hiddenHalfway,hidden:getComputedStyle(el).visibility==='hidden'};

   });

   assert(exiting.middle>exiting.start&&!exiting.hiddenHalfway&&exiting.hidden,'Closing must slide left to right before hiding');

   // A quick reversal must not let the old closing completion hide the reopened menu.

   await page.evaluate(()=>{fixture.ctx.settings.show();fixture.ctx.settings.hide();fixture.ctx.settings.show();});

   await page.locator('#menu').evaluate(el=>Promise.all(el.getAnimations().map(a=>a.finished)));

   assert(await page.locator('#menu').isVisible());

   assert.deepStrictEqual(errors,[]);

   await page.close();console.log(kind+': real Ace, popup/focus/scroll, native R values, draft isolation and Run transaction PASSED');

  }

 } finally {await browser.close();}

})().catch(error=>{console.error(error);process.exit(1);});
