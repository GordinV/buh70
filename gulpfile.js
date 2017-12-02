'use strict';
const gulp = require('gulp');
const mocha = require('gulp-mocha');
const babel = require('babel-core/register');
const gulpBabel = require('gulp-babel');

// Compiler for React tests
//require('./test/compiler.js');

gulp.task("test-jsx", function(){
    return gulp
        .src('./test/*.js?', { read: false })
        .pipe(gulpBabel({
            presets: ['es2015', 'react']
        }))
        .pipe(mocha());
});

gulp.task('mocha', function() {
    return gulp
        .src('./test/*.js?', { read: false })
        .pipe(mocha(
            {compilers: {
                js: babel
            }
            }));
});

gulp.task('default', [
    'mocha'
]);
/*


gulp.task('default', function() {
    gulp.run('test');
});
gulp.task('test', function () {
    return gulp.src('./test/doc-button.jsx', {read: false})
    // gulp-mocha needs filepaths so you can't have any plugins before it
        .pipe(mocha());
});
*/

//gulp.task('default', gulp.series('test'));