// PoseAI Pose Detail v2 — editorial real photo, bottom sheet

function Chip({ label, accent }) {
  return (
    <span style={{
      padding: '4px 10px', borderRadius: 999,
      background: accent ? 'rgba(236,72,153,0.15)' : 'rgba(255,255,255,0.08)',
      border: `0.5px solid ${accent ? 'rgba(236,72,153,0.4)' : 'rgba(255,255,255,0.1)'}`,
      fontSize: 11, fontWeight: 500, letterSpacing: -0.1,
      color: accent ? '#F472B6' : 'rgba(255,255,255,0.85)',
    }}>{label}</span>
  );
}

function Tip({ icon, title, body }) {
  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
      <div style={{
        width: 30, height: 30, borderRadius: 8, flexShrink: 0,
        background: 'rgba(236,72,153,0.12)',
        border: '0.5px solid rgba(236,72,153,0.25)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0, paddingTop: 1 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: '#fff', letterSpacing: -0.15 }}>{title}</div>
        <div style={{ marginTop: 2, fontSize: 12.5, color: 'rgba(255,255,255,0.6)', lineHeight: 1.4, letterSpacing: -0.1 }}>{body}</div>
      </div>
    </div>
  );
}

function PoseDetail() {
  return (
    <PhoneShell>
      {/* Blurred camera feed behind */}
      <div style={{ position: 'absolute', inset: 0 }}>
        <img src="https://images.unsplash.com/photo-1496345875659-11f7dd282d1d?w=1000&q=75&auto=format&fit=crop"
             alt="" style={{
               width: '100%', height: '100%', objectFit: 'cover',
               filter: 'blur(22px) brightness(0.45)', transform: 'scale(1.12)',
             }}/>
      </div>
      <div style={{ position: 'absolute', inset: 0, background: 'rgba(10,10,15,0.55)' }}/>

      {/* Sheet */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0,
        height: 750, borderRadius: '24px 24px 0 0',
        background: '#0E0E14',
        border: '0.5px solid rgba(255,255,255,0.08)',
        overflow: 'hidden',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* Handle */}
        <div style={{ padding: '10px 0 4px', display: 'flex', justifyContent: 'center' }}>
          <div style={{ width: 38, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.25)' }}/>
        </div>

        {/* Header row */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '8px 20px 12px',
        }}>
          <div style={{
            fontSize: 11, fontWeight: 700, letterSpacing: 1.8, textTransform: 'uppercase',
            fontFamily: 'ui-monospace, "SF Mono", monospace',
            color: 'rgba(255,255,255,0.45)',
          }}>Pose Details</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ width: 30, height: 30, borderRadius: '50%',
              background: 'rgba(255,255,255,0.08)',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {SF.bookmark('rgba(255,255,255,0.75)', 12)}
            </div>
            <div style={{ width: 30, height: 30, borderRadius: '50%',
              background: 'rgba(255,255,255,0.08)',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              {SF.shareUp('rgba(255,255,255,0.75)', 13)}
            </div>
          </div>
        </div>

        {/* Scrollable body */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '0 20px 24px' }}>

          {/* Large editorial photo */}
          <div style={{
            width: '100%', height: 360, borderRadius: 18, overflow: 'hidden',
            position: 'relative', boxShadow: '0 24px 40px rgba(0,0,0,0.4)',
          }}>
            <img src="https://images.unsplash.com/photo-1488716820095-cbe80883c496?w=800&q=85&auto=format&fit=crop"
                 alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }}/>
            {/* pro badge */}
            <div style={{
              position: 'absolute', top: 12, left: 12,
              padding: '4px 10px', borderRadius: 999,
              background: GRADIENT, color: '#fff',
              fontSize: 10, fontWeight: 800, letterSpacing: 1.2,
              boxShadow: '0 6px 14px rgba(236,72,153,0.4)',
              display: 'flex', alignItems: 'center', gap: 4,
            }}>{SF.sparkles('#fff', 10)} PRO</div>
            {/* credit */}
            <div style={{
              position: 'absolute', bottom: 10, right: 12,
              fontSize: 10, color: 'rgba(255,255,255,0.65)', letterSpacing: 0.2,
              textShadow: '0 1px 4px rgba(0,0,0,0.5)',
            }}>Photo: Unsplash</div>
          </div>

          {/* Title + tags */}
          <div style={{ marginTop: 18 }}>
            <h1 style={{
              margin: 0, fontSize: 26, fontWeight: 700, letterSpacing: -0.8, color: '#fff',
            }}>The Confident Lean</h1>
            <div style={{ marginTop: 3, fontSize: 13, color: 'rgba(255,255,255,0.55)', letterSpacing: -0.15 }}>
              Editorial · Solo · Medium effort
            </div>
            <div style={{ marginTop: 10, display: 'flex', gap: 6, flexWrap: 'wrap' }}>
              <Chip label="Golden hour"/>
              <Chip label="Full body"/>
              <Chip label="Outdoor"/>
              <Chip label="Flattering" accent/>
            </div>
          </div>

          {/* Lighting match */}
          <div style={{
            marginTop: 18, padding: '14px 14px', borderRadius: 14,
            ...glass({ background: 'rgba(16,185,129,0.08)' }),
            border: '0.5px solid rgba(16,185,129,0.25)',
            display: 'flex', alignItems: 'center', gap: 12,
          }}>
            <div style={{
              width: 38, height: 38, borderRadius: '50%',
              background: 'rgba(16,185,129,0.15)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>{SF.checkmark('#10B981', 18)}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: '#fff', letterSpacing: -0.15 }}>
                Your lighting is a match
              </div>
              <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.55)', marginTop: 1, letterSpacing: -0.1 }}>
                Golden hour detected · 92% confidence
              </div>
            </div>
          </div>

          {/* Pro tips */}
          <div style={{
            marginTop: 20, fontSize: 11, fontWeight: 700, letterSpacing: 1.8, textTransform: 'uppercase',
            fontFamily: 'ui-monospace, "SF Mono", monospace',
            color: 'rgba(255,255,255,0.45)',
          }}>Pro tips</div>

          <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 14 }}>
            <Tip icon={SF.bolt2('#EC4899', 12)} title="Shift weight to one hip"
              body="A 60/40 weight distribution creates a natural S-curve through the body."/>
            <Tip icon={SF.sparkles('#EC4899', 13)} title="Eyes off-camera"
              body="Look past the lens to a point 20° left. Reads as cinematic, not posed."/>
            <Tip icon={SF.camera('#EC4899', 14)} title="Lower your angle"
              body="Shoot from chest height for balance — avoid the top-down selfie look."/>
          </div>

          {/* Similar poses */}
          <div style={{
            marginTop: 22, fontSize: 11, fontWeight: 700, letterSpacing: 1.8, textTransform: 'uppercase',
            fontFamily: 'ui-monospace, "SF Mono", monospace',
            color: 'rgba(255,255,255,0.45)',
          }}>Similar poses</div>

          <div style={{ marginTop: 10, display: 'flex', gap: 10, overflowX: 'auto', paddingBottom: 4 }}>
            {[
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&q=80&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1524502397800-2eeaad7c3fe5?w=400&q=80&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80&auto=format&fit=crop',
              'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&q=80&auto=format&fit=crop',
            ].map((u, i) => (
              <div key={i} style={{
                flexShrink: 0, width: 90, height: 120, borderRadius: 12, overflow: 'hidden',
                border: '0.5px solid rgba(255,255,255,0.1)',
              }}>
                <img src={u} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }}/>
              </div>
            ))}
          </div>

          {/* CTA */}
          <div style={{ marginTop: 22, display: 'flex', gap: 10 }}>
            <button style={{
              width: 54, height: 54, borderRadius: 14, border: 'none', cursor: 'pointer',
              ...glass({ background: 'rgba(255,255,255,0.08)' }),
              fontFamily: 'inherit',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>{SF.heart('#fff', 18)}</button>
            <a href="PoseAI Camera v2.html" style={{
              textDecoration: 'none', flex: 1,
              height: 54, borderRadius: 27, background: GRADIENT,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
              fontSize: 15.5, fontWeight: 700, color: '#fff', letterSpacing: -0.2,
              boxShadow: '0 12px 28px rgba(236,72,153,0.45), inset 0 1px 0 rgba(255,255,255,0.25)',
            }}>
              {SF.camera('#fff', 18)} Use This Pose
            </a>
          </div>
        </div>
      </div>
    </PhoneShell>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <PageShell><PoseDetail/></PageShell>
);
