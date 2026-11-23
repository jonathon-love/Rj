/* Exercise jamovi's actual pointer and Image scale calculations in Chromium.
 * Only TS types and unrelated application services are removed in this harness.
 */
const fs=require('fs');
module.exports=function nativeResizeScript(core){
 const handles=fs.readFileSync(core+'/client/resultsview/resizehandles.ts','utf8');
 const pointer=handles.slice(handles.indexOf('const clamp'))
  .replace('(size: number)','(size)')
  .replace('export function addResizeHandles(owner: HTMLElement, options: ResizeHandlesOptions): void','function addResizeHandles(owner, options)')
  .replace('let cancelDrag: (() => void) | null','let cancelDrag')
  .replaceAll('(event: PointerEvent)','(event)').replaceAll('(e: PointerEvent)','(e)').replace('(commit: boolean)','(commit)');
 const image=fs.readFileSync(core+'/client/resultsview/image.ts','utf8');
 const target=image.slice(image.indexOf('    getResizeTarget()'),image.indexOf('    disconnectedCallback()')).replace('getResizeTarget(): ResizeTarget','getResizeTarget()');
 const scale=image.slice(image.indexOf('    updateScaleValues('),image.indexOf('    type()')).replaceAll(': number','');
 return `(function(){
 const DEFAULT_RESIZE_HANDLE_STYLE='corner',interactionManager={announce(){}},_=v=>v;
 const h=(tag,attrs)=>{const n=document.createElement(tag);for(const [k,v]of Object.entries(attrs))n.setAttribute(k,v);return n;};
 ${pointer}
 class ImageResize {
  constructor(owner,image,element){this.owner=owner;this.$image=image;this.model={attributes:{element}};this.resizeObserver={observe(){}};}
  address(){return [this.model.attributes.element.name];}
  focus(options){this.owner.focus(options);}
  get isConnected(){return this.owner.isConnected;}
  ${target}
  ${scale}
 }
 window.installNativeImageResize=(owner,image,element)=>{
  const view=new ImageResize(owner,image,element);owner.nativeResize=view;
  addResizeHandles(owner,{element:()=>image,focus:()=>owner.focus({preventScroll:true}),
   feedback:()=>{image.style.backgroundSize='';},commit:(w,h)=>view.getResizeTarget().apply(w,h)});
 };
 })();`;
};
