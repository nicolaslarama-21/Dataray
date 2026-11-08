/// Keeps visits in order; going back does not add another visit.
class TabHistory {
  final _visits = <int>[0];
  int get current => _visits.last;
  bool get canGoBack => _visits.length > 1;
  void select(int tab) {
    if (tab == current) return;
    _visits.add(tab);
  }

  bool back() {
    if (!canGoBack) return false;
    _visits.removeLast();
    return true;
  }
}
