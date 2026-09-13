const { PrismaClient } = require('@prisma/client');
const { decimalsToNumbers } = require('./decimalToNumber');

// Every query's result is walked once and its Decimal columns handed back as
// plain numbers - the shape every route was written against. See
// decimalToNumber.js for why this is done here rather than at each of the
// ~40 arithmetic expressions across the routes.
//
// It is applied at $allOperations rather than per field, because the money
// also comes back from aggregate() and groupBy() - and those were the cases
// that produced a silently wrong total rather than an error.
const prisma = new PrismaClient().$extends({
  query: {
    $allModels: {
      async $allOperations({ args, query }) {
        return decimalsToNumbers(await query(args));
      },
    },
  },
});

module.exports = prisma;
