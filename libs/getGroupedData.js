// will return date in format 'YYYY-MM-DD'
module.exports =    (data, group) => {
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
};