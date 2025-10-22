// Translation Requests JavaScript functionality
// Keep track of current page
let currentPage = 1;

// Make functions globally available for onclick handlers
window.loadPage = loadPage;
window.voteOnRequest = voteOnRequest;
window.toggleAssignmentDropdown = toggleAssignmentDropdown;
window.assignRequest = assignRequest;
window.unassignRequest = unassignRequest;
window.toggleEditMode = toggleEditMode;
window.cancelEdit = cancelEdit;
window.saveEdit = saveEdit;
window.deleteRequest = deleteRequest;

function loadPage(pageNumber) {
  currentPage = pageNumber; // Update current page tracker
  
  fetch(`/translate?page=${pageNumber}`, {
    method: 'GET',
    headers: {
      'Accept': 'text/vnd.turbo-stream.html',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    }
  })
  .then(response => response.text())
  .then(html => {
    // Parse the turbo stream response and apply it
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, 'text/html');
    const turboStreamElement = doc.querySelector('turbo-stream');
    
    if (turboStreamElement) {
      const action = turboStreamElement.getAttribute('action');
      const target = turboStreamElement.getAttribute('target');
      const template = turboStreamElement.querySelector('template');
      
      if (action === 'update' && target === 'requests-container' && template) {
        document.getElementById('requests-container').innerHTML = template.innerHTML;
      }
    }
  })
  .catch(error => {
    console.error('Error loading page:', error);
    showErrorMessage('Сталася помилка при завантаженні сторінки. Спробуйте ще раз.');
  });
}

function reloadCurrentPage() {
  // Check if current page still has items, if not go to previous page
  fetch(`/translate?page=${currentPage}`, {
    method: 'GET',
    headers: {
      'Accept': 'text/vnd.turbo-stream.html',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    }
  })
  .then(response => response.text())
  .then(html => {
    // Parse the turbo stream response and apply it
    const parser = new DOMParser();
    const doc = parser.parseFromString(html, 'text/html');
    const turboStreamElement = doc.querySelector('turbo-stream');
    
    if (turboStreamElement) {
      const action = turboStreamElement.getAttribute('action');
      const target = turboStreamElement.getAttribute('target');
      const template = turboStreamElement.querySelector('template');
      
      if (action === 'update' && target === 'requests-container' && template) {
        document.getElementById('requests-container').innerHTML = template.innerHTML;
        
        // Check if the current page is empty and we're not on page 1
        const requestCards = template.content.querySelectorAll('[id^="request-card-"]');
        if (requestCards.length === 0 && currentPage > 1) {
          // Load previous page if current page is empty
          loadPage(currentPage - 1);
        }
      }
    }
  })
  .catch(error => {
    console.error('Error reloading page:', error);
    showErrorMessage('Сталася помилка при оновленні списку. Спробуйте ще раз.');
  });
}

function voteOnRequest(requestId) {
  // Disable the vote button to prevent double-clicking
  const upvoteBtn = document.querySelector(`.upvote-btn-${requestId}`);
  upvoteBtn.disabled = true;
  
  fetch(`/translate/${requestId}/votes`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
      'Accept': 'application/json'
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.error) {
      showErrorMessage(data.error);
      return;
    }
    
    // Update vote counts
    document.querySelector(`.upvote-count-${requestId}`).textContent = data.votes_count;
    
    // Update the votes text for all instances (both logged in and non-logged in sections)
    const voteCountElements = document.querySelectorAll(`.votes-count-${requestId}`);
    voteCountElements.forEach(element => {
      element.textContent = data.votes_count;
    });
    
    // Update button styles based on user vote
    updateVoteButtonStyles(requestId, data.user_voted);
  })
  .catch(error => {
    console.error('Error:', error);
    showErrorMessage('Сталася помилка при голосуванні. Спробуйте ще раз.');
  })
  .finally(() => {
    // Re-enable button
    upvoteBtn.disabled = false;
  });
}

