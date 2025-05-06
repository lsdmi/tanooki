const initializeFilter = () => {
    const hiddenSubmitButton = document.getElementById('hiddenSubmit');
  
    const checkboxes = [
      ...document.getElementById('genre-list').querySelectorAll('input'),
    ];
  
    const addChangeListener = (element) => {
      element.addEventListener('change', () => hiddenSubmitButton.click());
    };
  
    checkboxes.forEach(addChangeListener);
  }
  
  document.addEventListener('turbo:load', initializeFilter);