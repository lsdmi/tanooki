const initializeCommentsHandler = () => {
  const dropdownButton = document.getElementById('dropdownNotificationButton');
  const dropdownForm = document.getElementById('dropdownForm');
  const dropdown = document.getElementById('dropdownNotification');
  const dropdownStatus = document.getElementById('dropdownStatus');

  dropdownButton.addEventListener('click', function(event) {
    event.preventDefault();
    dropdown.classList.toggle('hidden');

    if (dropdownStatus) { dropdownStatus.style.display = "none"; }
    if (!dropdown.classList.contains('hidden')) {
      const formData = new FormData(dropdownForm);

      const formAction = dropdownForm.getAttribute('action');
      const csrfToken = formData.get('authenticity_token');
      const headers = new Headers();
      headers.append('X-CSRF-Token', csrfToken);

      fetch(formAction, {
        method: dropdownForm.method,
        body: formData,
        headers: headers
      });
    }
  });
};

document.addEventListener('turbo:load', initializeCommentsHandler);
