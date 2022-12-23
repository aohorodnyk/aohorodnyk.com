if (window.matchMedia) {
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => identifyAndSetColorScheme());
  window.matchMedia('(prefers-color-scheme: light)').addEventListener('change', () => identifyAndSetColorScheme());
}
