import json,sys,glob,os,re
from html.parser import HTMLParser
VOID={'area','base','br','col','embed','hr','img','input','link','meta','source','track','wbr'}
class N:
  def __init__(s,tag,attrs,parent=None): s.tag=tag;s.attrs=dict(attrs);s.kids=[];s.parent=parent
class P(HTMLParser):
  def __init__(s): super().__init__(convert_charrefs=True); s.root=N('root',[]); s.cur=s.root
  def handle_starttag(s,t,a):
    n=N(t,a,s.cur); s.cur.kids.append(n)
    if t not in VOID: s.cur=n
  def handle_startendtag(s,t,a): s.cur.kids.append(N(t,a,s.cur))
  def handle_endtag(s,t):
    c=s.cur
    while c is not None and c.tag!=t: c=c.parent
    if c is not None and c.parent is not None: s.cur=c.parent
  def handle_data(s,d):
    if d.strip(): s.cur.kids.append(' '.join(d.split()))
def parse(h):
  p=P(); p.feed(h); return p.root
def text(n): return ' '.join(k if isinstance(k,str) else text(k) for k in n.kids).strip()
def cls(n): return n.attrs.get('class') or ''
def sig(n,out):
  for k in n.kids:
    if isinstance(k,str): out.append('T:'+k); continue
    if k.tag=='i' and 'data-i' in k.attrs: out.append('ICON:'+k.attrs['data-i']+':'+' '.join(sorted(cls(k).split()))); continue
    if k.tag=='svg' and 'data-icon' in k.attrs: out.append('ICON:'+k.attrs['data-icon']+':'+' '.join(sorted(c for c in cls(k).split() if c!='lu-i'))); continue
    st=';'.join(sorted(x.strip().replace(' ','') for x in (k.attrs.get('style') or '').split(';') if x.strip()))
    out.append('<%s.%s[%s]'%(k.tag,'.'.join(sorted(cls(k).split())),st)); sig(k,out); out.append('>')
  return out
def find_all(n,pred,acc):
  for k in n.kids:
    if isinstance(k,str): continue
    if pred(k): acc.append(k)
    find_all(k,pred,acc)
  return acc
docs=json.load(open('vitrine/docs.json')); byname={d['name']:d['id'] for d in docs}
res={}
for f in sorted(glob.glob('canvas/G*Claro*.dc.html')):
  root=parse(open(f).read())
  for sec in find_all(root,lambda k:k.tag=='section',[]):
    h2=[k for k in find_all(sec,lambda k:k.tag=='h2',[])]
    if not h2: continue
    name=text(h2[0]); cid=byname.get(name)
    if not cid or not os.path.exists('vitrine/sec/%s.json'%cid): continue
    vs=json.load(open('vitrine/sec/%s.json'%cid))
    demos=[d for d in find_all(sec,lambda k:'lu-demo' in cls(k).split(),[]) if not find_all(d,lambda k:'lu-demo' in cls(k).split(),[])]
    for d in demos:
      sp=[k for k in d.kids if not isinstance(k,str) and 'lu-spec' in cls(k).split()]
      t=text(sp[0]) if sp else ''
      t0=re.sub(r'\s*·\s*em loop$','',t)
      idx=[i for i,x in enumerate(vs) if x['t'].strip()==t0.strip()]
      body=N('root',[]); body.kids=[k for k in d.kids if k not in sp]
      a=sig(body,[])
      if not idx: res.setdefault(cid,[]).append(('NO-MATCH',t,None)); continue
      b=sig(parse(vs[idx[0]]['h']),[])
      if a!=b:
        import difflib
        dd=[l for l in difflib.unified_diff(b,a,lineterm='',n=0) if l[:1] in '+-' and l[:3] not in ('+++','---')]
        res.setdefault(cid,[]).append(('DIFF',t,idx[0]+1,dd[:8],len(dd)))
      else: res.setdefault(cid,[]).append(('OK',t,idx[0]+1))
ok=sum(1 for v in res.values() for x in v if x[0]=='OK'); tot=sum(len(v) for v in res.values())
print('components',len(res),'demos',tot,'identical',ok)
for cid,v in sorted(res.items()):
  for x in v:
    if x[0]!='OK': print(cid,x[0],repr(x[1]),x[2] if len(x)>2 else '', (x[4] if len(x)>4 else ''), x[3][:4] if len(x)>3 else '')
