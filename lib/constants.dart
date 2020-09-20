class Constants {
  /// battery level alert threshold, in %%
  static const batteryAlertLevel = 50;

  /// temperature normal range (outside triggers alert)
  static const tempLoBound = 5.0;
  static const tempHiBound = 30.0;

  /// number of retries on http before giving up
  static const maxErrorRetries = 5;
}