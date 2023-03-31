const initializeTinymce = () => {
  const textarea = document.querySelector('.tinymce');
  if (!textarea) return;

  tinymce.remove();
  tinymce.init({
    language: 'uk',
    selector: 'textarea',
    height: 500,
    plugins: [
      'code',
      'image',
      'link',
      'lists',
      'media',
      'quickbars',
      'wordcount'
    ],
  });
};

document.addEventListener('turbo:load', initializeTinymce);
document.addEventListener('turbo:render', initializeTinymce);
