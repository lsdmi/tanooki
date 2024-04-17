const initializeFilter = () => {
  let hiddenSubmitButton = document.getElementById('hiddenSubmit');
  let finishedCheckbox = document.getElementById('only_finished');

  finishedCheckbox.addEventListener('change', function() {
    hiddenSubmitButton.click();
  });
}

document.addEventListener('turbo:load', initializeFilter);