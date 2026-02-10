class Timer {
  double _previousTime = 0;
  double _currentTime = 0;
  final Stopwatch _stopwatch = Stopwatch();

  double _delta = 0;
  double _elapsed = 0;

  double _timescale = 1;

  Timer() {
    _stopwatch.start();
  }

  double getDelta() {
    return _delta / 1000;
  }

  double getElapsed() {
    return _elapsed / 1000;
  }

  double getTimescale() {
    return _timescale;
  }

  Timer setTimescale(double timescale) {
    _timescale = timescale;
    return this;
  }

  Timer reset() {
    _currentTime = _stopwatch.elapsedMilliseconds.toDouble();
    return this;
  }

  void dispose() {
    _stopwatch.stop();
  }

  Timer update([double? timestamp]) {
    _previousTime = _currentTime;
    _currentTime = timestamp ?? _stopwatch.elapsedMilliseconds.toDouble();

    _delta = (_currentTime - _previousTime) * _timescale;
    _elapsed += _delta;

    return this;
  }
}
