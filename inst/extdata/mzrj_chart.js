(function(){
const messages=__MESSAGES__,_=text=>messages[text]||text;
const root=document.getElementById('__ROOT__'),config=__PAYLOAD__;
const host=root.closest('.jmv-results-html'),signature='__SIGNATURE__';
const views=window.mzRjChartHtmlViews||(window.mzRjChartHtmlViews=new WeakMap());
const previous=host&&views.get(host);
if(previous&&previous.signature===signature){
 const parent=root.closest('.mzrj-accordion'),id=root.id;
 root.replaceWith(previous.root);previous.root.id=id;previous.adopt(parent);
 return;
}
if(previous)previous.dispose();
const legendInfo=config._mzrjLegend;delete config._mzrjLegend;
const surface=root.querySelector('.mzrj-cj-surface'),canvas=surface.querySelector('canvas');
let details=root.closest('.mzrj-accordion');
const error=root.querySelector('.mzrj-cj-error');
const C=window.mzRjChart461;let chart=null,frame=0,observer,printing=false,floating=null,legendResize=null;
function snapshot(c){if(c.width&&c.height)surface.style.backgroundImage='url("'+c.toBase64Image()+'")';}
function dispose(){cancelAnimationFrame(frame);if(observer)observer.disconnect();
 if(details)details.removeEventListener('toggle',onToggle);
 if(host&&views.get(host)?.root===root)views.delete(host);
 if(legendResize)legendResize.disconnect();
 window.removeEventListener('beforeprint',preparePrint);window.removeEventListener('afterprint',finishPrint);
 if(chart){chart.destroy();chart=null;}}
function showError(e){error.hidden=false;error.textContent='Chart.js: '+e.message;}
// Il PDF di jamovi stampa l'HTML in una finestra separata, senza sfondi e senza attendere animazioni.
function preparePrint(){printing=true;render();if(chart){chart.stop();chart.resize();chart.update('none');snapshot(chart);}}
function finishPrint(){printing=false;if(chart)chart.resize();}
function refreshLegend(c){if(floating)floating.querySelectorAll('[data-dataset-index]').forEach(b=>
 b.setAttribute('aria-pressed',String(c.isDatasetVisible(Number(b.dataset.datasetIndex)))));}
function makeLegend(){
 if(!legendInfo||floating)return;
 floating=document.createElement('aside');floating.className='mzrj-cj-float';floating.setAttribute('aria-label',legendInfo.title||_('Legend and notes'));
 const head=document.createElement('div');head.className='mzrj-cj-float-head';head.tabIndex=0;head.setAttribute('role','group');
 head.setAttribute('aria-label','Move legend: drag or use arrow keys. Shift moves farther.');
 const title=document.createElement('span');title.className='mzrj-cj-float-title';title.textContent=legendInfo.title||'Legend & notes';
 const toggle=document.createElement('button');toggle.type='button';toggle.className='mzrj-cj-float-toggle';
 const body=document.createElement('div');body.className='mzrj-cj-float-body';body.id=root.id+'_legend_body';
 toggle.setAttribute('aria-controls',body.id);let collapsed=legendInfo.collapsed===true;
 let x=0,y=10,drag=null;
 function place(nx,ny){x=Math.max(0,Math.min(nx,surface.clientWidth-floating.offsetWidth));
  y=Math.max(0,Math.min(ny,surface.clientHeight-floating.offsetHeight));floating.style.left=x+'px';floating.style.top=y+'px';}
 function fold(){body.hidden=collapsed;toggle.textContent=collapsed?'+':'−';toggle.setAttribute('aria-expanded',String(!collapsed));
  toggle.setAttribute('aria-label',collapsed?'Expand legend and notes':'Collapse legend and notes');place(x,y);}
 toggle.addEventListener('click',e=>{e.stopPropagation();collapsed=!collapsed;fold();});
 head.append(title,toggle);floating.append(head,body);surface.appendChild(floating);
 if(legendInfo.text){const p=document.createElement('p');p.className='mzrj-cj-float-note';p.textContent=legendInfo.text;body.appendChild(p);}
 const items=legendInfo.items||chart.data.datasets.map((d,i)=>({label:d.label||'Series '+(i+1),dataset:i}));
 items.forEach(item=>{const linked=Number.isInteger(item.dataset),row=document.createElement(linked?'button':'div');
  row.className='mzrj-cj-float-item';if(linked){row.type='button';row.dataset.datasetIndex=item.dataset;
   row.addEventListener('click',()=>{chart.setDatasetVisibility(item.dataset,!chart.isDatasetVisible(item.dataset));chart.update();});}
  const marker=document.createElement('span');marker.className='mzrj-cj-float-marker';marker.setAttribute('aria-hidden','true');
  const dataset=linked?chart.data.datasets[item.dataset]:{},raw=item.color||dataset.borderColor||'#3e6da9';
  const color=Array.isArray(raw)?raw[0]:raw;marker.style.backgroundColor=typeof color==='string'&&CSS.supports('color',color)?color:'#3e6da9';
  const text=document.createElement('span'),label=document.createElement('strong');label.textContent=item.label;text.appendChild(label);
  if(item.text){const description=document.createElement('span');description.className='mzrj-cj-float-description';description.textContent=item.text;text.appendChild(description);}
  row.append(marker,text);body.appendChild(row);});
 head.addEventListener('pointerdown',e=>{if(e.button!==0||e.target.closest('button'))return;
  e.preventDefault();e.stopPropagation();drag={id:e.pointerId,mx:e.clientX,my:e.clientY,x,y};head.setPointerCapture(e.pointerId);});
 head.addEventListener('pointermove',e=>{if(drag&&e.pointerId===drag.id)place(drag.x+e.clientX-drag.mx,drag.y+e.clientY-drag.my);});
 const end=e=>{if(drag&&e.pointerId===drag.id)drag=null;};
 head.addEventListener('pointerup',end);head.addEventListener('pointercancel',end);head.addEventListener('lostpointercapture',end);
 head.addEventListener('keydown',e=>{if(e.target!==head)return;const moves={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,-1],ArrowDown:[0,1]};
  const d=moves[e.key];if(d){e.preventDefault();place(x+d[0]*(e.shiftKey?20:5),y+d[1]*(e.shiftKey?20:5));}});
 fold();place(surface.clientWidth-floating.offsetWidth-10,10);refreshLegend(chart);
 legendResize=new ResizeObserver(()=>place(x,y));legendResize.observe(surface);legendResize.observe(floating);
}
function remember(){if(host&&chart)views.set(host,{signature,root,dispose,adopt(parent){
 const open=details?details.open:true;
 if(details)details.removeEventListener('toggle',onToggle);
 details=parent;if(details){details.open=open;details.addEventListener('toggle',onToggle);}
}});}
function render(){
 if(!root.isConnected||(details&&!details.open))return;
 try{
  if(chart){if(chart.width!==surface.clientWidth||chart.height!==surface.clientHeight)chart.resize();return;}
  const colors=['#3e6da9','#ed9950','#429587','#a580b7','#d66a70','#7e929c'];
  config.data.datasets.forEach((d,i)=>{if(d.borderColor===undefined)d.borderColor=colors[i%colors.length];
   if(d.backgroundColor===undefined)d.backgroundColor=colors[i%colors.length]+'99';});
  config.options.responsive=true;config.options.maintainAspectRatio=false;
  config.options.plugins=config.options.plugins||{};config.options.plugins.mzrjSnapshot={};
  if(printing||window.matchMedia('print').matches)config.options.animation=false;
  else if(config.options.animation===undefined)config.options.animation={duration:450};
  config.plugins=[{id:'mzrjSnapshot',afterRender:snapshot,afterUpdate:refreshLegend,beforeDraw(c){
   const ctx=c.ctx;ctx.save();ctx.globalCompositeOperation='destination-over';
   ctx.fillStyle='white';ctx.fillRect(0,0,c.width,c.height);ctx.restore();}}];
  chart=new C(canvas,config);
  canvas.style.backgroundColor='white';
  makeLegend();remember();
 }catch(e){const partial=C.getChart(canvas);if(partial)partial.destroy();chart=null;showError(e);}
}
function onToggle(){cancelAnimationFrame(frame);frame=requestAnimationFrame(render);}
if(details)details.addEventListener('toggle',onToggle);
observer=new MutationObserver(()=>{if(!root.isConnected)dispose();});
observer.observe(document.documentElement,{childList:true,subtree:true});
window.addEventListener('beforeprint',preparePrint);window.addEventListener('afterprint',finishPrint);
render();

})();