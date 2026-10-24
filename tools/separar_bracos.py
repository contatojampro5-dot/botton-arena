import numpy as np, json, os
from PIL import Image, ImageDraw
from scipy import ndimage
import os, sys
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src=ROOT+'/assets/chars'
dst=ROOT+'/assets/rig'
os.makedirs(dst,exist_ok=True)
# ellipse (cx,cy,rx,ry), L rect, R rect (x0,y0,x1,y1), L pivot, R pivot  (pixels of the 440px art)
SPEC={
 'prototipo':((245,165,170,158),(0,195,125,425),(345,255,440,425),(88,232),(385,272)),
 'chamas':   ((235,210,145,128),(0,215,120,400),(325,255,400,410),(98,238),(345,268)),
 'sombras':  ((220,215,135,125),(0,225,112,400),(300,288,381,410),(78,246),(330,300)),
 'floresta': ((240,210,150,135),(0,205,122,400),(345,262,433,440),(95,225),(365,280)),
 'ventos':   ((225,215,125,103),(20,232,112,350),(295,290,370,400),(100,250),(315,300)),
 'mares':    ((230,205,145,118),(0,235,102,400),(310,288,393,430),(85,252),(330,300)),
 'glacial':  ((210,225,150,128),(0,255,102,410),(298,292,378,430),(75,275),(320,305)),
 'solar':    ((205,225,150,120),(0,258,97,400),(300,288,380,430),(65,280),(315,300)),
 'colosso':  ((205,210,150,128),(0,240,102,415),(295,280,379,440),(70,255),(320,295)),
 'steampunk':((220,200,140,112),(20,218,127,360),(305,248,385,395),(95,235),(320,262)),
 'cosmico':  ((230,200,160,140),(0,235,112,365),(340,288,425,430),(95,255),(360,300)),
 'alquimista':((225,215,115,115),(0,232,108,350),(298,244,374,350),(112,250),(292,268)),
}
rig={}
prev=[]
for n,(el,LR,RR,LP,RP) in SPEC.items():
    im=Image.open(f'{src}/{n}.png').convert('RGBA'); a=np.array(im)
    H,W=a.shape[:2]
    yy,xx=np.mgrid[0:H,0:W]
    cx,cy,rx,ry=el
    outside=((xx-cx)/rx)**2+((yy-cy)/ry)**2>1.0
    alpha=a[...,3]>8
    info={'W':W,'H':H}
    body=a.copy()
    for side,rect,piv in (('L',LR,LP),('R',RR,RP)):
        x0,y0,x1,y1=rect
        inr=(xx>=x0)&(xx<x1)&(yy>=y0)&(yy<y1)
        m=alpha&inr&outside
        # mantém só o maior pedaço + pedaços grandes (evita levar faíscas soltas)
        lab,nl=ndimage.label(ndimage.binary_dilation(m,iterations=2))
        if nl>1:
            sizes=ndimage.sum(m,lab,range(1,nl+1))
            keep=np.zeros_like(m)
            big=max(sizes)
            for i,s in enumerate(sizes):
                if s>=big*0.25: keep|=(lab==i+1)
            m&=keep
        # borda suave: piece alpha
        piece=np.zeros_like(a); piece[m]=a[m]
        body[m]=0
        ys,xs=np.where(m)
        bx0,by0,bx1,by1=xs.min(),ys.min(),xs.max()+1,ys.max()+1
        Image.fromarray(piece[by0:by1,bx0:bx1]).save(f'{dst}/{n}_arm{side}.png',optimize=True)
        dd=(xs-piv[0])**2+(ys-piv[1])**2
        k=np.argsort(dd)[-max(1,len(dd)//40):]
        hx,hy=float(xs[k].mean()),float(ys[k].mean())
        info['arm'+side]={'x':int(bx0),'y':int(by0),'w':int(bx1-bx0),'h':int(by1-by0),'px':piv[0],'py':piv[1],'hx':round(hx,1),'hy':round(hy,1)}
    Image.fromarray(body).save(f'{dst}/{n}_body.png',optimize=True)
    rig[n]=info
    # pré-visualização: braços afastados e girados
    vis=Image.new('RGBA',(W+160,H+40),(40,40,52,255))
    vis.alpha_composite(Image.fromarray(body),(80,20))
    for side,dx,rot in (('L',-60,25),('R',60,-35)):
        ai=info['arm'+side]
        p=Image.open(f'{dst}/{n}_arm{side}.png')
        # gira em torno do ombro
        canvas=Image.new('RGBA',(W,H),(0,0,0,0)); canvas.alpha_composite(p,(ai['x'],ai['y']))
        canvas=canvas.rotate(rot,center=(ai['px'],ai['py']),resample=Image.BICUBIC)
        vis.alpha_composite(canvas,(80+dx,20))
    d=ImageDraw.Draw(vis)
    for side in 'LR':
        ai=info['arm'+side]; d.ellipse([80+ai['px']-5+(-60 if side=='L' else 60),20+ai['py']-5,80+ai['px']+5+(-60 if side=='L' else 60),20+ai['py']+5],fill=(255,255,0,255))
    d.text((6,6),n,fill='white')
    vis.thumbnail((300,300)); prev.append(vis)
json.dump(rig,open(f'{dst}/rig.json','w'),indent=1)
g=Image.new('RGBA',(300*6,300*2),(0,0,0,255))
for i,t in enumerate(prev): g.alpha_composite(t,((i%6)*300,(i//6)*300))
g.save(ROOT+'/tools/separar_bracos_previa.png'); print('ok')
