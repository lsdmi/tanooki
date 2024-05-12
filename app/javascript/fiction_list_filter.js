const initializeFilter = () => {
  const hiddenSubmitButton = document.getElementById('hiddenSubmit');

  const checkboxes = [
    document.getElementById('only_new'),
    document.getElementById('only_finished'),
    document.getElementById('only_long'),
    ...document.getElementById('genre-list').querySelectorAll('input'),
    ...document.getElementById('origin-list').querySelectorAll('input')
  ];

  const addChangeListener = (element) => {
    element.addEventListener('change', () => hiddenSubmitButton.click());
  };

  checkboxes.forEach(addChangeListener);
}

document.addEventListener('turbo:load', initializeFilter);
