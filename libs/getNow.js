// will return date in format 'YYYY-MM-DD'
module.exports = (now = new Date()) => {
    return now.toISOString().substring(0, 10);
};