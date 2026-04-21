// PoseAI Settings v2 — native iOS grouped list, SF Symbol icons, SwiftUI-style controls.

function IOSToggle({ on }) {
  return (
    <div style={{
      width: 51, height: 31, borderRadius: 999, padding: 2,
      background: on ? GRADIENT : 'rgba(120,120,128,0.32)',
      position: 'relative', transition: 'all 200ms',
    }}>
      <div style={{
        width: 27, height: 27, borderRadius: '50%', background: '#fff',
        position: 'absolute', top: 2, left: on ? 22 : 2,
        boxShadow: '0 3px 8px rgba(0,0,0,0.25)', transition: 'left 200ms',
      }}/>
    </div>
  );
}

function IOSSlider({ value }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', width: 160 }}>
      <div style={{ flex: 1, height: 4, borderRadius: 999, background: 'rgba(255,255,255,0.12)', position: 'relative' }}>
        <div style={{
          position: 'absolute', left: 0, top: 0, bottom: 0, width: `${value}%`,
          background: GRADIENT, borderRadius: 999,
        }}/>
        <div style={{
          position: 'absolute', left: `${value}%`, top: '50%', transform: 'translate(-50%, -50%)',
          width: 22, height: 22, borderRadius: '50%', background: '#fff',
          boxShadow: '0 3px 8px rgba(0,0,0,0.3)',
        }}/>
      </div>
    </div>
  );
}

function Segmented({ options, active }) {
  return (
    <div style={{
      display: 'flex', padding: 2, borderRadius: 9,
      background: 'rgba(118,118,128,0.24)',
    }}>
      {options.map((o, i) => (
        <div key={i} style={{
          padding: '5px 12px', borderRadius: 7,
          background: i === active ? GRADIENT : 'transparent',
          fontSize: 13, fontWeight: 600, color: '#fff', letterSpacing: -0.1,
          boxShadow: i === active ? '0 1px 3px rgba(0,0,0,0.25)' : 'none',
        }}>{o}</div>
      ))}
    </div>
  );
}

// SF Symbol rounded-fill icon tiles (settings-app style)
function Icon({ color, children }) {
  return (
    <div style={{
      width: 29, height: 29, borderRadius: 7, flexShrink: 0,
      background: color,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: '0 1px 2px rgba(0,0,0,0.15)',
    }}>{children}</div>
  );
}

function Row({ icon, label, children, chevron, isLast, labelExtra }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '11px 14px',
      borderBottom: isLast ? 'none' : '0.5px solid rgba(255,255,255,0.06)',
      minHeight: 48,
    }}>
      {icon}
      <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column' }}>
        <span style={{ fontSize: 15, color: '#fff', letterSpacing: -0.2 }}>{label}</span>
        {labelExtra && (
          <span style={{ fontSize: 11.5, color: 'rgba(255,255,255,0.45)', marginTop: 1, letterSpacing: -0.1 }}>{labelExtra}</span>
        )}
      </div>
      {children}
      {chevron && <span style={{ marginLeft: 4 }}>{SF.chevronRight('rgba(235,235,245,0.3)', 7)}</span>}
    </div>
  );
}

function SectionHeader({ children }) {
  return (
    <div style={{
      padding: '0 20px 6px 20px', marginTop: 22,
      fontSize: 13, fontWeight: 400, color: 'rgba(235,235,245,0.6)', letterSpacing: -0.1,
      textTransform: 'uppercase',
    }}>{children}</div>
  );
}

function Section({ children, footer }) {
  return (
    <>
      <div style={{
        margin: '0 16px', borderRadius: 12,
        background: 'rgba(28,28,30,0.85)',
        border: '0.5px solid rgba(255,255,255,0.06)',
        overflow: 'hidden',
      }}>{children}</div>
      {footer && (
        <div style={{
          padding: '6px 20px 0', fontSize: 13, color: 'rgba(235,235,245,0.45)',
          lineHeight: 1.35, letterSpacing: -0.1,
        }}>{footer}</div>
      )}
    </>
  );
}

