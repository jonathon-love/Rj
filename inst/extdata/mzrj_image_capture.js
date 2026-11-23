(async function(){
const messages=__MESSAGES__,_=text=>messages[text]||text;
const request=__REQUEST__,root=document.getElementById(request.root);
if(!root)return;
const status=root.querySelector('[data-image-status]'),errorTitle=root.querySelector('[data-image-error-title]');
function fail(error){if(!root.isConnected)return;root.dataset.mzrjImageCapture='error';root.setAttribute('aria-busy','false');errorTitle.hidden=false;errorTitle.textContent=request.title||request.name;status.hidden=false;status.setAttribute('role','alert');status.textContent=_('Image preparation failed: ')+String(error&&error.message||error)+_('. Run again after correcting the figure.');}
try{
 if(typeof window.setOption!=='function')throw Error(_('the native Image capture bridge is unavailable'));
 const deadline=Date.now()+30000;
 const frame=()=>new Promise(resolve=>requestAnimationFrame(resolve));
 let source;
 while(root.isConnected&&Date.now()<deadline){
  source=root.querySelector('svg.jmv-results-svg-content');
  const error=root.querySelector('.mzrj-cj-error:not([hidden])');
  const plotlyError=root.querySelector('.mz-plotly-status, .mzrj-plotly-status');
  if(error)throw Error(error.textContent);
  if(plotlyError&&plotlyError.textContent.startsWith('Plotly could not'))throw Error(plotlyError.textContent);
  if(source&&Array.from(source.querySelectorAll('image')).every(i=>(i.getAttribute('href')||'').startsWith('data:image/'))){await frame();await frame();break;}
  await frame();
 }
 if(!root.isConnected)return;
 if(!source||Date.now()>=deadline)throw Error(_('the graphic did not finish rendering'));
 const width=Number(source.getAttribute('width')),height=Number(source.getAttribute('height'));
 if(!Number.isFinite(width)||!Number.isFinite(height)||width<=0||height<=0)throw Error(_('invalid figure dimensions'));
 const scale=Math.min(2,4000/width,4000/height,Math.sqrt(4000000/(width*height)));
 const copy=source.cloneNode(true);copy.setAttribute('xmlns','http://www.w3.org/2000/svg');
 const style=getComputedStyle(source);copy.style.fontFamily=style.fontFamily;copy.style.fontSize=style.fontSize;
 const bitmap=new Image();
 await new Promise((resolve,reject)=>{bitmap.onload=resolve;bitmap.onerror=()=>reject(Error(_('the graphic could not be rasterized')));bitmap.src='data:image/svg+xml;charset=utf-8,'+encodeURIComponent(new XMLSerializer().serializeToString(copy));});
 if(!root.isConnected)return;
 const canvas=document.createElement('canvas');canvas.width=Math.max(1,Math.floor(width*scale));canvas.height=Math.max(1,Math.floor(height*scale));
 const context=canvas.getContext('2d');if(!context)throw Error(_('a 2D canvas is unavailable'));
 context.fillStyle='white';context.fillRect(0,0,canvas.width,canvas.height);context.drawImage(bitmap,0,0,canvas.width,canvas.height);
 const content=canvas.toDataURL('image/png').split(',')[1];
 if(content.length>1000000)throw Error(_('the PNG is too large; reduce the figure dimensions'));
 const displayScale=Math.min(1,2000/width,2000/height);
 const entry={name:request.name,token:request.token,content,width:Math.max(1,Math.round(width*displayScale)),height:Math.max(1,Math.round(height*displayScale))};
 let queue=window.mzRjNativeImageQueue;
 if(queue&&queue.version!==2){clearTimeout(queue.timer);for(const timer of queue.ackTimers?.values()||[])clearTimeout(timer);queue.observer?.disconnect();queue=null;}
 if(!queue){
  queue=window.mzRjNativeImageQueue={version:2,entries:new Map(),ackTimers:new Map(),failures:new Map(),inFlight:null,timer:null};
  queue.remove=id=>{clearTimeout(queue.ackTimers.get(id));queue.ackTimers.delete(id);queue.entries.delete(id);queue.failures.delete(id);if(queue.inFlight===id)queue.inFlight=null;};
  queue.prune=()=>{for(const [id]of queue.entries)if(!document.getElementById(id))queue.remove(id);};
  queue.schedule=()=>{if(queue.timer!==null||queue.inFlight!==null||!queue.entries.size)return;queue.timer=setTimeout(queue.flush,50);};
  queue.flush=()=>{
   queue.timer=null;queue.prune();if(queue.inFlight!==null||!queue.entries.size)return;
   const [id,image]=queue.entries.entries().next().value;queue.inFlight=id;
   const reject=error=>{const report=queue.failures.get(id);queue.remove(id);if(report)report(error);queue.schedule();};
   queue.ackTimers.set(id,setTimeout(()=>reject(Error(_('the native Image result was not acknowledged; run the script again'))),30000));
   try{
    // One bounded option message at a time. The Results replacement is the ack.
    const sent=window.setOption('graphicCapture',JSON.stringify({version:1,images:[image]}));
    if(sent&&typeof sent.catch==='function')sent.catch(reject);
   }catch(error){reject(error);}
  };
  queue.observer=new MutationObserver(()=>{queue.prune();queue.schedule();});
  queue.observer.observe(document.documentElement,{childList:true,subtree:true});
 }
 queue.prune();
 if(!queue.entries.has(request.root)&&queue.entries.size>=20)throw Error(_('too many pending PNG captures; split the figures across analyses'));
 queue.entries.set(request.root,entry);queue.failures.set(request.root,fail);
 root.dataset.mzrjImageReady='true';queue.schedule();
}catch(error){fail(error);}
})();