(function(){
const messages=__MESSAGES__,_=text=>messages[text]||text;
const root=document.getElementById('__ROOT__'),config=__PAYLOAD__,svg=root.querySelector('svg');
const canvas=document.createElement('canvas');canvas.width=__WIDTH__;canvas.height=__HEIGHT__;
const holder=document.createElement('div');holder.style.cssText='position:absolute;left:-100000px;top:0';
holder.appendChild(canvas);root.appendChild(holder);let chart;
try{
 const colors=['#3e6da9','#ed9950','#429587','#a580b7','#d66a70','#7e929c'];
 config.data.datasets.forEach((d,i)=>{if(d.borderColor===undefined)d.borderColor=colors[i%colors.length];
  if(d.backgroundColor===undefined)d.backgroundColor=colors[i%colors.length]+'99';});
 config.options.responsive=false;config.options.animation=false;config.options.events=[];
 config.options.devicePixelRatio=2;
 config.plugins=[{id:'mzrjWhite',beforeDraw(c){const ctx=c.ctx;ctx.save();
  ctx.globalCompositeOperation='destination-over';ctx.fillStyle='white';
  ctx.fillRect(0,0,c.width,c.height);ctx.restore();}}];
 chart=new window.mzRjChart461(canvas,config);
 svg.querySelector('image').setAttribute('href',chart.toBase64Image());
}catch(e){const p=root.querySelector('p');p.hidden=false;p.textContent='Chart.js: '+e.message;}
finally{const c=chart||window.mzRjChart461.getChart(canvas);if(c)c.destroy();holder.remove();}
})();