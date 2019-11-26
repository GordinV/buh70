
const data = [{"id":1,"kood":"test 1"},{"id":2,"kood":"test 2"}];
// rows
let csv;
    csvRows = data.map(row=> {
    // field
    return  stringRow = Object.values(row).join();
}).join('\n');

    console.log(csvRows);
