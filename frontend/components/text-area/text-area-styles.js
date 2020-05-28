module.exports = {
    input: {
        width: '100%',
        borderRadius:'3px',
        overflow: 'scroll',
        height: 'fit-content',
        ':focus': {
            backgroundColor: 'lightpink'
        },
        border: '1px solid gray'

    },
    focused: {
        backgroundColor: 'lightblue'
    },
    readOnly: {
        backgroundColor: '#F3EFEF'
    },
    wrapper: {
        margin: '5px',
        display: 'flex',
        width: '98%',
        flexDirection: 'column'
    },
    label : {
        margin: '5px'
    }
};

