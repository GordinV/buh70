module.exports = {
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
    footerTable: {
        tableLayout: 'fixed',
        width:'100%',
        borderCollapse:'collapse'

    },

    th: {
        borderBottom: '1px solid black',
        backgroundColor: 'grey',
        height:'30px',
        border:'1px solid lightgray',
        display: 'table-cell'
    },

    thHidden: {
        borderBottom: '1px solid black',
        backgroundColor: 'grey',
        height:'1px',
        border:'1px solid lightgray',
        display: 'table-cell'
    },

    tr: {
        backgroundColor: 'white'
    },

    focused: {
        backgroundColor: 'lightblue'
    },

    td : {
        border:'1px solid lightgray',
        display: 'table-cell',
        paddingLeft:'5px'
    },

    icons: {
        asc : '/images/icons/sort-alpha-asc.png',
        desc : '/images/icons/sort-alpha-desc.png'
    },

    image: {
        margin:'1px'
    },

    wrapper: {
        height:'inherit',
        overflow: 'scroll'
    },

    main: {
        height:'inherit',
    },

    header: {
        overflow: 'hidden'

    },
    boolSumbol: {
        yes: {
            value: '\u2714',
            color: 'black'
        },
        no: {
            value: '\u2716',
            color: 'red'
        }
    },
    boolColour: {
        yes: 'green',
        no: null
    },



};

