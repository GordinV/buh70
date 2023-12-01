module.exports = {
    grid: {
        mainTable: {
            tableLayout: 'fixed',
            position: 'relative',
            td: {
                border: '1px solid lightGrey',
                display: 'table-cell',
                paddingLeft: '5px',
            },
            minHeight: '50px',
            marginBottom: '10px'
        },
        headerTable: {
            tableLayout: 'fixed'
        },
    },
    ok: {
        backgroundColor:'lightgreen',
        width:'100%',
        textAlign: 'right'
    },
    error: {
        backgroundColor:'lightcoral',
        width:'100%',
        textAlign: 'right'
    },
    notValid: {
        backgroundColor:'yellow',
        width:'100%',
        textAlign: 'right'

    },

};
