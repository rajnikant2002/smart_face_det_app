String getSuggestion(String state, String lighting, int usageTime) {
  if (usageTime >= 120) {
    return 'You\'ve been active for 2 hours. Take a longer break now!';
  }
  if (usageTime >= 30) {
    return '30 mins active. Time for a short break.';
  }
  if (state == 'Tired') {
    return 'Take a 5-min break 😴';
  }
  if (state == 'Stressed') {
    return 'Try breathing exercise 🧘';
  }
  if (lighting == 'Dark') {
    return 'Increase lighting 💡';
  }
  return 'You\'re doing great 👍';
}
