import consumer from "channels/consumer"

// Global chat functions for widget controller
window.ChatChannel = {
  speak: function(message) {
    const subscription = consumer.subscriptions.subscriptions.find(sub => 
      sub.identifier === JSON.stringify({channel: "ChatChannel"})
    );
    if (subscription) {
      subscription.speak(message);
    }
  }
};
