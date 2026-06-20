/**
 * Calendar layout utilities for the DateTime popup
 * Provides calendar grid calculations with Monday-first week layout
 */

// Weekday abbreviations (Monday-first)
const weekDays = [
    { day: "Mo" },
    { day: "Tu" },
    { day: "We" },
    { day: "Th" },
    { day: "Fr" },
    { day: "Sa" },
    { day: "Su" }
];

/**
 * Check if a year is a leap year
 * @param {number} year - The year to check
 * @returns {boolean} True if leap year
 */
function checkLeapYear(year) {
    return (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
}

/**
 * Get the number of days in a given month
 * @param {number} month - Month (0-11)
 * @param {number} year - Year
 * @returns {number} Number of days in the month
 */
function getMonthDays(month, year) {
    const daysInMonths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month === 1 && checkLeapYear(year)) {
        return 29;
    }
    return daysInMonths[month];
}

/**
 * Get a Date object offset by x months from current date
 * @param {number} x - Number of months to offset (can be negative)
 * @returns {Date} Date object for the first of that month
 */
function getDateInXMonthsTime(x) {
    const now = new Date();
    const targetDate = new Date(now.getFullYear(), now.getMonth() + x, 1);
    return targetDate;
}

/**
 * Get the day of week for a date (0 = Monday, 6 = Sunday)
 * @param {Date} date - The date to check
 * @returns {number} Day of week (0-6, Monday-first)
 */
function getDayOfWeekMondayFirst(date) {
    const jsDay = date.getDay(); // 0 = Sunday, 6 = Saturday
    // Convert to Monday-first: Sunday (0) becomes 6, others shift down by 1
    return jsDay === 0 ? 6 : jsDay - 1;
}

/**
 * Generate a 6x7 calendar grid for a given month
 * @param {Date} viewDate - Date object for the month to display
 * @param {boolean} highlightToday - Whether to mark today's date
 * @returns {Array} 6x7 array of {day: string, today: number} objects
 *   today values: -1 = other month, 0 = current month, 1 = today
 */
function getCalendarLayout(viewDate, highlightToday) {
    const year = viewDate.getFullYear();
    const month = viewDate.getMonth();
    
    const now = new Date();
    const currentDay = now.getDate();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();
    
    const daysInMonth = getMonthDays(month, year);
    const firstDayOfMonth = new Date(year, month, 1);
    const startDayOfWeek = getDayOfWeekMondayFirst(firstDayOfMonth);
    
    // Get previous month's days
    const prevMonth = month === 0 ? 11 : month - 1;
    const prevYear = month === 0 ? year - 1 : year;
    const daysInPrevMonth = getMonthDays(prevMonth, prevYear);
    
    const grid = [];
    let dayCounter = 1;
    let nextMonthDay = 1;
    
    for (let row = 0; row < 6; row++) {
        const week = [];
        for (let col = 0; col < 7; col++) {
            const cellIndex = row * 7 + col;
            
            if (cellIndex < startDayOfWeek) {
                // Previous month days
                const prevDay = daysInPrevMonth - startDayOfWeek + cellIndex + 1;
                week.push({ day: String(prevDay), today: -1 });
            } else if (dayCounter <= daysInMonth) {
                // Current month days
                let todayValue = 0;
                if (highlightToday && 
                    dayCounter === currentDay && 
                    month === currentMonth && 
                    year === currentYear) {
                    todayValue = 1;
                }
                week.push({ day: String(dayCounter), today: todayValue });
                dayCounter++;
            } else {
                // Next month days
                week.push({ day: String(nextMonthDay), today: -1 });
                nextMonthDay++;
            }
        }
        grid.push(week);
    }
    
    return grid;
}