function updateVoteButtonStyles(requestId, userVoted) {
  const upvoteBtn = document.querySelector(`.upvote-btn-${requestId}`);
  
  if (userVoted) {
    upvoteBtn.className = `vote-btn upvote-btn-${requestId} flex items-center gap-1 px-1.5 py-0.5 rounded text-2xs transition-colors duration-200 bg-cyan-100 text-cyan-700 dark:bg-rose-900/30 dark:text-rose-400`;
  } else {
    upvoteBtn.className = `vote-btn upvote-btn-${requestId} flex items-center gap-1 px-1.5 py-0.5 rounded text-2xs transition-colors duration-200 text-gray-500 hover:bg-cyan-50 hover:text-cyan-600 dark:text-gray-400 dark:hover:bg-rose-900/20 dark:hover:text-rose-400`;
  }
}

function toggleAssignmentDropdown(requestId) {
  const dropdown = document.getElementById(`assignment-dropdown-${requestId}`);
  dropdown.classList.toggle('hidden');
  
  // Close other open dropdowns
  document.querySelectorAll('[id^="assignment-dropdown-"]').forEach(element => {
    if (element.id !== `assignment-dropdown-${requestId}`) {
      element.classList.add('hidden');
    }
  });
}

function assignRequest(requestId, scanlatorId) {
  // Close dropdown
  document.getElementById(`assignment-dropdown-${requestId}`).classList.add('hidden');
  
  fetch(`/translate/${requestId}/assign`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      scanlator_id: scanlatorId
    })
  })
  .then(response => response.json())
  .then(data => {
    if (data.error) {
      showErrorMessage(data.error);
      return;
    }
    
    if (data.success) {
      // Update the assignment status UI
      updateAssignmentStatus(requestId, data.scanlator_title, true);
      
      // Show success message
      showSuccessMessage(data.message);
    }
  })
  .catch(error => {
    console.error('Error:', error);
    showErrorMessage('Сталася помилка при призначенні запиту. Спробуйте ще раз.');
  });
}

function unassignRequest(requestId) {
  fetch(`/translate/${requestId}/unassign`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
      'Accept': 'application/json'
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.error) {
      showErrorMessage(data.error);
      return;
    }
    
    if (data.success) {
      // Update the assignment status UI to show as available
      updateAssignmentStatus(requestId, null, false);
      
      // Show success message
      showSuccessMessage(data.message);
    }
  })
  .catch(error => {
    console.error('Error:', error);
    showErrorMessage('Сталася помилка при відкликанні запиту. Спробуйте ще раз.');
  });
}

function updateAssignmentStatus(requestId, scanlatorTitle, isAssigned) {
  const statusContainer = document.getElementById(`assignment-status-${requestId}`);
  
  if (isAssigned && scanlatorTitle) {
    // Show as assigned with unassign button
    statusContainer.innerHTML = `
      <div class="flex items-center justify-between gap-1">
        <div class="flex items-center gap-1 min-w-0 flex-1">
          <div class="h-3 w-3 rounded-full bg-green-100 dark:bg-green-900/30 flex items-center justify-center flex-shrink-0">
            <svg class="h-1.5 w-1.5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
            </svg>
          </div>
          <span class="text-2xs font-medium text-green-700 dark:text-green-400 truncate">${scanlatorTitle}</span>
        </div>
        <button onclick="unassignRequest(${requestId})" 
                class="text-2xs bg-red-500 hover:bg-red-600 text-white font-medium px-2 py-0.5 rounded text-center flex-shrink-0 transition-colors duration-200">
          ×
        </button>
      </div>
    `;
  } else {
    // Show as available for assignment
    statusContainer.innerHTML = `
      <div class="flex items-center gap-1">
        <div class="h-3 w-3 rounded-full bg-orange-100 dark:bg-orange-900/30 flex items-center justify-center flex-shrink-0">
          <svg class="h-1.5 w-1.5 text-orange-600 dark:text-orange-400" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v3.586L7.707 9.293a1 1 0 00-1.414 1.414l3 3a1 1 0 001.414 0l3-3a1 1 0 00-1.414-1.414L11 10.586V7z" clip-rule="evenodd"/>
          </svg>
        </div>
        <span class="text-2xs text-orange-700 dark:text-orange-400">Вільний</span>
      </div>
    `;
  }
}

