// PoseAI Camera v2 — real photo viewfinder + live AR pose overlay + real pose thumbnails

function PoseOverlay() {
  // Target pose guide — drawn as thin gradient lines with joint dots at 30% opacity.
  // This is the actual product feature (AR guide), so lines stay as lines.
  return (
    <svg viewBox="0 0 393 600" style={{
      position: 'absolute', inset: 0, width: '100%', height: '100%',
      pointerEvents: 'none', zIndex: 10,
    }}>
      <defs>
        <linearGradient id="poseLine" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#A78BFA" stopOpacity="0.9"/>
          <stop offset="1" stopColor="#EC4899" stopOpacity="0.9"/>
        </linearGradient>
        <filter id="glow"><feGaussianBlur stdDeviation="2"/></filter>
      </defs>
      <g stroke="url(#poseLine)" strokeWidth="2.5" strokeLinecap="round" fill="none" opacity="0.55">
        {/* head */}
        <circle cx="200" cy="130" r="22"/>
        {/* spine */}
        <line x1="200" y1="152" x2="198" y2="310"/>
        {/* shoulders */}
        <line x1="170" y1="175" x2="232" y2="178"/>
        {/* left arm (slightly bent on hip) */}
        <line x1="170" y1="175" x2="152" y2="240"/>
        <line x1="152" y1="240" x2="180" y2="268"/>
        {/* right arm (falling) */}
        <line x1="232" y1="178" x2="250" y2="260"/>
        <line x1="250" y1="260" x2="245" y2="325"/>
        {/* hips */}
        <line x1="180" y1="310" x2="220" y2="310"/>
        {/* legs */}
        <line x1="188" y1="310" x2="180" y2="430"/>
        <line x1="180" y1="430" x2="178" y2="540"/>
        <line x1="212" y1="310" x2="222" y2="430"/>
        <line x1="222" y1="430" x2="228" y2="540"/>
      </g>
      {/* keypoint dots */}
      <g opacity="0.9">
        {[
          [200,130],[200,152],[170,175],[232,178],[152,240],[180,268],
          [250,260],[245,325],[200,310],[180,430],[222,430],[178,540],[228,540]
        ].map(([x,y], i) => (
          <g key={i}>
            <circle cx={x} cy={y} r="5" fill="#EC4899" opacity="0.3" filter="url(#glow)"/>
            <circle cx={x} cy={y} r="2.5" fill="#fff"/>
          </g>
        ))}
      </g>
    </svg>
  );
}

function GridLines() {
  return (
    <svg viewBox="0 0 393 852" style={{
      position: 'absolute', inset: 0, width: '100%', height: '100%',
      pointerEvents: 'none', zIndex: 5,
    }}>
      <g stroke="rgba(255,255,255,0.18)" strokeWidth="0.5">
        <line x1="131" y1="100" x2="131" y2="752"/>
        <line x1="262" y1="100" x2="262" y2="752"/>
        <line x1="0" y1="317" x2="393" y2="317"/>
        <line x1="0" y1="535" x2="393" y2="535"/>
      </g>
    </svg>
  );
}

