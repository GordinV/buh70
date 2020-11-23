const getPayDueDate = (kpv) => {
    let l_pay_dt = new Date(kpv.getFullYear(), kpv.getMonth(), 20);
    // Не так.Если счет выставлен с 10-го числа этого месяца по 9-е число следующего месяца, то ставим 20 число следующего
    if (new Date(kpv).getDate() > 10) {
        l_pay_dt = new Date(l_pay_dt.setMonth(l_pay_dt.getMonth() + 1));
    }
    console.log('l_pay_dt', l_pay_dt);
    return l_pay_dt;
};

let kpv = getPayDueDate(new Date('2020-11-01'));

console.log('kpv', kpv);
