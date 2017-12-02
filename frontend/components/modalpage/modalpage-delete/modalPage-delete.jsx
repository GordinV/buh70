'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    ModalPage = require('../modalPage.jsx'),
    styles = require('../modalpage-delete/modalpage-delete-styles');

class ModalPageDelete extends React.PureComponent {
    constructor(props) {
        super(props)
        this.state = {
            show: this.props.show
        }
    }

    componentWillReceiveProps(nextProps) {
        this.setState({show: nextProps.show});
    }

    render() {
        let modalObjects = ['btnOk', 'btnCancel'];

        return <ModalPage ref = 'modalPage'
            modalPageBtnClick={this.props.modalPageBtnClick}
            show={this.state.show}
            modalPageName='Delete document'>
            <div ref="container">
                <img ref="image" src={styles.icon}/>
                <span ref="message"> Удалить документ ? </span>
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