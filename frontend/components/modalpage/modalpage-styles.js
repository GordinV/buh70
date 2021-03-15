module.exports = {
    container: {
        position: 'fixed',
        top: '0',
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(255, 255, 255, 0.25)',
        display: 'flex',
        justifyContent:'center'
    },
    modalPage: {
        position: 'relative',
        border: '1px solid black',
        background: 'white',
        margin: '8px',
        borderRadius: '4px',
        outline: 'none',
        display: 'flex',
        flexDirection: 'column',
        alignSelf: 'center',
        height: 'auto',
        maxHeight: '95%',
        overflow: 'auto',
        zIndex: 1


    },
    modalPageContent: {
        padding: '10px',
        margin: '10px'
    },
    header: {
        height: '30px',
        width: '100%',
        border: '1px solid darkgray',
        background: 'lightgray',
        display: 'flex',
        justifyContent: 'space-between'
    },

    headerName: {
        color: 'white',
        alignSelf: 'center',
        marginLeft:'10px'
    },

    modalFooter: {
        alignSelf: 'center',
        display: 'flex',
        marginBotton:'10px'
    },

    modalPageButtons: {
        height: '30px',
        width:'100px',
        marginBottom:'10px'
    },

    buttonsSeparator : {
        width:'10px'
    },

    buttonClose: {
        borderRadius: '50%',
        backgroundColor: 'lightgray',
        border:'none',
        fontWeight: '900',
        margin: '0px 0px'

    },

    left: {
        right: 'auto',
        left: '0'
    },

    right: {
        left: 'auto',
        right: '0'
    },
    defaultButton: {
        backgroundColor: 'lightBlue'
    }

};