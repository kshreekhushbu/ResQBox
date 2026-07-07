/**
 * Timezone utility functions for converting between UTC and local time
 */

/**
 * Convert a Date object to local timezone string (Asia/Kolkata)
 * @param {Date} date - The date to convert
 * @returns {string} - Formatted local time string
 */
function toLocalTimeString(date) {
  if (!date) return null;
  
  return new Date(date).toLocaleString('en-IN', {
    timeZone: 'Asia/Kolkata',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  });
}

/**
 * Convert trip data to include local timezone information
 * @param {Object} trip - Trip object from database
 * @returns {Object} - Trip object with local timezone fields
 */
function convertTripToLocalTime(trip) {
  if (!trip) return trip;
  
  const localDepartureTime = new Date(trip.departureTime);
  const localArrivalTime = trip.arrivalTime ? new Date(trip.arrivalTime) : null;
  
  return {
    ...trip,
    departureTime: localDepartureTime.toISOString(),
    departureTimeLocal: toLocalTimeString(localDepartureTime),
    arrivalTime: localArrivalTime ? localArrivalTime.toISOString() : null,
    arrivalTimeLocal: toLocalTimeString(localArrivalTime)
  };
}

/**
 * Convert an array of trips to include local timezone information
 * @param {Array} trips - Array of trip objects
 * @returns {Array} - Array of trip objects with local timezone fields
 */
function convertTripsToLocalTime(trips) {
  if (!Array.isArray(trips)) return trips;
  
  return trips.map(trip => convertTripToLocalTime(trip));
}

/**
 * Create a local date string for database queries
 * @param {string} timeString - Time string in HH:MM format
 * @param {Date} date - Date object
 * @returns {string} - Date string in YYYY-MM-DD HH:MM:SS format
 */
function createLocalDateTimeString(timeString, date) {
  const [hours, minutes] = timeString.split(':').map(Number);
  
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  
  return `${year}-${month}-${day} ${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;
}

module.exports = {
  toLocalTimeString,
  convertTripToLocalTime,
  convertTripsToLocalTime,
  createLocalDateTimeString
};
