let data = [{deebet: 10, kreedit: 20}, {deebet: 30, kreedit: 40}];

let sum = data.reduce((a, b) => {
        a.deebet =  a.deebet + b.deebet;
        a.kreedit = a.kreedit + b.kreedit;
        return a;
    });

console.log(sum);
