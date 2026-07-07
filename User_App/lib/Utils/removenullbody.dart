Map<dynamic, dynamic> removeNullValues(Map<dynamic, dynamic> originalMap) {
  // Create a new map with non-null values
  Map<dynamic, dynamic> resultMap = {};

  originalMap.forEach((key, value) {
    if (value != null && value != '') {
      resultMap[key] = value;
    }
  });

  return resultMap;
}
