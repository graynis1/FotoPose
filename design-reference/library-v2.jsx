// PoseAI Library v2 — real photography everywhere

function Pill({ children, active }) {
  return (
    <span style={{
      padding: '7px 14px', borderRadius: 999,
      background: active ? '#fff' : 'rgba(255,255,255,0.06)',
      border: active ? 'none' : '0.5px solid rgba(255,255,255,0.1)',
      color: active ? '#0A0A0F' : 'rgba(255,255,255,0.85)',
      fontSize: 12.5, fontWeight: active ? 700 : 500, letterSpacing: -0.1,
      whiteSpace: 'nowrap',
    }}>{children}</span>
  );
}

const TRENDING = [
  { name: 'The Golden Gaze', uses: '24.3k', url: 'https://images.unsplash.com/photo-1524638431109-93d95c968f03?w=500&q=80&auto=format&fit=crop' },
  { name: 'Confident Lean', uses: '18.7k', url: 'https://images.unsplash.com/photo-1488716820095-cbe80883c496?w=500&q=80&auto=format&fit=crop' },
  { name: 'Over the Shoulder', uses: '15.2k', url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&q=80&auto=format&fit=crop' },
  { name: 'Power Stance', uses: '12.9k', url: 'https://images.unsplash.com/photo-1524502397800-2eeaad7c3fe5?w=500&q=80&auto=format&fit=crop' },
];

const GOLDEN = [
  { name: 'Sun Kiss',  url: 'https://images.unsplash.com/photo-1502323777036-f29e3972d82f?w=500&q=80&auto=format&fit=crop' },
  { name: 'Backlit',   url: 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=500&q=80&auto=format&fit=crop' },
  { name: 'Warm Glow', url: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&q=80&auto=format&fit=crop' },
];

const CATEGORIES = [
  { name: 'Classic Portrait', count: 42, url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&q=80&auto=format&fit=crop' },
  { name: 'Street Style',     count: 38, url: 'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=600&q=80&auto=format&fit=crop' },
  { name: 'Couple Poses',     count: 24, pro: true, url: 'https://images.unsplash.com/photo-1519741497674-611481863552?w=600&q=80&auto=format&fit=crop' },
  { name: 'Editorial',        count: 31, pro: true, url: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&q=80&auto=format&fit=crop' },
  { name: 'Wedding',          count: 47, pro: true, url: 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=600&q=80&auto=format&fit=crop' },
  { name: 'Group Shots',      count: 19, pro: true, url: 'https://images.unsplash.com/photo-1529333166437-7750a6dd5a70?w=600&q=80&auto=format&fit=crop' },
];

function TrendingCard({ p }) {
  return (
    <a href="PoseAI Pose Detail v2.html" style={{
      textDecoration: 'none', flexShrink: 0,
      width: 150, height: 210, borderRadius: 16, overflow: 'hidden',
      position: 'relative', border: '0.5px solid rgba(255,255,255,0.08)',
    }}>
      <img src={p.url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }}/>
      <div style={{
        position: 'absolute', inset: 0,
        background: 'linear-gradient(180deg, transparent 45%, rgba(0,0,0,0.85) 100%)',
      }}/>
      <div style={{ position: 'absolute', left: 12, right: 12, bottom: 10 }}>
        <div style={{ fontSize: 13.5, fontWeight: 700, color: '#fff', letterSpacing: -0.15, textShadow: '0 1px 4px rgba(0,0,0,0.6)' }}>
          {p.name}
        </div>
        <div style={{
          marginTop: 3, fontSize: 10.5, color: 'rgba(255,255,255,0.7)',
          fontFamily: 'ui-monospace, "SF Mono", monospace', letterSpacing: 0.2,
        }}>{p.uses} uses · this week</div>
      </div>
    </a>
  );
}

function GoldenCard({ p }) {
  return (
    <a href="PoseAI Pose Detail v2.html" style={{
      textDecoration: 'none', flexShrink: 0,
      width: 220, height: 140, borderRadius: 14, overflow: 'hidden', position: 'relative',
      border: '0.5px solid rgba(255,255,255,0.08)',
    }}>
      <img src={p.url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }}/>
      <div style={{ position: 'absolute', inset: 0,
        background: 'linear-gradient(180deg, transparent 50%, rgba(0,0,0,0.75))' }}/>
      <div style={{
        position: 'absolute', left: 12, bottom: 10,
        fontSize: 13, fontWeight: 700, color: '#fff', letterSpacing: -0.15,
        textShadow: '0 1px 4px rgba(0,0,0,0.5)',
      }}>{p.name}</div>
    </a>
  );
}

function CategoryCard({ c }) {
  return (
    <a href="PoseAI Pose Detail v2.html" style={{
      textDecoration: 'none',
      height: 160, borderRadius: 16, overflow: 'hidden', position: 'relative',
      border: '0.5px solid rgba(255,255,255,0.08)',
    }}>
      <img src={c.url} alt="" style={{
        width: '100%', height: '100%', objectFit: 'cover',
        filter: c.pro ? 'brightness(0.85)' : 'brightness(0.92)',
      }}/>
      <div style={{ position: 'absolute', inset: 0,
        background: 'linear-gradient(165deg, rgba(0,0,0,0.15) 0%, rgba(10,10,15,0.85) 100%)' }}/>
      {c.pro && (
        <div style={{
          position: 'absolute', top: 10, right: 10,
          padding: '3px 8px', borderRadius: 5,
          background: GRADIENT,
          fontSize: 9, fontWeight: 800, letterSpacing: 1, color: '#fff',
          display: 'flex', alignItems: 'center', gap: 4,
          boxShadow: '0 4px 10px rgba(236,72,153,0.4)',
        }}>{SF.lock('#fff', 9)} PRO</div>
      )}
      <div style={{ position: 'absolute', left: 12, right: 12, bottom: 12 }}>
        <div style={{ fontSize: 14.5, fontWeight: 700, color: '#fff', letterSpacing: -0.2 }}>{c.name}</div>
        <div style={{
          marginTop: 2, fontSize: 11, color: 'rgba(255,255,255,0.6)', letterSpacing: 0.2,
          fontFamily: 'ui-monospace, "SF Mono", monospace',
        }}>{c.count} poses</div>
      </div>
    </a>
  );
}

function Library() {
  return (
    <PhoneShell>
      <div style={{
        position: 'absolute', inset: 0, background: '#0A0A0F',
        overflowY: 'auto', paddingBottom: 110,
      }}>
        {/* Ambient glow */}
        <div style={{
          position: 'absolute', top: -140, right: -90, width: 320, height: 320, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(124,58,237,0.28), transparent 65%)',
          filter: 'blur(10px)', pointerEvents: 'none',
        }}/>

        {/* Title row */}
        <div style={{ padding: '60px 20px 0', position: 'relative' }}>
          <div style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end',
          }}>
            <div>
              <h1 style={{
                margin: 0, fontSize: 32, fontWeight: 700, letterSpacing: -1, color: '#fff',
              }}>Library</h1>
              <div style={{
                marginTop: 3, fontSize: 13, color: 'rgba(255,255,255,0.5)', letterSpacing: -0.15,
              }}>240 poses · curated by portrait photographers</div>
            </div>
            <div style={{
              width: 36, height: 36, borderRadius: '50%',
              ...glass(), display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
                <circle cx="6" cy="6" r="4.5" stroke="rgba(255,255,255,0.8)" strokeWidth="1.5"/>
                <line x1="9.5" y1="9.5" x2="12.5" y2="12.5" stroke="rgba(255,255,255,0.8)" strokeWidth="1.5" strokeLinecap="round"/>
              </svg>
            </div>
          </div>
        </div>

        {/* Filter pills */}
        <div style={{
          marginTop: 16, padding: '0 20px',
          display: 'flex', gap: 8, overflowX: 'auto',
        }}>
          <Pill active>All</Pill>
          <Pill>Solo</Pill>
          <Pill>Couple</Pill>
          <Pill>Group</Pill>
          <Pill>Outdoor</Pill>
          <Pill>Studio</Pill>
        </div>

        {/* Trending */}
        <div style={{ marginTop: 26 }}>
          <div style={{
            padding: '0 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          }}>
            <div style={{
              fontSize: 11, fontWeight: 700, letterSpacing: 1.8, textTransform: 'uppercase',
              fontFamily: 'ui-monospace, "SF Mono", monospace', color: 'rgba(255,255,255,0.5)',
            }}>Trending this week</div>
            <span style={{ fontSize: 12, color: '#EC4899', fontWeight: 600 }}>See all</span>
          </div>
          <div style={{
            marginTop: 12, padding: '0 20px',
            display: 'flex', gap: 10, overflowX: 'auto',
          }}>
            {TRENDING.map((p, i) => <TrendingCard key={i} p={p}/>)}
          </div>
        </div>

        {/* Golden hour */}
        <div style={{ marginTop: 26 }}>
          <div style={{ padding: '0 20px' }}>
            <div style={{
              display: 'flex', alignItems: 'center', gap: 7, marginBottom: 3,
            }}>
              <span style={{ fontSize: 15 }}>🌅</span>
              <div style={{
                fontSize: 16, fontWeight: 700, color: '#fff', letterSpacing: -0.3,
              }}>Perfect for Golden Hour</div>
            </div>
            <div style={{
              fontSize: 12.5, color: 'rgba(255,255,255,0.5)', letterSpacing: -0.15, marginLeft: 22,
            }}>It's 6:42 PM at your location · 18 min until sunset</div>
          </div>
          <div style={{
            marginTop: 12, padding: '0 20px',
            display: 'flex', gap: 10, overflowX: 'auto',
          }}>
            {GOLDEN.map((p, i) => <GoldenCard key={i} p={p}/>)}
          </div>
        </div>

        {/* Categories */}
        <div style={{ marginTop: 28, padding: '0 20px' }}>
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: 1.8, textTransform: 'uppercase',
            fontFamily: 'ui-monospace, "SF Mono", monospace', color: 'rgba(255,255,255,0.5)',
            marginBottom: 12,
          }}>Categories</div>
          <div style={{
            display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
          }}>
            {CATEGORIES.map((c, i) => <CategoryCard key={i} c={c}/>)}
          </div>
        </div>

        <div style={{ height: 24 }}/>
      </div>

      <TabBar active="library"/>
    </PhoneShell>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <PageShell><Library/></PageShell>
);
