module.exports = {
    grid: {
        mainTable: {
            width: '100%',
            td : {
                border:'1px solid black',
                display: 'table-cell',
                paddingLeft:'5px',
                nullColour:'lightGrey'
            },
            marginBottom:'20px'
        },
        headerTable: {
            width:'100%',
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

        gridContainer: {
            width: '100%'
        },
        boolColour: {
            yes: null,
            no: null
        },

    },
    // td custom styles
    custom: {
        positive: {
            backgroundColor: 'lightgreen'
        },
        negative: {
            backgroundColor: 'pink'
        }
    }
};