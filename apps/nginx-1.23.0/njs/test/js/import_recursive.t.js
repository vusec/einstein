/*---
includes: []
flags: []
paths: [test/js/module/]
---*/

import m from 'recursive.js';

assert.sameValue(m, 42);
