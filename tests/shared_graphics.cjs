/* Real R-produced payloads through the shared renderers, offline. */
const fs=require('fs'),path=require('path'),assert=require('node:assert/strict');
const {chromium}=require(process.env.MZRJ_PLAYWRIGHT||'playwright');
const root=path.resolve(process.argv[2]),work=path.resolve(process.argv[3]);
(async()=>{const browser=await chromium.launch({headless:true,...(process.env.MZRJ_CHROME?{executablePath:process.env.MZRJ_CHROME}:{})});
try {for(const mode of ['embedded','system']) for(const f of JSON.parse(fs.readFileSync(path.join(work,mode,'fixtures.json'),'utf8'))){
 const page=await browser.newPage({viewport:{width:1100,height:950}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));await page.route('**/*',r=>r.abort());
 await page.setContent('<meta charset="utf-8"><meta http-equiv="Content-Security-Policy" content="default-src \'none\'; script-src \'unsafe-inline\' \'unsafe-eval\'; style-src \'unsafe-inline\'; img-src data:; font-src data:;"><div class="jmv-results-html" style="width:720px"><div class="content"></div></div><table id="after"><tr><td>Following result</td></tr></table>');
 await page.evaluate(()=>{window.captures=[];window.setOption=(name,text)=>window.captures.push({name,...JSON.parse(text)});});
 for(const vendor of ['d3.min.js','plotly.min.js'])await page.addScriptTag({content:fs.readFileSync(path.join(root,'inst/extdata',vendor),'utf8')});
 const content=fs.readFileSync(path.join(work,mode,f.file),'utf8');
 const mount=async html=>page.evaluate(html=>{const target=document.querySelector('.content');target.innerHTML=html;for(const old of target.querySelectorAll('script')){const script=document.createElement('script');script.textContent=old.textContent;document.head.appendChild(script);script.remove();old.remove();}},html);
 await mount(content);
 if(f.mode==='html'){
  if(f.name==='iris_d3'||f.name==='length_histogram'){
   await page.waitForSelector('.mz-d3-mark');if(f.name==='iris_d3')assert.equal(await page.locator('.mz-d3-mark').count(),150);
   if(f.name==='iris_d3'){await page.locator('.mz-d3-group').first().click();assert(await page.locator('.mz-d3-mark[style*="display: none"]').count()>0);}
   const slider=page.locator('.mz-d3-zoom input');
   const range=page.locator('input[type=range]').first();if(await range.count()){await range.fill('130');await range.dispatchEvent('input');}
  }else if(f.name==='iris_chart'){
   await page.waitForFunction(()=>window.mzRjChart461?.getChart(document.querySelector('canvas')));
   const canvas=await page.locator('canvas').elementHandle();await mount(content);
   assert(await page.locator('canvas').evaluate((node,old)=>node===old,canvas),'unchanged Chart canvas must be reused');
  }else{
   await page.waitForFunction(()=>document.querySelector('.js-plotly-plot')?._fullLayout);
   assert.equal(await page.evaluate(()=>document.querySelector('.js-plotly-plot')._context.displayModeBar),false);
   if(f.name==='correlation_heatmap'){
    const values=await page.evaluate(()=>{const trace=document.querySelector('.js-plotly-plot').data[0];return {z:trace.z,min:trace.zmin,max:trace.zmax,text:trace.texttemplate};});
    assert.equal(values.z.length,4);assert(values.z.every(row=>Array.isArray(row)&&row.length===4&&row.every(Number.isFinite)));
    assert.equal(values.z[0][0],1);assert(Math.abs(values.z[0][1]+.11756978413300206)<1e-12);
    assert.equal(values.min,-1);assert.equal(values.max,1);assert.equal(values.text,'%{z:.2f}');
    const raster=await page.evaluate(async()=>{
     const node=document.querySelector('.heatmaplayer image');if(!node)throw Error('Missing heatmap cell raster');
     const image=new Image();image.src=node.getAttribute('href')||node.getAttribute('xlink:href');await image.decode();
     const canvas=document.createElement('canvas');canvas.width=image.naturalWidth;canvas.height=image.naturalHeight;
     const ctx=canvas.getContext('2d');ctx.drawImage(image,0,0);const data=ctx.getImageData(0,0,canvas.width,canvas.height).data;
     const colors=new Set();let opaque=0;for(let i=0;i<data.length;i+=4)if(data[i+3]){opaque++;colors.add([data[i],data[i+1],data[i+2]].join(','));}
     return {opaque,colors:colors.size};
    });
    assert(raster.opaque>=16&&raster.colors>=5,'heatmap must contain colored correlation cells, not empty axes');
   }
   if(f.name==='iris_plotly')assert.equal(await page.evaluate(()=>document.querySelector('.js-plotly-plot').data[0].q1[0]),Number(3.2));
  }
  assert.equal(await page.locator('details').count(),1);
  await page.locator('summary').click();assert.equal(await page.locator('details').evaluate(n=>n.open),false);
  await page.locator('summary').click();await page.waitForTimeout(100);
  const flow=await page.evaluate(()=>({graphic:document.querySelector('.jmv-results-html').getBoundingClientRect().bottom,table:document.getElementById('after').getBoundingClientRect().top}));
  assert(flow.table>=flow.graphic-1,'following table overlaps graphic');
 }else if(f.mode==='svg'){
  if(f.name==='iris_d3'||f.name==='length_histogram')await page.waitForSelector('svg.jmv-results-svg-content');
  else await page.waitForFunction(()=>document.querySelector('svg.jmv-results-svg-content image')?.getAttribute('href')?.startsWith('data:image/png'));
  assert.equal(await page.locator('details').count(),0);
 }else{
  await page.waitForFunction(()=>window.captures.length>0,null,{timeout:45000});
  const payload=await page.evaluate(()=>window.captures[0]);assert.equal(payload.name,'graphicCapture');
  assert.equal(payload.images[0].name,f.name);assert(payload.images[0].content.startsWith('iVBOR'));
  fs.writeFileSync(path.join(work,mode,f.name+'_capture.json'),JSON.stringify(payload));
 }
 assert.deepEqual(errors,[],f.file+': '+errors.join('; '));
 await page.screenshot({path:path.join(work,mode,f.name+'_'+f.mode+'.png'),fullPage:true});
 console.log('PASSED',mode,f.file);await page.close();
 }
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
