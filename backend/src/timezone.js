// ─────────────────────────────────────────────────────────────────────────────
// The business runs on Indian time, whatever clock the server is on.
//
// "Today" (the expected-delivery sweep), "this month" (every MTD card), the
// financial year (bill and order numbers) and the dashboard's months are all
// worked out with plain `new Date(...)` arithmetic, which uses the process's
// timezone. On a UTC host (Render, most clouds) that put the day boundary at
// 05:30 IST: an order due today was only marked delivered at 05:30 next
// morning, and sales made after midnight IST counted toward the wrong day.
//
// Setting TZ before anything reads a date fixes all of them at once. Node
// applies a runtime change to process.env.TZ. Override with BUSINESS_TZ.
// ─────────────────────────────────────────────────────────────────────────────

const BUSINESS_TZ = process.env.BUSINESS_TZ || 'Asia/Kolkata';
process.env.TZ = BUSINESS_TZ;

module.exports = { BUSINESS_TZ };
