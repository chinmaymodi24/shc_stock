/* eslint-disable no-console */
// Cases taken from the real imported data. Run with:
//   node prisma/backfillClientContacts.test.js
// (No test runner in this project — plain asserts, non-zero exit on failure.)

const assert = require('assert');
const { splitContact } = require('./backfillClientContacts');

const cases = [
  {
    why: 'name and phone joined by a dash',
    input:
      '2nd Floor, Modi Nivas, In Lane of Canara Bank,, Ramnagar, Sabarmati,, Ahmedabad - 380005, Shri Shreyashbhai - 9428421959',
    want: {
      address:
        '2nd Floor, Modi Nivas, In Lane of Canara Bank,, Ramnagar, Sabarmati,, Ahmedabad - 380005',
      contactPerson: 'Shri Shreyashbhai',
      contactPhone: '9428421959',
    },
  },
  {
    why: 'phone behind a "mo." marker, no name',
    input: 'Gat No. 896, Kudalwadi Chikhali, Taluka Haveli, Dist. Pune - 411062, mo. 9923908368',
    want: {
      address: 'Gat No. 896, Kudalwadi Chikhali, Taluka Haveli, Dist. Pune - 411062',
      contactPerson: '',
      contactPhone: '9923908368',
    },
  },
  {
    why: 'phone split by a space',
    input: 'Plot No. 108, GIDC State,, POR, Ramangamdi,, Vadodara - 391243, Shri Ronakbhai Patel - 97250 33951',
    want: {
      address: 'Plot No. 108, GIDC State,, POR, Ramangamdi,, Vadodara - 391243',
      contactPerson: 'Shri Ronakbhai Patel',
      contactPhone: '9725033951',
    },
  },
  {
    why: 'two phones on one contact',
    input:
      '33, Puskar Industrial Estate,, Vatva, GIDC, Phase 1, Ahmedabad - 382445, Mr. Jayesh Mali - 9662900358, 9714445487',
    want: {
      address: '33, Puskar Industrial Estate,, Vatva, GIDC, Phase 1, Ahmedabad - 382445',
      contactPerson: 'Mr. Jayesh Mali',
      contactPhone: '9662900358 / 9714445487',
    },
  },
  {
    why: 'STD landline plus a mobile',
    input:
      'M-10, ADDA Industrial Estate,, Asansol - 713305 West Bengal., Mr. Rahul Anand - 0341-2258800, M 9800003381',
    want: {
      address: 'M-10, ADDA Industrial Estate,, Asansol - 713305 West Bengal.',
      contactPerson: 'Mr. Rahul Anand',
      contactPhone: '03412258800 / 9800003381',
    },
  },
  {
    why: 'international number',
    input: 'Bardghar 12 - Bhataulia, Nawalparasi,, Nepal., Mr. Domer Singh Saud - +977 9702625922',
    want: {
      address: 'Bardghar 12 - Bhataulia, Nawalparasi,, Nepal.',
      contactPerson: 'Mr. Domer Singh Saud',
      contactPhone: '9779702625922',
    },
  },
  {
    why: 'a plain address keeps every word',
    input: 'Shop No. A5 & 6, Shri Hari Complex,, N.H. 8/A, Morbi.',
    want: {
      address: 'Shop No. A5 & 6, Shri Hari Complex,, N.H. 8/A, Morbi.',
      contactPerson: '',
      contactPhone: '',
    },
  },
  {
    why: 'a PIN code is never mistaken for a phone',
    input: 'Sy. No. 18-23, Taverekere Venkatpura, Hosakote Tal., Bangalore - 5621232',
    want: {
      address: 'Sy. No. 18-23, Taverekere Venkatpura, Hosakote Tal., Bangalore - 5621232',
      contactPerson: '',
      contactPhone: '',
    },
  },
  {
    why: 'a landline still counts when a titled name introduces it',
    input: '345, G.V.M.M., Odhav,, Ahmedabad., Shri Yogeshbhai - 22902933',
    want: {
      address: '345, G.V.M.M., Odhav,, Ahmedabad.',
      contactPerson: 'Shri Yogeshbhai',
      contactPhone: '22902933',
    },
  },
  {
    why: 'empty address stays empty',
    input: '',
    want: { address: '', contactPerson: '', contactPhone: '' },
  },
];

let failed = 0;
for (const { why, input, want } of cases) {
  const got = splitContact(input);
  try {
    assert.deepStrictEqual(got, want);
    console.log(`  ok   ${why}`);
  } catch {
    failed++;
    console.log(`  FAIL ${why}`);
    console.log(`       input : ${JSON.stringify(input)}`);
    console.log(`       want  : ${JSON.stringify(want)}`);
    console.log(`       got   : ${JSON.stringify(got)}`);
  }
}

console.log(failed ? `\n${failed} failed` : `\nall ${cases.length} passed`);
process.exit(failed ? 1 : 0);
