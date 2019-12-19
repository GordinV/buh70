'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    ModalPage = require('../modalPage.jsx'),
    styles = require('../modalpage-delete/modalpage-delete-styles');

class ModalPageDelete extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            show: this.props.show
        }
    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.show !== prevState.show ) {
            return {show: nextProps.show};
        } else return null;
    }

    render() {
        let modalObjects = ['btnOk', 'btnCancel'];

        return <ModalPage ref = 'modalPage'
            modalPageBtnClick={this.props.modalPageBtnClick}
            show={this.state.show}
            modalPageName='Delete document'>
            <div ref="container">
                <img ref="image" src={styles.icon}/>
                <span ref="message"> Kas kustuta dokument ? </span>
            </div>
        </ModalPage>
    }
}
/*
ModalPageDelete.propTypes = {
    modalPageBtnClick: PropTypes.func.isRequired
}
*/
module.exports = ModalPageDelete;