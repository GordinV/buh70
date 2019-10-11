module.exports = {
    docRow: {
        display: 'flex',
        flexDirection: 'row wrap',
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
        position: 'relative',
        height: '90vh',
        display: 'flex',
        flexDirection: 'column',
        /*
                border: '1px solid brown'
        */
    },
    gridContainer: {
        display: 'flex',
        flexFlow: 'row wrap',
        height: '87%',
    },
    grid: {
        mainTable: {
            tableLayout: 'fixed',
            position:'relative',
        },
        headerTable: {
            tableLayout: 'fixed',
        },
    },
    limit: {
        width: '20%'
    }
};