"use strict";
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
(async()=>{
  const status=document.getElementById('diagram-status');
  const nodes=document.querySelectorAll('.mermaid');
  if(!nodes.length)return;
  if(!window.mermaid){if(status)status.textContent='The renderer is unavailable. Expand a chart to read its editable Mermaid source.';return;}
  try{
    mermaid.initialize({startOnLoad:false,securityLevel:'strict',theme:'neutral',layout:'dagre',flowchart:{htmlLabels:false,look:'classic'}});
    await mermaid.run({querySelector:'.mermaid'});
    document.querySelectorAll('.mermaid svg').forEach(svg=>{
      const width=Number((svg.getAttribute('viewBox')||'').split(/\s+/)[2]);
      if(width>0){svg.style.width=Math.ceil(width)+'px';svg.style.maxWidth='100%';}
      const button=svg.closest('figure').querySelector('.diagram-size');
      if(button){
        button.hidden=false;
        button.addEventListener('click',()=>{
          const enlarged=button.getAttribute('aria-pressed')!=='true';
          svg.style.maxWidth=enlarged?'none':'100%';
          button.setAttribute('aria-pressed',String(enlarged));
          button.textContent=enlarged?'Fit diagram to page':'Enlarge diagram';
        });
      }
    });
    if(status)status.textContent=document.querySelectorAll('.mermaid svg').length+' diagrams rendered. Each chart retains its editable source.';
  }catch(error){if(status)status.textContent='Some charts could not render. Their Mermaid source remains available below each chart.';}
})();
