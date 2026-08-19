import { StrictMode, useEffect, useRef } from 'react'
import { createRoot } from 'react-dom/client'
import './styles.css'

const apkPath = '/RoutineSync.apk'

const features = [
  {
    icon: '✓',
    eyebrow: 'ROUTINE',
    title: 'Daily rhythm',
    copy: 'See every routine in one focused timeline and record what actually happened.',
  },
  {
    icon: '↗',
    eyebrow: 'TRAINING',
    title: 'Clear progression',
    copy: 'Follow the six-day gym plan with technique cues, sets, reps, and completion.',
  },
  {
    icon: '◎',
    eyebrow: 'NUTRITION',
    title: 'Food awareness',
    copy: 'Log meals and quantities with automatic daily calorie totals and history.',
  },
]

function DownloadIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M12 3v11m0 0 4-4m-4 4-4-4M5 18v2h14v-2" />
    </svg>
  )
}

function ArrowIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path d="M5 12h14m-5-5 5 5-5 5" />
    </svg>
  )
}

function PhonePreview() {
  return (
    <div className="visual" aria-label="RoutineSync app preview">
      <div className="visual-grid" />
      <div className="orb orb-one" />
      <div className="orb orb-two" />
      <div className="orbit orbit-one"><i /></div>
      <div className="orbit orbit-two"><i /></div>
      <div className="phone-shadow" />
      <div className="phone">
        <div className="phone-top"><span /></div>
        <div className="screen">
          <div className="screen-header">
            <div>
              <small>FRIDAY, JULY 17</small>
              <h2>Good afternoon.</h2>
            </div>
            <img src="/app-icon.png" alt="" />
          </div>
          <div className="progress-card">
            <div className="progress-heading">
              <span>Today's rhythm</span><strong>67%</strong>
            </div>
            <div className="progress-track"><i /></div>
            <small>6 of 9 routines complete</small>
          </div>
          <p className="section-label">UP NEXT</p>
          <div className="task active">
            <span className="task-icon">↗</span>
            <div><strong>Gym training</strong><small>6:00 PM — 7:30 PM</small></div>
            <b>›</b>
          </div>
          <div className="task">
            <span className="task-icon meal">◎</span>
            <div><strong>Dinner & calories</strong><small>7:30 PM — 8:00 PM</small></div>
            <b>›</b>
          </div>
          <div className="mini-grid">
            <div><small>CALORIES</small><strong>1,840</strong><span>kcal today</span></div>
            <div><small>GYM SETS</small><strong>12 / 18</strong><span>on target</span></div>
          </div>
        </div>
      </div>
      <div className="floating-chip chip-one"><span>✓</span> Routine complete</div>
      <div className="floating-chip chip-two"><span>↗</span> 12 sets logged</div>
    </div>
  )
}

