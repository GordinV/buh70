let data = [
    {id: 1, nimetus: 'nimi', group1: '1', group2: '2'}, {
    id: 2,
    nimetus: 'nimi 2',
    group1: '1',
    group2: '2'
}, {id: 3, nimetus: 'nimi 3', group1: '2', group2: '3'},
    {id: 4, nimetus: 'nimi 4', group1: '3', group2: '3'}];
let group = ['group1', 'group2'];
let groupedData = {};
let elements = [];
// если передан массив группировок
if (typeof group && Array.isArray(group)) {
    // 1 уровень группировки
    groupedData = getGroupedData(data, group[0]).map(row => {
        // второй уровень? ключ
        let level = Object.keys(row);
        let dt = row[level[0]];
        // вторая группировка
        let levelData = getGroupedData(row[level[0]], group[1]);
        // присваиваем
        row[level[0]] = levelData;
        return row;
    });

} else {
    // просто группировка
    groupedData = getGroupedData(data, group);
}
console.log('groupedData', JSON.stringify(groupedData));

function getGroupedData(data, group) {
    const parent = new Set;
    console.log('group', group);
    data.forEach(row => {
        parent.add(row[group])
    });

    result = Array.from(parent).map(field => {
        const subGroupData = data.filter(row => row[group] === field);
        let returnData = {};
        returnData[field] = subGroupData;
        return returnData;
    });
    return result;
}