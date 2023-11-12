function sweetAlertBtn(itemid, deleteurl, authtoken) {
  const item = document.getElementById(itemid);

  Swal.fire({
    customClass: {
      container: 'swal-container',
      title: 'title',
      htmlContainer: 'htmlContainer',
      actions: 'actions',
      confirmButton: 'swal-button swal-confirm',
      cancelButton: 'swal-button'
    },
    title: 'Ви впевнені?',
    text: 'текст',
    showCancelButton: true,
    confirmButtonText: 'Так!',
    cancelButtonText: `Ні в якому разі!`,
  }).then((result) => {
    if (result.isConfirmed) {
      deleteItem(deleteurl, authtoken, item);
    }
  });
}

function deleteItem(url, token, item) {
  fetch(url, {
    method: "DELETE",
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': token,
    },
    credentials: "include"
  }).then((res) => {
    if (res.ok) {
      item.remove();
    }
  });
}

document.addEventListener('DOMContentLoaded', function() {
  const buttons = document.querySelectorAll('.sweet-alert-button');

  buttons.forEach(button => {
    button.addEventListener('click', function() {
      sweetAlertBtn(
        button.getAttribute('data-id'),
        button.getAttribute('data-url'),
        button.getAttribute('data-token')
      );
    });
  });
});
