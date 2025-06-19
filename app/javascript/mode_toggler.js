const initializeModeToggler = () => {
  const siteLogo = document.getElementById('site-logo');
  const defaultLogo = siteLogo.getAttribute('data-default-logo');
  const darkLogo = siteLogo.getAttribute('data-dark-logo');

  const setLogo = (isDark) => {
    siteLogo.src = isDark ? darkLogo : defaultLogo;
  };

  const themeToggleDarkIcon = document.getElementById('theme-toggle-dark-icon');
  const themeToggleLightIcon = document.getElementById('theme-toggle-light-icon');
  const themeToggleBtn = document.getElementById('theme-toggle');

  const setIconVisibility = (isDark) => {
    themeToggleDarkIcon.style.display = isDark ? 'none' : 'inline';
    themeToggleLightIcon.style.display = isDark ? 'inline' : 'none';
  };  

  const isDark =
    localStorage.getItem('color-theme') === 'dark' ||
    (!('color-theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches);

  document.documentElement.classList.toggle('dark', isDark);
  setLogo(isDark);
  setIconVisibility(isDark);

  themeToggleBtn.addEventListener('click', function() {
    const currentlyDark = document.documentElement.classList.toggle('dark');
    const newIsDark = document.documentElement.classList.contains('dark');
    localStorage.setItem('color-theme', newIsDark ? 'dark' : 'light');
    setLogo(newIsDark);
    setIconVisibility(newIsDark);

    // Set the Rails cookie for server-side theme detection
    document.cookie = `color_theme=${newIsDark ? 'dark' : 'light'}; path=/; max-age=31536000`;
  });
};

document.addEventListener('turbo:load', initializeModeToggler);