function showSuccessMessage(message) {
  showNotification(message, 'success');
}

function showErrorMessage(message) {
  showNotification(message, 'error');
}

function showNotification(message, type = 'success') {
  if (!message) return;
  
  // Calculate position based on existing notifications
  const existingNotifications = document.querySelectorAll('.notification-toast');
  const topOffset = 16 + (existingNotifications.length * 80); // 16px base + 80px per notification
  
  // Create notification element
  const notification = document.createElement('div');
  notification.classList.add('notification-toast');
  
  // Base classes for all notifications
  const baseClasses = 'fixed right-4 px-4 py-3 rounded-lg shadow-lg z-50 flex items-center gap-3 max-w-sm transform transition-all duration-300 ease-in-out';
  
  // Type-specific classes
  const typeClasses = {
    success: 'bg-green-100 dark:bg-green-900/30 border border-green-200 dark:border-green-800 text-green-800 dark:text-green-200',
    error: 'bg-red-100 dark:bg-red-900/30 border border-red-200 dark:border-red-800 text-red-800 dark:text-red-200'
  };
  
  notification.className = `${baseClasses} ${typeClasses[type] || typeClasses.success}`;
  notification.style.top = `${topOffset}px`;
  
  // Create icon
  const icon = document.createElement('div');
  icon.className = 'flex-shrink-0';
  
  if (type === 'success') {
    icon.innerHTML = `
      <svg class="w-5 h-5 text-green-600 dark:text-green-400" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
      </svg>
    `;
  } else {
    icon.innerHTML = `
      <svg class="w-5 h-5 text-red-600 dark:text-red-400" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
      </svg>
    `;
  }
  
  // Create message text
  const messageText = document.createElement('div');
  messageText.className = 'text-sm font-medium flex-1';
  messageText.textContent = message;
  
  // Create close button
  const closeButton = document.createElement('button');
  closeButton.className = 'flex-shrink-0 ml-2 text-current opacity-70 hover:opacity-100 transition-opacity duration-200';
  closeButton.innerHTML = `
    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
      <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
    </svg>
  `;
  
  // Assemble notification
  notification.appendChild(icon);
  notification.appendChild(messageText);
  notification.appendChild(closeButton);
  
  // Add to page with animation
  notification.style.transform = 'translateX(100%)';
  notification.style.opacity = '0';
  document.body.appendChild(notification);
  
  // Animate in
  requestAnimationFrame(() => {
    notification.style.transform = 'translateX(0)';
    notification.style.opacity = '1';
  });
  
  // Remove notification function
  const removeNotification = () => {
    notification.style.transform = 'translateX(100%)';
    notification.style.opacity = '0';
    setTimeout(() => {
      if (notification.parentNode) {
        notification.remove();
      }
    }, 300);
  };
  
  // Close button click handler
  closeButton.addEventListener('click', removeNotification);
  
  // Auto-remove after delay
  const autoRemoveDelay = type === 'error' ? 5000 : 3000; // Errors stay longer
  setTimeout(removeNotification, autoRemoveDelay);
}

// Inline editing functions
function toggleEditMode(requestId) {
  const viewMode = document.getElementById(`view-mode-${requestId}`);
  const editMode = document.getElementById(`edit-mode-${requestId}`);
  
  viewMode.classList.add('hidden');
  editMode.classList.remove('hidden');
}

function cancelEdit(requestId) {
  const viewMode = document.getElementById(`view-mode-${requestId}`);
  const editMode = document.getElementById(`edit-mode-${requestId}`);
  
  editMode.classList.add('hidden');
  viewMode.classList.remove('hidden');
}

