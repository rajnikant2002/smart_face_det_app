String getSuggestion(String state, String lighting, int usageTime) {
  if (state == 'Tired') {
    return 'Take a 5-min break 😴';
  }
  if (state == 'Stressed') {
    return 'Try breathing exercise 🧘';
  }
  if (lighting == 'Dark') {
    return 'Increase lighting 💡';
  }
  if (usageTime > 30) {
    return 'You\'ve been active for 30 mins, take a break!';
  }
  return 'You\'re doing great 👍';
}
