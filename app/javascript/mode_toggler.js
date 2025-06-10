const initializeModeToggler = () => {
  const siteLogo = document.getElementById('site-logo');
  const defaultLogo = siteLogo.getAttribute('data-default-logo');
  const darkLogo = siteLogo.getAttribute('data-dark-logo');

  const setLogo = (isDark) => {
    if (isDark) {
      siteLogo.src = darkLogo;
    } else {
      siteLogo.src = defaultLogo;
    }
  };

  if (localStorage.getItem('color-theme') === 'dark' || (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.documentElement.classList.add('dark');
    setLogo(true);
  } else {
    document.documentElement.classList.remove('dark');
    setLogo(false);
  }

  var themeToggleDarkIcon = document.getElementById('theme-toggle-dark-icon');
  var themeToggleLightIcon = document.getElementById('theme-toggle-light-icon');

  if (!themeToggleLightIcon) { return; }

  if (localStorage.getItem('color-theme') === 'dark' || (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    themeToggleLightIcon.classList.remove('hidden');
  } else {
    themeToggleDarkIcon.classList.remove('hidden');
  }

  var themeToggleBtn = document.getElementById('theme-toggle');

  themeToggleBtn.addEventListener('click', function() {

    themeToggleDarkIcon.classList.toggle('hidden');
    themeToggleLightIcon.classList.toggle('hidden');

    if (localStorage.getItem('color-theme')) {
      if (localStorage.getItem('color-theme') === 'light') {
        document.documentElement.classList.add('dark');
        localStorage.setItem('color-theme', 'dark');
        setLogo(true);
      } else {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('color-theme', 'light');
        setLogo(false);
      }
    } else {
      if (document.documentElement.classList.contains('dark')) {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('color-theme', 'light');
        setLogo(false);
      } else {
        document.documentElement.classList.add('dark');
        localStorage.setItem('color-theme', 'dark');
        setLogo(true);
      }
    }
  });
}

document.addEventListener('turbo:load', initializeModeToggler);