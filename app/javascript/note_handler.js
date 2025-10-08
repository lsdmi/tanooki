// Handle note clicks on content display pages
document.addEventListener('click', function(e) {
  if (e.target.classList.contains('note-reference')) {
    e.preventDefault();
    e.stopPropagation();

    // Check if this note is already open
    const existingNote = e.target.parentNode.querySelector('.note-content');
    if (existingNote) {
      existingNote.remove();
      return;
    }

    // Remove any other open notes first
    document.querySelectorAll('.note-content').forEach(content => {
      content.remove();
    });
    const noteText = e.target.getAttribute('data-note');

    // Create note content element
    const noteContent = document.createElement('div');
    noteContent.className = 'note-content show';
    noteContent.textContent = noteText;

    // Insert after the clicked element
    const parent = e.target.parentNode;

    // Find the next sibling or append to parent
    const nextSibling = e.target.nextSibling;
    if (nextSibling) {
      parent.insertBefore(noteContent, nextSibling);
    } else {
      parent.appendChild(noteContent);
    }

    // Scroll to note if needed
    setTimeout(() => {
      noteContent.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }, 100);
  }
});
