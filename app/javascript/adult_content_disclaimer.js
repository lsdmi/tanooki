/** Persists 18+ acknowledgement in the Rails session (see AdultContentAcknowledgementsController). */
export function acknowledgeAdultContent() {
  const token = document.querySelector('meta[name="csrf-token"]')?.content;

  return fetch("/adult_content_acknowledge", {
    method: "POST",
    headers: {
      "X-CSRF-Token": token,
      "X-Requested-With": "XMLHttpRequest",
    },
    credentials: "same-origin",
  });
}
