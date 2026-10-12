// The date an order reached its final status — a purchase "Received", a sale
// "Delivered". Kept on the order (receivedAt / deliveredAt) so the details
// can say WHEN, not just that it happened.
//
//   stampDone('Received', nextStatus, prevStatus, prevStamp)
//
// - moving into the final status stamps now;
// - already there (a re-save, or a payment edit) keeps the original date;
// - moving out of it clears the date, so a later re-receipt gets a fresh one.
function stampDone(doneStatus, nextStatus, prevStatus = null, prevStamp = null) {
  if (nextStatus !== doneStatus) return null;
  if (prevStatus === doneStatus && prevStamp) return prevStamp;
  return new Date();
}

module.exports = { stampDone };
