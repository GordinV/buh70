/**
 * готовим csv с разделителем
 * @param data
 * @returns {*}
 */
module.exports = (data) => {
    let csv = data.map(row => {
        // field
        return stringRow = Object.values(row).join(';');
    }).join('\n');
    return csv;
};

