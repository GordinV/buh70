Date.prototype.daysInMonth = function() {
    return 33 - new Date(this.getFullYear(), this.getMonth(), 33).getDate();
};

let today = new Date();
let currentMonth = today.getMonth();
let currentYear = today.getFullYear();
let startMonth = new Date( currentYear, currentMonth, 2);
let daysInMonth = new Date().daysInMonth();

let finishMonth =  new Date( currentYear, currentMonth , daysInMonth + 1);
