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
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        /*
                border: '1px solid brown'
        */
    },
    gridContainer: {
        display: 'flex',
        flexFlow: 'row wrap',
        height: '95%',
    },
    grid: {
        mainTable: {
            tableLayout: 'fixed',
            position:'relative',
            td: {
                border: '1px solid lightGrey',
                display: 'table-cell',
                paddingLeft: '5px',
            },
            minHeight: '200px',
            marginBottom:'20px'
        },
        headerTable: {
            tableLayout: 'fixed'
        },
    },
    limit: {
        width: '20%',
        margin: '5px 2px'
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
    total: {
        width: 'auto'
    },

};