// Subscription cards
function FreeCard() {
  return (
    <div style={{
      margin: '14px 16px 0', padding: 1.5, borderRadius: 16, background: GRADIENT,
      boxShadow: '0 14px 30px rgba(124,58,237,0.28)',
    }}>
      <div style={{
        borderRadius: 14.5, padding: '14px 16px',
        background: 'linear-gradient(165deg, rgba(124,58,237,0.16), rgba(15,15,20,0.98) 65%)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8, background: 'rgba(255,255,255,0.08)',
            border: '0.5px solid rgba(255,255,255,0.15)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            opacity: 0.75,
          }}>
            <svg width="16" height="14" viewBox="0 0 24 18"><path d="M2 5 L6 12 L12 4 L18 12 L22 5 L20 16 L4 16 Z" fill="rgba(255,255,255,0.6)"/></svg>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{
              fontSize: 10, fontWeight: 700, letterSpacing: 1.8, color: 'rgba(255,255,255,0.5)',
              fontFamily: 'ui-monospace, "SF Mono", monospace',
            }}>FREE PLAN</div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#fff', letterSpacing: -0.3, marginTop: 1 }}>
              You're on Free
            </div>
          </div>
        </div>
        <div style={{ marginTop: 12 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ fontSize: 12, color: 'rgba(255,255,255,0.65)', letterSpacing: -0.1 }}>
              Daily poses
            </span>
            <span style={{
              fontSize: 11.5, fontWeight: 600, color: '#F472B6',
              fontFamily: 'ui-monospace, "SF Mono", monospace',
            }}>3 / 3 used</span>
          </div>
          <div style={{ height: 5, borderRadius: 999, background: 'rgba(255,255,255,0.08)' }}>
            <div style={{ width: '100%', height: '100%', background: GRADIENT, borderRadius: 999 }}/>
          </div>
        </div>
        <a href="PoseAI Paywall v2.html" style={{
          textDecoration: 'none', marginTop: 14,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          height: 42, borderRadius: 12, background: GRADIENT,
          fontSize: 14, fontWeight: 700, color: '#fff', letterSpacing: -0.1,
          boxShadow: '0 8px 20px rgba(236,72,153,0.4), inset 0 1px 0 rgba(255,255,255,0.25)',
        }}>
          Upgrade to Pro
          <svg width="14" height="12" viewBox="0 0 14 12"><path d="M8 1 L13 6 L8 11 M13 6 L1 6" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" fill="none"/></svg>
        </a>
      </div>
    </div>
  );
}

