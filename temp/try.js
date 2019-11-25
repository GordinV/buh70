var path = require('path');

var x = path.join('Users', 'Refsnes', '..', 'public','pdf','demo_path.js');
const wkhtmltopdf = require('wkhtmltopdf');

wkhtmltopdf('<h1>Test</h1><p>Hello world</p>', {output: 'c:/temp/doc.pdf'});
console.log(x);