const data = [{
    id: 1,
    name: 'name value',
    lisa: 'lisa value',
    hideFilter: true
},
    {
        id: 2,
        name: 'name value 2',
        lisa: 'lisa value 2',
        hideFilter: false    },
    {
        id: 3,
        name: 'name value 3',
        lisa: 'lisa value 3'}
];

// head
let notEmptyFilter = data.filter(row => {
    console.log('!row.hideFilter',!row.hideFilter);
    return !row.hideFilter;
});

console.log(notEmptyFilter);