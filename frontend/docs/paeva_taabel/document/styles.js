module.exports = {
    docRow: {
        display: 'flex',
        flexDirection: 'row',
        /*
                border: '1px solid blue'
        */
    },
    docColumn: {
        display: 'flex',
        flexDirection: 'column',
        /*
                border: '1px solid yellow',
        */
        width: '50%'
    },
    doc: {
        display: 'flex',
        flexDirection: 'column',
        /*
                border: '1px solid brown'
        */
    },

    grid: {
        mainTable: {
            tableLayout: 'fixed',
            width:'-webkit-calc(100% + 16px)',
            position:'relative',
            top:'-30px',
            borderCollapse:'collapse'
        },
        headerTable: {
            tableLayout: 'fixed',
            width:'100%',
            borderCollapse:'collapse'
        },

        gridContainer: {
            width: '100%'
        },
        boolSumbol: {
            yes: {
                value: '\u2714',
                color: '#007300'
            },
            no: {
                value: null,
                color: 'red'
            }
        },

    },

    gridRow: {
        /*
                border: '1px solid black',
        */
        backgroundColor: 'white',
        position: 'relative',
        margin: '10% 30% 10% 30%',
        width: 'auto',
        opacity: '1',
        top: '100px'
    },

    btnEdit: {
        width: 'min-content'
    },
    total: {
        width: 'auto'
    }


};