function ProCard() {
  return (
    <div style={{
      margin: '10px 16px 0', borderRadius: 16, padding: '14px 16px',
      background: GRADIENT, position: 'relative', overflow: 'hidden',
      boxShadow: '0 14px 30px rgba(236,72,153,0.35)',
    }}>
      <div style={{
        position: 'absolute', top: -40, right: -40, width: 180, height: 180, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(255,255,255,0.22), transparent 60%)',
      }}/>
      <div style={{ position: 'relative' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <svg width="16" height="13" viewBox="0 0 24 18"><path d="M2 5 L6 12 L12 4 L18 12 L22 5 L20 16 L4 16 Z" fill="#fff"/></svg>
            <span style={{
              fontSize: 10, fontWeight: 700, letterSpacing: 1.8, color: 'rgba(255,255,255,0.9)',
              fontFamily: 'ui-monospace, "SF Mono", monospace',
            }}>PRO · YEARLY</span>
          </div>
          <div style={{
            width: 22, height: 22, borderRadius: '50%',
            background: 'rgba(255,255,255,0.2)', border: '0.5px solid rgba(255,255,255,0.4)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{SF.checkmark('#fff', 12)}</div>
        </div>
        <div style={{ marginTop: 6, fontSize: 17, fontWeight: 700, color: '#fff', letterSpacing: -0.3 }}>
          PoseAI Pro is active
        </div>
        <div style={{ marginTop: 2, fontSize: 12.5, color: 'rgba(255,255,255,0.85)' }}>
          Renews Oct 12, 2026 · $49.99/yr
        </div>
        <div style={{
          marginTop: 12, padding: '10px 0 0', borderTop: '0.5px solid rgba(255,255,255,0.2)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <span style={{ fontSize: 13, fontWeight: 600, color: '#fff', letterSpacing: -0.1 }}>
            Manage Subscription
          </span>
          {SF.chevronRight('#fff', 8)}
        </div>
      </div>
    </div>
  );
}

// Sections
function Preferences() {
  return (
    <>
      <SectionHeader>Camera</SectionHeader>
      <Section>
        <Row icon={
          <Icon color="#A78BFA">
            <svg width="15" height="15" viewBox="0 0 15 15" fill="none">
              <rect x="1.5" y="1.5" width="12" height="12" rx="1.5" stroke="#fff" strokeWidth="1.4"/>
              <line x1="5.5" y1="1.5" x2="5.5" y2="13.5" stroke="#fff" strokeWidth="1" strokeOpacity="0.9"/>
              <line x1="9.5" y1="1.5" x2="9.5" y2="13.5" stroke="#fff" strokeWidth="1" strokeOpacity="0.9"/>
              <line x1="1.5" y1="5.5" x2="13.5" y2="5.5" stroke="#fff" strokeWidth="1" strokeOpacity="0.9"/>
              <line x1="1.5" y1="9.5" x2="13.5" y2="9.5" stroke="#fff" strokeWidth="1" strokeOpacity="0.9"/>
            </svg>
          </Icon>
        } label="Grid Overlay">
          <IOSToggle on={true}/>
        </Row>
        <Row icon={
          <Icon color="#EC4899">
            {SF.sparkles('#fff', 15)}
          </Icon>
        } label="Pose Overlay Opacity" labelExtra="35%">
          <IOSSlider value={35}/>
        </Row>
        <Row icon={
          <Icon color="#FBBF24">
            {SF.timer('#fff', 16)}
          </Icon>
        } label="Timer Default">
          <Segmented options={['3s','5s','10s']} active={0}/>
        </Row>
        <Row icon={
          <Icon color="#10B981">
            <svg width="14" height="14" viewBox="0 0 14 14">
              <rect x="1.5" y="4.5" width="4" height="5" rx="1" fill="#fff"/>
              <path d="M7 7 C 9 5, 11 5, 12 7 M7 7 C 9 9, 11 9, 12 7" stroke="#fff" strokeWidth="1.3" fill="none" strokeLinecap="round"/>
            </svg>
          </Icon>
        } label="Haptic Feedback" isLast>
          <IOSToggle on={true}/>
        </Row>
      </Section>
    </>
  );
}

function AI() {
  return (
    <>
      <SectionHeader>AI Detection</SectionHeader>
      <Section footer="All AI processing happens on your device. No photos are ever uploaded.">
        <Row icon={
          <Icon color="#7C3AED">{SF.sparkles('#fff', 14)}</Icon>
        } label="Show Environment Tags">
          <IOSToggle on={true}/>
        </Row>
        <Row icon={
          <Icon color="#EC4899">
            <svg width="14" height="14" viewBox="0 0 14 14">
              <circle cx="7" cy="4.5" r="2" fill="none" stroke="#fff" strokeWidth="1.3"/>
              <path d="M2.5 12 C 2.5 8.5, 4.5 7, 7 7 S 11.5 8.5, 11.5 12" fill="none" stroke="#fff" strokeWidth="1.3"/>
            </svg>
          </Icon>
        } label="Person Detection" labelExtra="High · 78%" isLast>
          <IOSSlider value={78}/>
        </Row>
      </Section>
    </>
  );
}

function About() {
  return (
    <>
      <SectionHeader>About</SectionHeader>
      <Section>
        <Row icon={<Icon color="#FBBF24">{SF.star('#fff', 13)}</Icon>} label="Rate PoseAI" chevron/>
        <Row icon={
          <Icon color="#10B981">
            <svg width="13" height="13" viewBox="0 0 13 13">
              <circle cx="3" cy="6.5" r="1.6" fill="#fff"/>
              <circle cx="10" cy="3" r="1.6" fill="#fff"/>
              <circle cx="10" cy="10" r="1.6" fill="#fff"/>
              <line x1="4.5" y1="5.5" x2="8.5" y2="3.8" stroke="#fff" strokeWidth="1.1"/>
              <line x1="4.5" y1="7.5" x2="8.5" y2="9.2" stroke="#fff" strokeWidth="1.1"/>
            </svg>
          </Icon>
        } label="Share with Friends" chevron/>
        <Row icon={
          <Icon color="#60A5FA">
            <svg width="13" height="14" viewBox="0 0 13 14"><path d="M6.5 1 L1.5 2.5 V7 C 1.5 10, 4 11.5, 6.5 12.5 C 9 11.5, 11.5 10, 11.5 7 V2.5 Z" fill="#fff"/></svg>
          </Icon>
        } label="Privacy Policy" chevron/>
        <Row icon={
          <Icon color="#9CA3AF">
            <svg width="12" height="14" viewBox="0 0 12 14">
              <rect x="1" y="1" width="10" height="12" rx="1" fill="#fff"/>
              <line x1="3" y1="4.5" x2="9" y2="4.5" stroke="#9CA3AF" strokeWidth="0.9"/>
              <line x1="3" y1="7" x2="9" y2="7" stroke="#9CA3AF" strokeWidth="0.9"/>
              <line x1="3" y1="9.5" x2="7" y2="9.5" stroke="#9CA3AF" strokeWidth="0.9"/>
            </svg>
          </Icon>
        } label="Terms of Service" chevron/>
        <Row icon={<Icon color="rgba(255,255,255,0.12)">
          <span style={{ fontSize: 10, fontWeight: 800, color: 'rgba(255,255,255,0.7)' }}>i</span>
        </Icon>} label="App Version" isLast>
          <span style={{
            fontSize: 13, color: 'rgba(235,235,245,0.45)',
            fontFamily: 'ui-monospace, "SF Mono", monospace',
          }}>1.0.0 (214)</span>
        </Row>
      </Section>
    </>
  );
}

function Settings() {
  return (
    <PhoneShell>
      <div style={{ position: 'absolute', inset: 0, background: '#0A0A0F', overflow: 'hidden' }}>
        <div style={{
          position: 'absolute', top: -140, right: -80, width: 300, height: 300, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(124,58,237,0.22), transparent 65%)',
          filter: 'blur(12px)', pointerEvents: 'none',
        }}/>

        <div style={{
          position: 'absolute', inset: 0, overflowY: 'auto', paddingBottom: 110,
        }}>
          {/* Title */}
          <div style={{ padding: '62px 20px 0' }}>
            <h1 style={{
              margin: 0, fontSize: 34, fontWeight: 700, letterSpacing: -1, color: '#fff',
            }}>Settings</h1>
          </div>

          {/* subscription header */}
          <div style={{
            padding: '20px 20px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          }}>
            <span style={{
              fontSize: 13, fontWeight: 400, color: 'rgba(235,235,245,0.6)',
              textTransform: 'uppercase', letterSpacing: -0.1,
            }}>Subscription</span>
            <span style={{
              fontSize: 10, padding: '2px 7px', borderRadius: 4,
              background: 'rgba(255,255,255,0.06)', border: '0.5px solid rgba(255,255,255,0.12)',
              color: 'rgba(255,255,255,0.5)', fontFamily: 'ui-monospace, "SF Mono", monospace', letterSpacing: 0.6,
            }}>BOTH STATES SHOWN</span>
          </div>
          <FreeCard/>
          <ProCard/>

          <Preferences/>
          <AI/>
          <About/>

          <div style={{
            margin: '26px 20px 0', textAlign: 'center',
            fontSize: 12, color: 'rgba(255,255,255,0.3)', letterSpacing: -0.1,
          }}>Made with care · © 2026 PoseAI</div>
        </div>

        <TabBar active="settings"/>
      </div>
    </PhoneShell>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <PageShell><Settings/></PageShell>
);
