"use strict";
// SPDX-License-Identifier: PolyForm-Noncommercial-1.0.0
// Required Notice: Copyright 2026 Maciej Jankowski (https://maciejjankowski.com)
const menuButton=document.querySelector('.nav-toggle');
const menu=document.querySelector('header nav');
if(menuButton&&menu){
  menuButton.addEventListener('click',()=>{
    const open=menu.classList.toggle('open');menuButton.setAttribute('aria-expanded',String(open));
  });
  menu.querySelectorAll('a').forEach(link=>link.addEventListener('click',()=>{
    menu.classList.remove('open');menuButton.setAttribute('aria-expanded','false');
  }));
}
const proofData=document.getElementById('proof-data');
if(proofData){
  const data=JSON.parse(proofData.textContent);
  const descriptions={
    supported:['The record declares support','Flow complexity prevents first-task completion. The fictional record includes an observation and a tested ordinary alternative.'],
    defeated:['Its declared defeater arrives','A later fictional comparison finds that instruction alone performs as well. The old reading still says supported. That declaration now blocks the record.'],
    withdrawn:['The reading is withdrawn','Keep both observations and the failed reading in the record. Withdraw it, retain the brief and close without a forced deeper explanation.']
  };
  const render=stage=>{
    const selected=data[stage];
    document.querySelectorAll('[data-stage]').forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.stage===stage)));
    document.getElementById('stage-heading').textContent=descriptions[stage][0];
    document.getElementById('stage-description').textContent=descriptions[stage][1];
    const status=document.getElementById('proof-status');
    status.textContent=selected.report.status==='blocked'?'Blocked: withdraw the reading':selected.report.verdict==='awaiting_closure_review'?'Awaiting closure review; evidence unverified':'Awaiting change review; evidence unverified';
    status.className='status'+(selected.report.status==='blocked'?' blocked':'');
    document.getElementById('proof-report').textContent=JSON.stringify(selected.report,null,2);
    document.getElementById('proof-record').textContent=JSON.stringify(selected.case,null,2);
  };
  document.querySelectorAll('[data-stage]').forEach(button=>button.addEventListener('click',()=>render(button.dataset.stage)));
  render('supported');
}
