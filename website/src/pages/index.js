import React, { useEffect, useRef } from 'react';
import Layout from '@theme/Layout';
import Typed from 'typed.js';
import Link from '@docusaurus/Link';
import styles from './index.module.css';

export default function Home() {
  const typedRef = useRef(null);

  useEffect(() => {
    const typed = new Typed(typedRef.current, {
      strings: [
        `#include "CDP.au3"\n$chrome = $browser.launch()\n$page = $chrome.newPage()\n$page.goto("https://example.com")\n$page.screenshot("example.png")`
      ],
      typeSpeed: 28,
      backSpeed: 0,
      showCursor: true,
      cursorChar: '|',
      smartBackspace: false,
    });

    return () => typed.destroy();
  }, []);

  return (
    <Layout
      title="AutoIt CDP UDF"
      description="Chrome DevTools Protocol automation for AutoIt"
    >
      {/* HERO SECTION */}
      <header className={styles.heroBanner}>
        <div className="container">
          <h1 className={styles.heroTitle}>AutoIt CDP UDF</h1>
          <p className={styles.heroSubtitle}>
            Modern browser automation using the Chrome DevTools Protocol — no WebDriver required.
          </p>

          <div className={styles.buttons}>
            <Link className="button button--primary button--lg" to="/docs/intro">
              Get Started
            </Link>
            <Link className="button button--secondary button--lg" to="https://github.com/seanhaydongriffin/autoit-cdp-udf">
              View on GitHub
            </Link>
          </div>

          {/* TYPED.JS ANIMATION */}
          <div className={styles.typedContainer}>
            <pre className={styles.typedBlock}>
              <code ref={typedRef}></code>
            </pre>
          </div>
        </div>
      </header>

      {/* FEATURES SECTION */}
      <main>
        <section className={styles.featuresSection}>
          <div className="container">
            <div className={styles.featuresGrid}>

              <div className={styles.featureCard}>
                <h3>Chrome DevTools Protocol</h3>
                <p>Direct, low‑level control of Chrome — fast, reliable, and WebDriver‑free.</p>
              </div>

              <div className={styles.featureCard}>
                <h3>AutoIt Friendly</h3>
                <p>Designed for AutoIt developers with clean UDF functions and simple patterns.</p>
              </div>

              <div className={styles.featureCard}>
                <h3>Modern Automation</h3>
                <p>Navigate, click, evaluate JavaScript, capture screenshots, and more.</p>
              </div>

            </div>
          </div>
        </section>

        {/* DEMO SECTION (GIF/MP4 placeholder) */}
        <section className={styles.demoSection}>
          <div className="container">
            <h2>See It In Action</h2>
            <p>A real browser automation demo will appear here soon.</p>

            <div className={styles.demoPlaceholder}>
              <p>[ Browser demo GIF/MP4 goes here ]</p>
            </div>
          </div>
        </section>
      </main>
    </Layout>
  );
}
