// PoseAI Onboarding v2 — real photography, no illustrations.

function Photo({ src, style, children }) {
  return (
    <div style={{
      position: 'absolute', inset: 0, overflow: 'hidden', ...style,
    }}>
      <img src={src} alt="" style={{
        width: '100%', height: '100%', objectFit: 'cover', display: 'block',
      }}/>
      {children}
    </div>
  );
}

function Dots({ i, total }) {
  return (
    <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
      {Array.from({ length: total }).map((_, k) => (
        <div key={k} style={{
          width: k === i ? 22 : 6, height: 6, borderRadius: 999,
          background: k === i ? '#fff' : 'rgba(255,255,255,0.35)',
          transition: 'width 200ms',
        }}/>
      ))}
    </div>
  );
}

function Screen({ photo, eyebrow, headline, sub, index, ctaHref, focalY = '50%' }) {
  return (
    <PhoneShell statusBarDark={true} homeIndicatorLight={true}>
      {/* full-bleed photo */}
      <div style={{ position: 'absolute', inset: 0 }}>
        <img src={photo} alt="" style={{
          width: '100%', height: '100%', objectFit: 'cover',
          objectPosition: `center ${focalY}`,
        }}/>
      </div>

      {/* top gradient for status bar */}
      <div style={{
        position: 'absolute', top: 0, left: 0, right: 0, height: 160, zIndex: 5,
        background: 'linear-gradient(180deg, rgba(0,0,0,0.5), transparent)',
        pointerEvents: 'none',
      }}/>

      {/* bottom gradient for text readability */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, height: 500, zIndex: 5,
        background: 'linear-gradient(180deg, rgba(10,10,15,0) 0%, rgba(10,10,15,0.75) 40%, rgba(10,10,15,0.98) 100%)',
        pointerEvents: 'none',
      }}/>

      {/* Skip button */}
      <div style={{
        position: 'absolute', top: 64, right: 24, zIndex: 20,
        padding: '6px 14px', borderRadius: 999,
        ...glass(),
        fontSize: 13, fontWeight: 500, color: '#fff', letterSpacing: -0.1,
      }}>Skip</div>

      {/* Content */}
      <div style={{
        position: 'absolute', bottom: 0, left: 0, right: 0, zIndex: 10,
        padding: '0 28px 48px',
      }}>
        {/* Eyebrow */}
        <div style={{
          fontFamily: 'ui-monospace, "SF Mono", Menlo, monospace',
          fontSize: 11, fontWeight: 600, letterSpacing: 2.2,
          color: 'rgba(255,255,255,0.7)', textTransform: 'uppercase',
          marginBottom: 14,
        }}>
          <span style={{
            background: GRADIENT, WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text',
          }}>{eyebrow}</span>
        </div>

        {/* Headline */}
        <h1 style={{
          margin: 0, fontSize: 36, fontWeight: 700, letterSpacing: -1.2,
          color: '#fff', lineHeight: 1.08,
        }}>{headline}</h1>

        <p style={{
          margin: '14px 0 0', fontSize: 15.5, lineHeight: 1.45,
          color: 'rgba(255,255,255,0.72)', letterSpacing: -0.2,
          maxWidth: 320,
        }}>{sub}</p>

        {/* Pager + CTA */}
        <div style={{
          marginTop: 36,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <Dots i={index} total={3}/>
          <a href={ctaHref} style={{
            textDecoration: 'none',
            height: 52, padding: '0 28px', borderRadius: 26,
            background: GRADIENT,
            boxShadow: '0 12px 26px rgba(236,72,153,0.45), inset 0 1px 0 rgba(255,255,255,0.25)',
            display: 'flex', alignItems: 'center', gap: 10,
            fontSize: 15.5, fontWeight: 700, color: '#fff', letterSpacing: -0.2,
          }}>
            {index === 2 ? 'Get Started' : 'Continue'}
            <svg width="14" height="12" viewBox="0 0 14 12"><path d="M8 1 L13 6 L8 11 M13 6 L1 6" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
          </a>
        </div>
      </div>
    </PhoneShell>
  );
}

function App() {
  return (
    <PageShell>
      <div style={{ display: 'flex', gap: 48, alignItems: 'center', flexWrap: 'wrap', justifyContent: 'center' }}>
        <Screen
          photo="https://images.unsplash.com/photo-1524638431109-93d95c968f03?w=900&q=85&auto=format&fit=crop"
          eyebrow="01 · Point"
          headline={<>Any scene.<br/>Instant pose ideas.</>}
          sub="Open the camera. Our on-device AI reads the light, location, and framing — and serves pose ideas that actually fit."
          index={0}
          ctaHref="PoseAI Paywall v2.html"
          focalY="30%"
        />
        <Screen
          photo="https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=900&q=85&auto=format&fit=crop"
          eyebrow="02 · Follow"
          headline={<>A live guide,<br/>drawn on you.</>}
          sub="Real-time body tracking overlays the target pose on screen. Match it, and we capture automatically."
          index={1}
          ctaHref="PoseAI Paywall v2.html"
          focalY="30%"
        />
        <Screen
          photo="https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=900&q=85&auto=format&fit=crop"
          eyebrow="03 · Capture"
          headline={<>Shots worth<br/>posting. Every time.</>}
          sub="Built by portrait photographers. 200+ poses, coaching that adapts to your body, and zero cloud uploads — ever."
          index={2}
          ctaHref="PoseAI Paywall v2.html"
          focalY="25%"
        />
      </div>
    </PageShell>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App/>);
