"""Generate the faceted SVG logos in this directory.

  python3 generate.py OUTDIR            # rounded tiles, for READMEs
  python3 generate.py OUTDIR --square   # square corners, for Slack (it rounds icons itself)

Writes weka.svg, weka-alerts.svg (the Slack alerts bot) and rosegrove.svg (the
Slack workspace). Shapes are plain coordinates and colours, so tweak the
numbers below rather than editing the SVGs. `just logos` regenerates everything.
"""
import math, sys
out = sys.argv[1]
radius = 0 if "--square" in sys.argv[2:] else 28
def tile(label, defs, body):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" role="img" aria-label="{label}">
  <defs>
    <clipPath id="t"><rect width="128" height="128" rx="{radius}"/></clipPath>
{defs}  </defs>
  <g clip-path="url(#t)">
{body}
  </g>
</svg>
'''
def tri(pts, c, seam=True):
    s = f' stroke="{c}" stroke-width=".5" stroke-linejoin="round"' if seam else ''
    return '    <polygon points="%s" fill="%s"%s/>' % (" ".join(f"{x:.1f},{y:.1f}" for x,y in pts), c, s)

# ---------------- WEKA ----------------
P = dict(T=(20,42), B0=(35,56), B2=(62,47), NT=(85,40),
         HB=(86,32), HT=(96,27), BT=(105,32), BK=(120,40.5), BM=(105,38), BB=(105,44), J=(97,48),
         C=(95,71), E1=(82,84), E2=(60,89), R=(31,74), TU=(32,63), M=(60,68), N=(87,53))
F = [
 ("T B0 TU","#3F2410"), ("T TU R","#2E1A0B"),
 ("B0 B2 M","#D39A5C"), ("B0 M TU","#B47A44"), ("B2 NT N","#E2AB6B"), ("B2 N M","#C48848"),
 ("TU M R","#8C5A2D"), ("R M E2","#583519"), ("M E1 E2","#6B4220"), ("M N E1","#7E5029"), ("N C E1","#6E5238"),
 ("N NT HB","#B88A5E"), ("N HB J","#9A7A5C"), ("HB HT BT","#C9A27A"), ("HB BT J","#A4825F"), ("J BT BB","#8C6C50"),
 ("N J C","#7E654C"),
 ("BT BK BM","#F0C2A0"), ("BM BK BB","#C88B68"),
]
w = [tri([P[k] for k in ks.split()], c) for ks,c in F]
wdefs = '    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#B4ECF0"/><stop offset="1" stop-color="#4FB8C4"/></linearGradient>\n'
ground = "\n".join([
 '    <rect width="128" height="128" fill="url(#sky)"/>',
 tri([(0,104),(40,100),(0,128)],"#8FCB7A",False), tri([(40,100),(90,102),(0,128)],"#7DBD6A",False),
 tri([(90,102),(128,106),(128,128)],"#8FCB7A",False), tri([(90,102),(128,128),(0,128)],"#6AAE5C",False),
 '    <ellipse cx="66" cy="106" rx="30" ry="2.6" fill="#2E5A2A" opacity=".3"/>'])
legs = '''    <g stroke-linecap="round" stroke-linejoin="round" fill="none">
      <path d="M59 88 L55 105" stroke="#7A4A30" stroke-width="4.6"/><path d="M76 84 L79 105" stroke="#946048" stroke-width="4.6"/>
      <path d="M48 106 L55 105 L62 106.5 M55 105 L52 107" stroke="#7A4A30" stroke-width="2.6"/>
      <path d="M74 106 L80 105 L88 106 M80 105 L77 107" stroke="#946048" stroke-width="2.6"/>
    </g>'''
eye = '    <circle cx="97.5" cy="36" r="2.4" fill="#A62A22"/><circle cx="97.7" cy="36" r="1.2" fill="#1A0D05"/><circle cx="98.3" cy="35.3" r=".6" fill="#fff"/>'
weka_body = "\n".join([ground, legs, *w, eye])
open(f"{out}/weka.svg","w").write(tile("weka", wdefs, weka_body))
badge = '''    <circle cx="24" cy="22" r="12" fill="#E5484D" stroke="#fff" stroke-width="3"/>
    <path d="M24 15 L24 24" stroke="#fff" stroke-width="4" stroke-linecap="round"/>
    <circle cx="24" cy="29" r="2.2" fill="#fff"/>'''
open(f"{out}/weka-alerts.svg","w").write(tile("weka alerts", wdefs, weka_body+"\n"+badge))

# ---------------- ROSE ----------------
cx, cy = 64, 44
def pol(r, a): return (cx + r*math.cos(math.radians(a)), cy + r*math.sin(math.radians(a)))
rings = [  # (radius, vertices, rotation, light, dark)
    (27, 7, -12, "#B81A35", "#8E1129"),
    (21, 6,  22, "#D7263D", "#A3162F"),
    (14.5, 5,  58, "#EC4A5F", "#C41E3A"),
    (8,  4,  96, "#FF8E9E", "#E2364C"),
]
jit = [1.0, 0.86, 1.08, 0.92, 1.04, 0.88, 1.0]
rose = []
for k,(r,n,rot,light,dark) in enumerate(rings):
    vs = [pol(r*jit[(i+k)%len(jit)], rot + 360/n*i + (6 if i%2 else -4)) for i in range(n)]
    # offset each ring's hub slightly so facets twist rather than radiate evenly
    hub = pol(r*0.12, rot+200)
    for i in range(n):
        rose.append(tri([hub, vs[i], vs[(i+1)%n]], light if i%2==0 else dark))
def tree(x, base, h, wd, light, dark):
    return tri([(x,base-h),(x-wd,base),(x+wd*0.1,base)],light,False)+"\n"+tri([(x,base-h),(x+wd*0.1,base),(x+wd,base)],dark,False)
rdefs = '    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFE7A8"/><stop offset="1" stop-color="#F9C97A"/></linearGradient>\n'
rbody = "\n".join([
    '    <rect width="128" height="128" fill="url(#sky)"/>',
    tree(18,112,52,12,"#7FBF6E","#4E9A55"), tree(36,112,36,9,"#9CD088","#6BAE62"),
    tree(108,112,58,13,"#7FBF6E","#4E9A55"), tree(90,112,38,9,"#9CD088","#6BAE62"),
    tri([(0,110),(70,108),(0,128)],"#4A9550",False), tri([(70,108),(128,111),(128,128)],"#4A9550",False), tri([(70,108),(128,128),(0,128)],"#3F8A48",False),
    '    <path d="M64 62 L63 110" stroke="#2E6B35" stroke-width="4"/>',
    tri([(63.5,96),(42,86),(55,80)],"#5BA75E"), tri([(63.5,96),(55,80),(63.5,88)],"#2E6B35"),
    tri([(64,84),(86,72),(73,68)],"#5BA75E"), tri([(64,84),(73,68),(64,76)],"#2E6B35"),
    tri([(64,68),(56,60),(64,62)],"#3E8A45"), tri([(64,68),(72,60),(64,62)],"#2E6B35"),
    *rose])
open(f"{out}/rosegrove.svg","w").write(tile("rosegrove", rdefs, rbody))
