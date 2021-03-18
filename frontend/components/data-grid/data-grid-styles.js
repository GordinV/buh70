module.exports = {
    mainTable: {
        tableLayout: 'fixed',
        width: '-webkit-calc(100% + 16px)',
        borderCollapse: 'collapse',
        marginBottom:'20px'
    },
    headerTable: {
        tableLayout: 'fixed',
        width: '100%',
        borderCollapse: 'collapse',
    },
    footerTable: {
        tableLayout: 'fixed',
        width: '100%',
        borderCollapse: 'collapse'

    },

    th: {
        borderBottom: '1px solid black',
        backgroundColor: 'grey',
        height: '30px',
        border: '1px solid lightgray',
        display: 'table-cell',
        color:'black',
        boldColor: 'red'
    },

    thHidden: {
        borderBottom: '1px solid black',
        backgroundColor: 'grey',
        height: '1px',
        border: '1px solid lightgray',
        display: 'table-cell'
    },

    tr: {
        backgroundColor: 'white'
    },

    focused: {
        backgroundColor: 'lightblue'
    },

    td: {
        border: '1px solid lightgray',
        display: 'table-cell',
        paddingLeft: '5px'
    },

    icons: {
        asc: '/images/icons/sort-alpha-asc.png',
        desc: '/images/icons/sort-alpha-desc.png'
    },

    image: {
        margin: '1px'
    },

    wrapper: {
        height: 'inherit',
        overflow: 'auto',
        minHeight: '100px'
    },

    main: {
        height: 'inherit',
    },

    header: {
        overflow: 'hidden'
    },
    boolSumbol: {
        yes: {
            value: '\u2714',
            color: 'green'
        },
        no: {
            //value: '\u2716',
            color: null
        },
        null: {
            value: '-',
            color: null
        }
    },
    boolColour: {
        yes: null,
        no: null
    },


};