function saveEdit(requestId) {
  const title = document.getElementById(`edit-title-${requestId}`).value;
  const author = document.getElementById(`edit-author-${requestId}`).value;
  const sourceUrl = document.getElementById(`edit-source-url-${requestId}`).value;
  const notes = document.getElementById(`edit-notes-${requestId}`).value;
  
  // Disable save button to prevent double-clicking
  const saveBtn = event.target;
  const originalText = saveBtn.textContent;
  saveBtn.disabled = true;
  saveBtn.textContent = 'Збереження...';
  
  fetch(`/translate/${requestId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
      'Accept': 'application/json'
    },
    body: JSON.stringify({
      translation_request: {
        title: title,
        author: author,
        source_url: sourceUrl,
        notes: notes
      }
    })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      // Update the view mode with new data
      updateRequestView(requestId, title, author, sourceUrl, notes);
      
      // Switch back to view mode
      cancelEdit(requestId);
      
      // Show success message
      showSuccessMessage(data.message);
    } else {
      // Show error messages
      if (data.errors && data.errors.length > 0) {
        showErrorMessage(data.errors.join(', '));
      } else {
        showErrorMessage('Сталася помилка при оновленні запиту.');
      }
    }
  })
  .catch(error => {
    console.error('Error:', error);
    showErrorMessage('Сталася помилка при оновленні запиту. Спробуйте ще раз.');
  })
  .finally(() => {
    // Re-enable save button
    saveBtn.disabled = false;
    saveBtn.textContent = originalText;
  });
}

function updateRequestView(requestId, title, author, sourceUrl, notes) {
  // Update title
  const titleElement = document.querySelector(`#view-mode-${requestId} h4`);
  if (titleElement) {
    titleElement.textContent = title;
  }
  
  // Update author
  const authorElements = document.querySelectorAll(`#view-mode-${requestId} .text-2xs`);
  authorElements.forEach(element => {
    if (element.textContent.includes('Автор:')) {
      const authorSpan = element.querySelector('span.font-medium');
      if (authorSpan) {
        authorSpan.textContent = author || '';
      }
      // Hide the whole div if author is empty
      if (!author || author.trim() === '') {
        element.style.display = 'none';
      } else {
        element.style.display = 'block';
      }
    }
    if (element.textContent.includes('Джерело:')) {
      const sourceLink = element.querySelector('a');
      if (sourceLink) {
        sourceLink.href = sourceUrl || '#';
      }
      // Hide the whole div if source URL is empty
      if (!sourceUrl || sourceUrl.trim() === '') {
        element.style.display = 'none';
      } else {
        element.style.display = 'block';
      }
    }
  });
  
  // Update notes
  const notesElement = document.querySelector(`#view-mode-${requestId} .whitespace-pre-line`);
  if (notesElement) {
    notesElement.textContent = notes;
  }
}

function deleteRequest(requestId) {
  // Disable any buttons to prevent double-clicking
  const requestCard = document.getElementById(`request-card-${requestId}`);
  if (requestCard) {
    requestCard.style.opacity = '0.5';
    requestCard.style.pointerEvents = 'none';
  }
  
  // Check if this is the newest request by looking for it in the newest request section
  const newestRequestSection = document.getElementById('newest-request-section');
  const isNewestRequest = newestRequestSection && newestRequestSection.querySelector(`#request-card-${requestId}`);
  
  fetch(`/translate/${requestId}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
      'Accept': 'application/json'
    }
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      // Show success message
      showSuccessMessage(data.message);
      
      if (isNewestRequest) {
        // If this was the newest request, reload the entire page to update both sections
        window.location.reload();
      } else {
        // If this was not the newest request, just reload the requests list
        reloadCurrentPage();
      }
    } else {
      // Re-enable the card on error
      if (requestCard) {
        requestCard.style.opacity = '1';
        requestCard.style.pointerEvents = 'auto';
      }
      
      showErrorMessage(data.error || 'Сталася помилка при видаленні запиту.');
    }
  })
  .catch(error => {
    console.error('Error:', error);
    
    // Re-enable the card on error
    if (requestCard) {
      requestCard.style.opacity = '1';
      requestCard.style.pointerEvents = 'auto';
    }
    
    showErrorMessage('Сталася помилка при видаленні запиту. Спробуйте ще раз.');
  });
}

// Close dropdowns when clicking outside
document.addEventListener('click', function(event) {
  if (!event.target.closest('.relative')) {
    document.querySelectorAll('[id^="assignment-dropdown-"]').forEach(element => {
      element.classList.add('hidden');
    });
  }
});
