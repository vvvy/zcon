class Constants {
  /// Interval between successive incremental updates
  static const defaultIntervalMainS = 60;
  /// Interval between retries during error
  static const defaultIntervalErrorRetryS = 60;
  /// Interval between a device command and the update (refresh) that follows it
  static const defaultIntervalUpdateS = 5;

  /// battery level alert threshold, in %%
  static const defaultBatteryAlertLevel = 25;

  /// temperature normal range (outside triggers alert)
  static const defaultTempLoBound = 5.0;
  static const defaultTempHiBound = 30.0;

  /// number of retries on http before giving up
  static const maxErrorRetries = 5;
}