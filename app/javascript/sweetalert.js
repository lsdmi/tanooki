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


function sweetalert(message, url="*", description="", type = 0, okbuttontext="Так!", cancelbuttontext="Ні в якому разі!"){
    Swal.fire({
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
    }).then((result) => {
        if (result.isConfirmed) {
            if(url !== "*")
                window.location.replace(url);
        }
    });
}