const POSES = [
  { id: 'lean',    name: 'The Lean',       tag: 'Active',   url: 'https://images.unsplash.com/photo-1488716820095-cbe80883c496?w=500&q=80&auto=format&fit=crop' },
  { id: 'power',   name: 'Power Stance',   tag: 'Confidence', url: 'https://images.unsplash.com/photo-1524502397800-2eeaad7c3fe5?w=500&q=80&auto=format&fit=crop' },
  { id: 'gaze',    name: 'Golden Gaze',    tag: 'Editorial', url: 'https://images.unsplash.com/photo-1524638431109-93d95c968f03?w=500&q=80&auto=format&fit=crop' },
  { id: 'shoulder',name: 'Over Shoulder',  tag: 'Soft',     url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&q=80&auto=format&fit=crop' },
  { id: 'walk',    name: 'Walking Away',   tag: 'Movement', url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&q=80&auto=format&fit=crop' },
];

function Camera() {
  const [activeId, setActiveId] = React.useState('lean');
  return (
    <PhoneShell statusBarDark={true} homeIndicatorLight={true}>
      {/* Viewfinder: real photo as live feed */}
      <div style={{ position: 'absolute', inset: 0 }}>
        <img
          src="https://images.unsplash.com/photo-1496345875659-11f7dd282d1d?w=1000&q=85&auto=format&fit=crop"
          alt=""
          style={{ width: '100%', height: '100%', objectFit: 'cover', objectPosition: 'center 35%' }}
        />
      </div>

      {/* top gradient */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 170, zIndex: 6,
        background: 'linear-gradient(180deg, rgba(0,0,0,0.55), transparent)',
      }}/>

      {/* bottom gradient */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 360, zIndex: 6,
        background: 'linear-gradient(180deg, transparent, rgba(0,0,0,0.75))',
      }}/>

      {/* grid */}
      <GridLines/>

      {/* AR pose overlay on subject */}
      <div style={{ position: 'absolute', top: 60, left: 0, right: 0, bottom: 280, zIndex: 10 }}>
        <PoseOverlay/>
      </div>

      {/* Environment tag (top-left) */}
      <div style={{
        position: 'absolute', top: 62, left: 20, zIndex: 20,
        padding: '7px 12px 7px 10px', borderRadius: 999,
        ...glass({ background: 'rgba(0,0,0,0.4)' }),
        display: 'flex', alignItems: 'center', gap: 8,
        fontSize: 12, color: '#fff', letterSpacing: -0.1,
      }}>
        <span style={{
          width: 6, height: 6, borderRadius: '50%', background: '#10B981',
          boxShadow: '0 0 8px #10B981',
        }}/>
        <span style={{ fontWeight: 500 }}>Street · Golden Hour</span>
      </div>

      {/* Top-right icons row */}
      <div style={{
        position: 'absolute', top: 62, right: 20, zIndex: 20,
        display: 'flex', gap: 10,
      }}>
        {[SF.flash('#fff', 14), SF.timer('#fff', 18), SF.swap('#fff', 18)].map((icon, i) => (
          <div key={i} style={{
            width: 34, height: 34, borderRadius: '50%',
            ...glass({ background: 'rgba(0,0,0,0.4)' }),
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{icon}</div>
        ))}
      </div>

      {/* Detection chips, left column */}
      <div style={{
        position: 'absolute', top: 116, right: 20, zIndex: 20,
        display: 'flex', flexDirection: 'column', gap: 6, alignItems: 'flex-end',
      }}>
        {[
          { label: '1 person detected', dot: '#EC4899' },
          { label: 'Pose match · 78%', dot: '#A78BFA' },
          { label: 'Framing · good', dot: '#10B981' },
        ].map((c, i) => (
          <div key={i} style={{
            padding: '4px 9px', borderRadius: 999,
            ...glass({ background: 'rgba(0,0,0,0.45)' }),
            display: 'flex', alignItems: 'center', gap: 6,
            fontSize: 10.5, fontWeight: 500, color: 'rgba(255,255,255,0.92)', letterSpacing: -0.1,
          }}>
            <span style={{ width: 5, height: 5, borderRadius: '50%', background: c.dot }}/>
            {c.label}
          </div>
        ))}
      </div>

      {/* Focus reticle */}
      <div style={{
        position: 'absolute', left: 190, top: 300, width: 64, height: 64, zIndex: 15,
        border: '1px solid rgba(255,235,59,0.9)',
        borderRadius: 2, pointerEvents: 'none',
      }}/>

      {/* Coaching hint */}
      <div style={{
        position: 'absolute', left: '50%', bottom: 340, transform: 'translateX(-50%)', zIndex: 20,
        padding: '8px 14px', borderRadius: 999,
        ...glass({ background: 'rgba(0,0,0,0.5)' }),
        display: 'flex', alignItems: 'center', gap: 8,
        fontSize: 12.5, color: '#fff', fontWeight: 500, letterSpacing: -0.1,
        whiteSpace: 'nowrap',
      }}>
        <span>{SF.sparkles('url(#cg)', 13)}</span>
        <svg width="0" height="0"><defs>
          <linearGradient id="cg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stopColor="#A78BFA"/><stop offset="1" stopColor="#EC4899"/></linearGradient>
        </defs></svg>
        Tilt your chin slightly up — match the guide
      </div>

      {/* Pose scroller */}
      <div style={{
        position: 'absolute', bottom: 210, left: 0, right: 0, zIndex: 20,
        paddingLeft: 16,
      }}>
        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '0 18px 10px 4px',
        }}>
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: 1.6, textTransform: 'uppercase',
            fontFamily: 'ui-monospace, "SF Mono", monospace',
            color: 'rgba(255,255,255,0.55)',
          }}>Suggested poses</div>
          <a href="PoseAI Library v2.html" style={{
            textDecoration: 'none',
            fontSize: 12, color: '#EC4899', fontWeight: 600, letterSpacing: -0.1,
          }}>See all</a>
        </div>
        <div style={{
          display: 'flex', gap: 10, overflowX: 'auto', paddingRight: 16, paddingBottom: 4,
        }}>
          {POSES.map((p) => {
            const active = p.id === activeId;
            return (
              <a key={p.id} href={p.id === 'lean' ? 'PoseAI Pose Detail v2.html' : '#'}
                onClick={(e) => { if (p.id !== 'lean') { e.preventDefault(); setActiveId(p.id); } }}
                style={{
                  textDecoration: 'none', flexShrink: 0,
                  width: 88, height: 118, borderRadius: 14,
                  background: active ? GRADIENT : 'transparent',
                  padding: active ? 2 : 0,
                  boxShadow: active ? '0 10px 22px rgba(236,72,153,0.45)' : 'none',
                  position: 'relative',
                }}>
                <div style={{
                  width: '100%', height: '100%', borderRadius: 12.5, overflow: 'hidden',
                  border: active ? 'none' : '0.5px solid rgba(255,255,255,0.15)',
                  position: 'relative',
                }}>
                  <img src={p.url} alt="" style={{
                    width: '100%', height: '100%', objectFit: 'cover',
                  }}/>
                  {/* dark gradient bottom */}
                  <div style={{
                    position: 'absolute', inset: 0,
                    background: 'linear-gradient(180deg, transparent 40%, rgba(0,0,0,0.8))',
                  }}/>
                  <div style={{
                    position: 'absolute', left: 7, right: 7, bottom: 6,
                    fontSize: 11, fontWeight: 700, color: '#fff', letterSpacing: -0.1,
                    textShadow: '0 1px 4px rgba(0,0,0,0.5)',
                  }}>{p.name}</div>
                  {active && (
                    <div style={{
                      position: 'absolute', top: 5, right: 5,
                      width: 16, height: 16, borderRadius: '50%', background: '#fff',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>{SF.checkmark('#EC4899', 10)}</div>
                  )}
                </div>
              </a>
            );
          })}
        </div>
      </div>

      {/* Shutter row */}
      <div style={{
        position: 'absolute', bottom: 100, left: 0, right: 0, zIndex: 25,
        display: 'flex', alignItems: 'center', justifyContent: 'space-around',
        padding: '0 32px',
      }}>
        {/* gallery thumbnail */}
        <a href="PoseAI Library v2.html" style={{
          textDecoration: 'none',
          width: 44, height: 44, borderRadius: 10, overflow: 'hidden',
          border: '1.5px solid rgba(255,255,255,0.6)',
        }}>
          <img src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&q=80&auto=format&fit=crop"
               alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }}/>
        </a>

        {/* shutter */}
        <div style={{
          width: 78, height: 78, borderRadius: '50%',
          border: '4px solid #fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <div style={{
            width: 62, height: 62, borderRadius: '50%', background: '#fff',
            boxShadow: 'inset 0 0 0 2px rgba(0,0,0,0.06)',
          }}/>
        </div>

        {/* mode */}
        <div style={{
          width: 44, height: 44, borderRadius: '50%',
          ...glass({ background: 'rgba(255,255,255,0.15)' }),
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>{SF.sparkles('#fff', 16)}</div>
      </div>

      {/* Mode strip */}
      <div style={{
        position: 'absolute', bottom: 188, left: 0, right: 0, zIndex: 24,
        display: 'flex', justifyContent: 'center', gap: 22,
        fontSize: 11, fontWeight: 600, letterSpacing: 1.4, textTransform: 'uppercase',
        color: 'rgba(255,255,255,0.5)',
      }}>
        <span>VIDEO</span>
        <span style={{ color: '#EC4899' }}>PHOTO</span>
        <span>PORTRAIT</span>
      </div>

      <TabBar active="camera"/>
    </PhoneShell>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <PageShell><Camera/></PageShell>
);
