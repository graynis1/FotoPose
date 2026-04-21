// PoseAI Paywall v2 — real hero photo, SF Symbol features, plan cards

function Feature({ icon, title, sub }) {
  return (
    <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10, flexShrink: 0,
        background: 'linear-gradient(135deg, rgba(167,139,250,0.18), rgba(236,72,153,0.18))',
        border: '0.5px solid rgba(236,72,153,0.3)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0, paddingTop: 2 }}>
        <div style={{ fontSize: 14.5, fontWeight: 600, color: '#fff', letterSpacing: -0.2 }}>{title}</div>
        <div style={{ marginTop: 2, fontSize: 12.5, color: 'rgba(255,255,255,0.55)', letterSpacing: -0.1, lineHeight: 1.4 }}>{sub}</div>
      </div>
    </div>
  );
}

function Plan({ selected, title, price, per, sub, badge }) {
  return (
    <div style={{
      flex: 1, padding: 2, borderRadius: 16,
      background: selected ? GRADIENT : 'rgba(255,255,255,0.1)',
      position: 'relative',
      boxShadow: selected ? '0 10px 28px rgba(236,72,153,0.35)' : 'none',
    }}>
      {badge && (
        <div style={{
          position: 'absolute', top: -10, right: 10, zIndex: 2,
          padding: '3px 9px', borderRadius: 6,
          background: '#F472B6', color: '#fff',
          fontSize: 10, fontWeight: 800, letterSpacing: 0.6,
          boxShadow: '0 4px 10px rgba(236,72,153,0.5)',
        }}>{badge}</div>
      )}
      <div style={{
        borderRadius: 14.5, background: '#0F0B18',
        padding: '14px 14px 16px',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <span style={{ fontSize: 12.5, fontWeight: 600, color: 'rgba(255,255,255,0.75)', letterSpacing: -0.1 }}>{title}</span>
          <div style={{
            width: 18, height: 18, borderRadius: '50%',
            border: '1.5px solid',
            borderColor: selected ? 'transparent' : 'rgba(255,255,255,0.25)',
            background: selected ? GRADIENT : 'transparent',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {selected && SF.checkmark('#fff', 10)}
          </div>
        </div>
        <div style={{ marginTop: 8, display: 'flex', alignItems: 'baseline', gap: 4 }}>
          <span style={{ fontSize: 24, fontWeight: 800, color: '#fff', letterSpacing: -0.8 }}>{price}</span>
          <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.5)', letterSpacing: -0.1 }}>/{per}</span>
        </div>
        <div style={{ marginTop: 2, fontSize: 11.5, color: 'rgba(255,255,255,0.5)', letterSpacing: -0.1 }}>{sub}</div>
      </div>
    </div>
  );
}

function Paywall() {
  return (
    <PhoneShell>
      {/* Scrollable content */}
      <div style={{
        position: 'absolute', inset: 0, overflowY: 'auto', background: '#0A0A0F',
      }}>

        {/* Hero photo */}
        <div style={{ position: 'relative', width: '100%', height: 440 }}>
          <img src="https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=1000&q=85&auto=format&fit=crop"
               alt="" style={{ width: '100%', height: '100%', objectFit: 'cover', objectPosition: 'center 30%' }}/>

          {/* top overlay for status */}
          <div style={{
            position: 'absolute', top: 0, left: 0, right: 0, height: 100,
            background: 'linear-gradient(180deg, rgba(0,0,0,0.4), transparent)',
          }}/>

          {/* close */}
          <div style={{
            position: 'absolute', top: 62, right: 20, width: 32, height: 32, borderRadius: '50%',
            ...glass({ background: 'rgba(0,0,0,0.35)' }),
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{SF.close('#fff', 14)}</div>

          {/* Restore */}
          <div style={{
            position: 'absolute', top: 66, left: 20,
            fontSize: 13, color: 'rgba(255,255,255,0.85)', letterSpacing: -0.1, fontWeight: 500,
          }}>Restore</div>

          {/* bottom gradient to blend into content */}
          <div style={{
            position: 'absolute', bottom: 0, left: 0, right: 0, height: 180,
            background: 'linear-gradient(180deg, transparent, #0A0A0F)',
          }}/>

          {/* PRO Badge floating */}
          <div style={{
            position: 'absolute', left: '50%', bottom: 130, transform: 'translateX(-50%)',
            padding: '5px 14px', borderRadius: 999,
            background: GRADIENT,
            boxShadow: '0 10px 25px rgba(236,72,153,0.5)',
            display: 'flex', alignItems: 'center', gap: 6,
            fontSize: 11, fontWeight: 800, letterSpacing: 1.4, color: '#fff',
          }}>
            {SF.sparkles('#fff', 12)} POSEAI PRO
          </div>

          {/* Social proof avatars */}
          <div style={{
            position: 'absolute', bottom: 74, left: 0, right: 0,
            display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 10,
          }}>
            <div style={{ display: 'flex' }}>
              {[
                'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100&q=80&auto=format&fit=crop',
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&q=80&auto=format&fit=crop',
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&q=80&auto=format&fit=crop',
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&q=80&auto=format&fit=crop',
              ].map((u, i) => (
                <img key={i} src={u} alt="" style={{
                  width: 22, height: 22, borderRadius: '50%', objectFit: 'cover',
                  border: '2px solid #0A0A0F',
                  marginLeft: i === 0 ? 0 : -6,
                }}/>
              ))}
            </div>
            <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.7)', letterSpacing: -0.1 }}>
              <span style={{ color: '#fff', fontWeight: 600 }}>240,000+</span> photographers
            </div>
          </div>

          {/* rating row */}
          <div style={{
            position: 'absolute', bottom: 44, left: 0, right: 0,
            display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 6,
          }}>
            <div style={{ display: 'flex', gap: 2 }}>
              {Array.from({ length: 5 }).map((_, i) => (
                <span key={i}>{SF.star('#FBBF24', 11)}</span>
              ))}
            </div>
            <span style={{ fontSize: 11, color: 'rgba(255,255,255,0.65)', letterSpacing: -0.1 }}>
              4.9 · App Store
            </span>
          </div>
        </div>

        {/* Headline */}
        <div style={{ padding: '0 28px', marginTop: -30, position: 'relative', zIndex: 2 }}>
          <h1 style={{
            margin: 0, fontSize: 30, fontWeight: 800, letterSpacing: -1.2,
            color: '#fff', lineHeight: 1.08, textAlign: 'center',
          }}>
            Shoot like<br/>you mean it.
          </h1>
          <p style={{
            margin: '10px auto 0', textAlign: 'center', maxWidth: 290,
            fontSize: 14, color: 'rgba(255,255,255,0.6)', letterSpacing: -0.15, lineHeight: 1.45,
          }}>
            200+ editorial poses, live AR guidance, and coaching that adapts to your body. No ads. No cloud.
          </p>
        </div>

        {/* Features */}
        <div style={{
          margin: '28px 20px 0', padding: '18px 18px',
          borderRadius: 16, ...glass(),
          display: 'flex', flexDirection: 'column', gap: 16,
        }}>
          <Feature icon={SF.sparkles('url(#g1)', 16)}
            title="Unlimited AI pose suggestions"
            sub="Live environment + body-aware recommendations, any lighting."
          />
          <Feature icon={SF.bolt2('url(#g1)', 14)}
            title="Full pose library · 240+ poses"
            sub="Editorial, couple, wedding, street & group modes."
          />
          <Feature icon={SF.camera('url(#g1)', 18)}
            title="Live AR pose overlay"
            sub="Match target poses in real time with body tracking."
          />
          <Feature icon={SF.lock('url(#g1)', 14)}
            title="100% on-device privacy"
            sub="Nothing leaves your phone. Not even anonymised."
          />
        </div>

        {/* shared gradient defs */}
        <svg width="0" height="0" style={{ position: 'absolute' }}>
          <defs>
            <linearGradient id="g1" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0" stopColor="#A78BFA"/>
              <stop offset="1" stopColor="#EC4899"/>
            </linearGradient>
          </defs>
        </svg>

        {/* Plan cards */}
        <div style={{
          margin: '22px 20px 0', display: 'flex', gap: 10,
        }}>
          <Plan title="Monthly" price="$9.99" per="mo" sub="Cancel anytime"/>
          <Plan selected title="Yearly" price="$49.99" per="yr" sub="$4.16/mo · Save 58%" badge="BEST VALUE"/>
        </div>

        {/* CTA */}
        <div style={{ padding: '18px 20px 0' }}>
          <button style={{
            width: '100%', height: 54, borderRadius: 27, border: 'none', cursor: 'pointer',
            background: GRADIENT, fontFamily: 'inherit',
            fontSize: 16, fontWeight: 700, color: '#fff', letterSpacing: -0.2,
            boxShadow: '0 14px 30px rgba(236,72,153,0.5), inset 0 1px 0 rgba(255,255,255,0.25)',
          }}>Start 7-Day Free Trial</button>
          <div style={{
            textAlign: 'center', marginTop: 10,
            fontSize: 11.5, color: 'rgba(255,255,255,0.45)', letterSpacing: -0.1,
          }}>
            $49.99/yr after trial · Cancel anytime in Settings
          </div>
        </div>

        {/* Footer links */}
        <div style={{
          margin: '24px 20px 40px', display: 'flex', justifyContent: 'center', gap: 18,
          fontSize: 11, color: 'rgba(255,255,255,0.4)', letterSpacing: 0.1,
        }}>
          <span>Terms</span>
          <span>·</span>
          <span>Privacy</span>
          <span>·</span>
          <span>Restore</span>
        </div>
      </div>
    </PhoneShell>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <PageShell><Paywall/></PageShell>
);