function App() {
  const glowRef = useRef(null)

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) entry.target.classList.add('is-visible')
        })
      },
      { threshold: 0.14 },
    )

    document.querySelectorAll('.reveal').forEach((node) => observer.observe(node))

    const moveGlow = (event) => {
      if (!glowRef.current) return
      glowRef.current.style.setProperty('--x', `${event.clientX}px`)
      glowRef.current.style.setProperty('--y', `${event.clientY}px`)
    }
    window.addEventListener('pointermove', moveGlow, { passive: true })

    return () => {
      observer.disconnect()
      window.removeEventListener('pointermove', moveGlow)
    }
  }, [])

  return (
    <main ref={glowRef}>
      <div className="cursor-glow" aria-hidden="true" />

      <nav className="nav shell">
        <a className="brand" href="#top" aria-label="RoutineSync home">
          <span className="brand-mark"><img src="/app-icon.png" alt="" /></span>
          <span>RoutineSync</span>
        </a>
        <div className="nav-links">
          <a href="#features">Features</a>
          <a href="#install">Install</a>
        </div>
        <a className="nav-download" href={apkPath} download>
          Download <ArrowIcon />
        </a>
      </nav>

      <section className="hero shell" id="top">
        <div className="hero-copy">
          <div className="eyebrow hero-enter enter-one">
            <span className="live-dot" /> Android release available
          </div>
          <h1 className="hero-enter enter-two">
            Your day,<br /><span>beautifully in rhythm.</span>
          </h1>
          <p className="hero-lead hero-enter enter-three">
            One calm personal system for routines, workouts, meals, work,
            study, and the small wins worth remembering.
          </p>
          <div className="hero-actions hero-enter enter-four">
            <a className="download-button magnetic" href={apkPath} download>
              <DownloadIcon />
              <span><small>Download for Android</small>RoutineSync v1.0.0</span>
              <i className="button-shine" />
            </a>
            <div className="build-meta"><strong>50.1 MB</strong><span>Android 6.0+</span></div>
          </div>
          <p className="trust-line hero-enter enter-five">
            <span>✓</span> Direct APK&nbsp;&nbsp; <span>✓</span> No account required&nbsp;&nbsp;
            <span>✓</span> Free download
          </p>
        </div>
        <PhonePreview />
      </section>

      <div className="marquee" aria-hidden="true">
        <div>
          <span>ROUTINE</span><i /> <span>TRAINING</span><i /> <span>NUTRITION</span><i />
          <span>FOCUS</span><i /> <span>HISTORY</span><i /> <span>RHYTHM</span><i />
          <span>ROUTINE</span><i /> <span>TRAINING</span><i /> <span>NUTRITION</span><i />
          <span>FOCUS</span><i /> <span>HISTORY</span><i /> <span>RHYTHM</span><i />
        </div>
      </div>

      <section className="feature-section shell" id="features">
        <div className="section-intro reveal">
          <div>
            <p className="eyebrow plain">BUILT FOR CONSISTENCY</p>
            <h2>Everything important.<br />Nothing noisy.</h2>
          </div>
          <p className="section-copy">
            Designed to make daily tracking feel lighter, faster, and genuinely useful.
          </p>
        </div>
        <div className="feature-grid">
          {features.map((feature, index) => (
            <article className="feature-card reveal" style={{ '--delay': `${index * 110}ms` }} key={feature.title}>
              <div className="card-top"><span className="feature-icon">{feature.icon}</span><small>0{index + 1}</small></div>
              <p className="feature-eyebrow">{feature.eyebrow}</p>
              <h3>{feature.title}</h3>
              <p>{feature.copy}</p>
              <i className="card-glow" />
            </article>
          ))}
        </div>
      </section>

      <section className="facts shell reveal">
        <div><strong>9</strong><span>daily routine slots</span></div>
        <i />
        <div><strong>6</strong><span>training days</span></div>
        <i />
        <div><strong>3</strong><span>meal checkpoints</span></div>
        <i />
        <div><strong>1</strong><span>clear daily system</span></div>
      </section>

      <section className="install shell" id="install">
        <div className="install-heading reveal">
          <p className="eyebrow plain">QUICK INSTALL</p>
          <h2>Ready in<br />three steps.</h2>
          <p>Download directly to your Android phone. No store account needed.</p>
        </div>
        <ol>
          {[
            ['Download', 'Tap the Android download button.'],
            ['Allow installation', 'Approve “Install unknown apps” if Android asks.'],
            ['Open RoutineSync', 'Install the APK and begin your day.'],
          ].map(([title, copy], index) => (
            <li className="reveal" style={{ '--delay': `${index * 100}ms` }} key={title}>
              <span>{index + 1}</span><div><strong>{title}</strong><p>{copy}</p></div><i>↗</i>
            </li>
          ))}
        </ol>
      </section>

      <section className="final-cta shell reveal">
        <div className="cta-orb" />
        <img src="/app-icon.png" alt="RoutineSync icon" />
        <div><p>Make consistency feel lighter.</p><h2>Start your next good day.</h2></div>
        <a className="download-button compact" href={apkPath} download>
          <DownloadIcon /> Download APK <i className="button-shine" />
        </a>
      </section>

      <footer className="shell">
        <span>RoutineSync © 2026</span>
        <span>Version 1.0.0 · Build 1</span>
      </footer>
    </main>
  )
}

createRoot(document.getElementById('root')).render(
  <StrictMode><App /></StrictMode>,
)
