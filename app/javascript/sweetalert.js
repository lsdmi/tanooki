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