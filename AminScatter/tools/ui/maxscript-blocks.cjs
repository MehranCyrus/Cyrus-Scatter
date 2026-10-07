function close(text,start){
 let depth=0,string=false,comment=false,block=false;
 for(let i=start;i<text.length;i++){
  const c=text[i],n=text[i+1];
  if(comment){if(c==='\n')comment=false;continue;}
  if(block){if(c==='*'&&n==='/'){block=false;i++;}continue;}
  if(string){if(c==='\\'){i++;continue;}if(c==='"')string=false;continue;}
  if(c==='-'&&n==='-'){comment=true;i++;continue;}
  if(c==='/'&&n==='*'){block=true;i++;continue;}
  if(c==='"'){string=true;continue;}
  if(c==='(')depth++;if(c===')'&&--depth===0)return i+1;
 }
 throw Error('Unclosed MAXScript block at '+start);
}
function span(s,re){
 const m=re.exec(s);if(!m)throw Error('Missing unified declaration: '+re);
 const a=m.index,b=s.indexOf('(',a);return [a,close(s,b)];
}
function fn(s,name,body){
 const re=new RegExp('^    fn '+name+'\\b[^\\n]*= \\(','m');
 const [a,b]=span(s,re);return s.slice(0,a)+(body||'')+s.slice(b);
}
function rollout(s,name,body){
 const re=new RegExp('^    rollout '+name+' "[^"\\n]+"[^\\n]*\\(','m');
 const [a,b]=span(s,re);return s.slice(0,a)+body+s.slice(b);
}
module.exports={close,span,fn,rollout};
