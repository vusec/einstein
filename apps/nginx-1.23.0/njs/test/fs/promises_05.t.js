/*---
includes: [compareArray.js, compatFs.js]
flags: [async]
---*/

var dname = `${test_dir}/fs_promises_05`;
var dname_utf8 = `${test_dir}/fs_promises_αβγ_05`;
var fname = (d) => d + '/fs_promises_05_file';

var testSync = () => new Promise((resolve, reject) => {
    try {
        try { fs.unlinkSync(fname(dname)); } catch (e) {}
        try { fs.unlinkSync(fname(dname_utf8)); } catch (e) {}
        try { fs.rmdirSync(dname); } catch (e) {}
        try { fs.rmdirSync(dname_utf8); } catch (e) {}

        fs.mkdirSync(dname);

        try {
            fs.mkdirSync(dname);

        } catch (e) {
            if (e.syscall != 'mkdir' || e.code != 'EEXIST') {
                throw e;
            }
        }

        fs.writeFileSync(fname(dname), fname(dname));

        try {
            fs.rmdirSync(dname);

        } catch (e) {
            if (e.syscall != 'rmdir'
                || (e.code != 'ENOTEMPTY' && e.code != 'EEXIST'))
            {
                throw e;
            }
        }

        fs.unlinkSync(fname(dname));

        fs.rmdirSync(dname);

        fs.mkdirSync(dname_utf8, 0o555);

        try {
            fs.writeFileSync(fname(dname_utf8), fname(dname_utf8));

        } catch (e) {
            if (e.syscall != 'open' || e.code != 'EACCES') {
                throw e;
            }
        }

        try {
            fs.unlinkSync(dname_utf8);

        } catch (e) {
            if (e.syscall != 'unlink' || (e.code != 'EISDIR' && e.code != 'EPERM')) {
                throw e;
            }
        }

        fs.rmdirSync(dname_utf8);

        resolve();

    } catch (e) {
        reject(e);
    }
});


var testCallback = () => new Promise((resolve, reject) => {
    try {
        try { fs.unlinkSync(fname(dname)); } catch (e) {}
        try { fs.unlinkSync(fname(dname_utf8)); } catch (e) {}
        try { fs.rmdirSync(dname); } catch (e) {}
        try { fs.rmdirSync(dname_utf8); } catch (e) {}

        fs.mkdir(dname, (err) => {
            if (err) {
                reject(err);
            }

            fs.mkdir(dname, (err) => {
                if (!err || err.code != 'EEXIST') {
                    reject(new Error('fs.mkdir error 1'));
                }

                fs.rmdir(dname, (err) => {
                    if (err) {
                        reject(err);
                    }

                    resolve();
                });
            });
        });

    } catch (e) {
        reject(e);
    }
});


let stages = [];

Promise.resolve()
.then(testSync)
.then(() => {
    stages.push("mkdirSync");
})


.then(testCallback)
.then(() => {
    stages.push("mkdir");
})

.then(() => {
    try { fs.unlinkSync(fname(dname)); } catch (e) {}
    try { fs.unlinkSync(fname(dname_utf8)); } catch (e) {}
    try { fs.rmdirSync(dname); } catch (e) {}
    try { fs.rmdirSync(dname_utf8); } catch (e) {}
})
.then(() => fsp.mkdir(dname))
.then(() => fsp.mkdir(dname))
.catch((e) => {
    if (e.syscall != 'mkdir' || e.code != 'EEXIST') {
        throw e;
    }
})
.then(() => fsp.rmdir(dname))
.then(() => {
    stages.push("fsp.mkdir");
})
.then(() => assert.compareArray(stages, ['mkdirSync', 'mkdir', 'fsp.mkdir']))
.then($DONE, $DONE);
