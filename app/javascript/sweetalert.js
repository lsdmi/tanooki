function sweetAlertBtn(itemid, deleteurl, authtoken) {
    const item = document.getElementById(itemid)
    Swal.fire({
        customClass: {
            container: 'swal-container',
            popup: '',
            header: '',
            title: 'title',
            icon: '',
            image: '',
            htmlContainer: 'htmlContainer',
            input: '',
            inputLabel: '',
            validationMessage: '',
            actions: 'actions',
            confirmButton: 'swal-button swal-confirm',
            cancelButton: 'swal-button',
            loader: '',
            footer: '',
            timerProgressBar: '',
        },
        title: "Ви впевнені?",
        text: "текст",
        showCancelButton: true,
        confirmButtonText: "Так!",
        cancelButtonText: `Ні в якому разі!`,
    }).then((result) => {
        if (result.isConfirmed) {
            fetch(deleteurl, {
                method: "DELETE",
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': authtoken,
                },
                credentials: "include",
            }).then((res) => {
                if (res.ok) {
                    item.remove();
                }
            })
        }
    });
}


async function sweetalert(message, description, type, okbuttontext, cancelbuttontext) {
    return Swal.fire({
        customClass: {
            container: 'swal-container',
            title: 'title',
            htmlContainer: 'htmlContainer',
            actions: 'actions',
            confirmButton: 'swal-button swal-confirm',
            cancelButton: type !== 0 ? 'swal-button' : '',
        },
        title: message,
        text: description,
        showDenyButton: false,
        showCancelButton: type !== 0,
        confirmButtonText: okbuttontext,
        cancelButtonText: cancelbuttontext,
    })
}

async function makeCall(url, method, token) {
    return fetch(url, {
        method: method,
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': token,
        },
        credentials: "include",
    })
}

function removeItem(itemid){
    const item = document.getElementById(itemid)
    item.remove();
}

document.addEventListener('DOMContentLoaded', function () {
    const buttons = document.querySelectorAll('.sweet-alert-button');

    buttons.forEach(button => {
        button.addEventListener('click', function () {
            sweetalert(
                button.hasAttribute('data-message') ? button.getAttribute('data-message') : "Alert",
                button.hasAttribute('data-description') ? button.getAttribute('data-description') : '',
                button.hasAttribute('data-type') ? parseInt(button.getAttribute('data-type')) : 0,
                button.hasAttribute('data-ok_button_text') ? button.getAttribute('data-ok_button_text') : "Так!",
                button.hasAttribute('data-cancel_button_text') ? button.getAttribute('data-cancel_button_text') : "Ні в якому разі!",
            ).then(result => {
                if (result.isConfirmed) {
                    if (button.getAttribute('data-url') !== "*")
                        window.location.replace(button.getAttribute('data-url'))

                    if (button.hasAttribute('data-async-fetch')) {
                        makeCall(
                            button.getAttribute('data-async-fetch'),
                            button.getAttribute('data-method'),
                            button.getAttribute('data-auth-token')
                        ).then((res) => {
                            if (res.ok) {
                                if (button.hasAttribute('data-delete-after'))
                                    removeItem(button.getAttribute('data-delete-after'))
                            }
                        })
                    }
                }
            });
        });
    });
});


