if (window.matchMedia) {
  function checkSwitch(checked) {
    let modeSwitch = document.querySelector('[data-bs-toggle="mode"]');
    if(modeSwitch === null) {
      return;
    }

    const checkbox = modeSwitch.querySelector('.form-check-input');
    checkbox.checked = checked;
  }

  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    if (!window.matchMedia('(prefers-color-scheme: dark)').matches) {
      return;
    }

    identifyAndSetColorScheme();
    checkSwitch(true);
  });

  window.matchMedia('(prefers-color-scheme: light)').addEventListener('change', () => {
    if (!window.matchMedia('(prefers-color-scheme: light)').matches) {
      return;
    }

    identifyAndSetColorScheme();
    checkSwitch(false);
  });
}
