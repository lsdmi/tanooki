const initializeGA = () => {
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'G-BW05CDN8VS');
};

document.addEventListener('turbo:load', initializeGA);