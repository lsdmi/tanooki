async function sweetAlertBtn(message, description) {
  return Swal.fire({
    customClass: {
      container: 'swal-container',
      title: 'title',
      htmlContainer: 'htmlContainer',
      actions: 'actions',
      confirmButton: 'swal-button swal-confirm',
      cancelButton: 'swal-button',
    },
    title: message,
    text: description,
    showDenyButton: false,
    showCancelButton: true,
    confirmButtonText: 'Прибрати',
    cancelButtonText: 'Відмінити',
  });
}

async function makeCall(url, token) {
  const response = await fetch(url, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': token,
    },
    credentials: 'include'
  });

  return response;
}

function removeItem(itemId){
  const item = document.getElementById(itemId)
  item.remove();
}

function initializeAlert() {
  const buttons = document.querySelectorAll('.sweet-alert-button');

  buttons.forEach(button => {
    button.addEventListener('click', async function () {
      const result = await sweetAlertBtn(
        button.getAttribute('data-message'),
        button.getAttribute('data-description')
      );

      if (result.isConfirmed) {
        if (button.hasAttribute('data-url')) {
          const res = await makeCall(
            button.getAttribute('data-url'),
            button.getAttribute('data-token')
          );

          if (res.ok && button.hasAttribute('data-tag-id')) {
            removeItem(button.getAttribute('data-tag-id'));
          }
        }
      }
    });
  });
}

document.addEventListener('turbo:load', function() {
  initializeAlert();
});
