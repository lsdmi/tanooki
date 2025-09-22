import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star"]

  setRating(event) {
    const rating = parseInt(event.currentTarget.dataset.starValue)
    const fictionId = event.currentTarget.dataset.fictionId

    // Update visual state immediately with user's rating
    this.updateStarDisplay(rating)

    // Send rating to server and update stats with server response
    this.submitRating(fictionId, rating)
  }

  updateStarDisplay(rating) {
    this.starTargets.forEach((star, index) => {
      const starValue = parseInt(star.dataset.starValue)
      if (starValue <= rating) {
        star.classList.remove('text-gray-300', 'dark:text-gray-600')
        star.classList.add('text-cyan-600', 'dark:text-rose-700')
      } else {
        star.classList.remove('text-cyan-600', 'dark:text-rose-700')
        star.classList.add('text-gray-300', 'dark:text-gray-600')
      }
    })
    
    // Update the fish label immediately when user clicks
    this.updateFishLabelForUser(rating)
  }

  updateFishLabelForUser(userRating) {
    // Find the fish label and update it with the user's rating
    const fishLabel = document.querySelector('.text-xs.text-gray-500.dark\\:text-gray-400')
    if (fishLabel) {
      fishLabel.textContent = `Ваша оцінка (${userRating})`
    }
  }

  async submitRating(fictionId, rating) {
    try {
      const response = await fetch(`/fictions/${fictionId}/fiction_ratings`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ rating: rating })
      })

      if (response.ok) {
        const data = await response.json()
        this.updateRatingStats(data.average_rating, data.rating_count)
        // Keep showing user's individual rating, not average
        // this.updateStarDisplay(data.average_rating) // Removed - fish show user rating
      } else {
        console.error('Failed to submit rating')
        // Revert visual state on error
        this.revertStarDisplay()
      }
    } catch (error) {
      console.error('Error submitting rating:', error)
      this.revertStarDisplay()
    }
  }

  updateRatingStats(averageRating, ratingCount) {
    // Update the rating statistics display
    const ratingDisplay = document.querySelector('[data-rating-stats]')
    if (ratingDisplay) {
      const averageElement = ratingDisplay.querySelector('.average-rating')
      const countElement = ratingDisplay.querySelector('.rating-count')

      if (averageElement) {
        averageElement.textContent = averageRating > 0 ? averageRating : '—'
      }

      if (countElement) {
        countElement.textContent = `${ratingCount} оцінок`
      }

      // Update non-logged-in fish display to show rounded up average
      const staticFish = ratingDisplay.parentElement.querySelectorAll('span[class*="w-8 h-8"]')
      if (staticFish.length > 0) {
        const roundedRating = Math.ceil(averageRating)
        staticFish.forEach((fish, index) => {
          const fishValue = index + 1
          if (fishValue <= roundedRating) {
            fish.classList.remove('text-gray-300', 'dark:text-gray-600')
            fish.classList.add('text-cyan-600', 'dark:text-rose-700')
          } else {
            fish.classList.remove('text-cyan-600', 'dark:text-rose-700')
            fish.classList.add('text-gray-300', 'dark:text-gray-600')
          }
        })
      }
    }

    // Update the fish label with new average rating
    this.updateFishLabel(averageRating)
  }

  updateFishLabel(averageRating) {
    // Find the fish label and update it with the new average
    const fishLabel = document.querySelector('.text-xs.text-gray-500.dark\\:text-gray-400')
    if (fishLabel) {
      // Check if user is logged in by looking for interactive fish buttons
      const interactiveFish = document.querySelectorAll('button[data-rating-target="star"]')
      if (interactiveFish.length > 0) {
        // User is logged in - show their individual rating
        // We need to get the current user's rating from the active fish
        let userRating = 0
        interactiveFish.forEach(fish => {
          if (fish.classList.contains('text-cyan-600') || fish.classList.contains('dark:text-rose-700')) {
            userRating = Math.max(userRating, parseInt(fish.dataset.starValue))
          }
        })
        fishLabel.textContent = `Ваша оцінка (${userRating})`
      } else {
        // User is not logged in - show community average
        fishLabel.textContent = `Середня оцінка (${averageRating})`
      }
    }
  }

  revertStarDisplay() {
    // Revert to original state - this would need the original rating
    // For now, we'll just show a brief error state
    this.starTargets.forEach(star => {
      star.classList.add('text-red-400')
      setTimeout(() => {
        star.classList.remove('text-red-400')
        // Note: In a real implementation, you'd want to restore the original state
      }, 1000)
    })
  }
}
