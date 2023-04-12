module.exports = (data, group) => {
    // если передан массив группировок
    if (typeof group && Array.isArray(group)) {
        // 1 уровень группировки
        let groupedData = getGroupedData(data, group[0]).map(row => {
            // второй уровень? ключ
            let level = Object.keys(row);

            if (group[1]) {
                // вторая группировка
                let levelData = getGroupedData(row[level[0]], group[1]);
                // присваиваем
                row[level[0]] = levelData;
            }

            return row;
        });
        return groupedData;
    } else {
        // просто группировка
        return getGroupedData(data, group);
    }

};

function getGroupedData(data, group) {
    const parent = new Set;
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