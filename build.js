#!/usr/bin/env node
// Construye index.html cifrado a partir de src/app.html y ACCESS-PASSWORD.txt
// Esquema: contenido cifrado con AES-256-GCM usando una clave aleatoria (CEK);
// la CEK se envuelve dos veces (rol propietario y rol pruebas) con claves PBKDF2-SHA256 (250k iteraciones, salt propio).
const fs=require('fs'),c=require('crypto'),path=require('path');
const D=__dirname,IT=250000;
function readPw(){
  const t=fs.readFileSync(path.join(D,'ACCESS-PASSWORD.txt'),'utf8').split('\n'),o={};
  t.forEach(l=>{const m=/^(ACCESO|PRUEBAS)=(.*)$/.exec(l);if(m)o[m[1]]=m[2]});
  if(!o.ACCESO||!o.PRUEBAS)throw new Error('ACCESS-PASSWORD.txt debe tener ACCESO= y PRUEBAS=');
  if(o.ACCESO.length<6||o.PRUEBAS.length<6)throw new Error('Las contraseñas deben tener al menos 6 caracteres');
  if(o.ACCESO===o.PRUEBAS)throw new Error('La contraseña de pruebas debe ser distinta a la de acceso');
  return o;
}
function gcm(key,iv,data){const ci=c.createCipheriv('aes-256-gcm',key,iv);const ct=Buffer.concat([ci.update(data),ci.final()]);return Buffer.concat([ct,ci.getAuthTag()])}
const pw=readPw(),app=fs.readFileSync(path.join(D,'src/app.html'));
const cek=c.randomBytes(32);
function wrap(p){const salt=c.randomBytes(16),iv=c.randomBytes(12),k=c.pbkdf2Sync(p,salt,IT,32,'sha256');
  return {salt:salt.toString('base64'),iv:iv.toString('base64'),ct:gcm(k,iv,cek).toString('base64')}}
const piv=c.randomBytes(12);
const G={v:1,it:IT,w:{owner:wrap(pw.ACCESO),tester:wrap(pw.PRUEBAS)},p:{iv:piv.toString('base64'),ct:gcm(cek,piv,app).toString('base64')}};
const tpl=fs.readFileSync(path.join(D,'gate.template.html'),'utf8');
fs.writeFileSync(path.join(D,'index.html'),tpl.replace('/*GATE_DATA*/null',()=>JSON.stringify(G)));
console.log('index.html cifrado generado ('+Math.round(fs.statSync(path.join(D,'index.html')).size/1024)+' KB)');
