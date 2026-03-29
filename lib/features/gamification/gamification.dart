/// Points and streak; reward rules align with healthy camera session state.
class Gamification {
  int points = 0;
  int streak = 0;

  void rewardUser() {
    points += 10;
    streak += 1;
  }

  static bool shouldReward({
    required String stateKey,
    required String lightingKey,
  }) {
    return lightingKey == 'Good' &&
        (stateKey == 'Neutral' || stateKey == 'Happy');
  }
}
