'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    ModalPage = require('../modalPage.jsx'),
    styles = require('../modalpage-info/modalpage-info-styles');

class ModalPageInfo extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            show: this.props.show
        }

    }

    componentWillReceiveProps(nextProps) {
        this.setState({show: nextProps.show});
    }

    render() {

        let systemMessage = this.props.systemMessage ? this.props.systemMessage : '',
            modalObjects = ['btnOk'];

        return <ModalPage ref = 'modalPage'
            modalPageBtnClick={this.props.modalPageBtnClick}
            modalPageName='Warning!'
            modalObjects={modalObjects}>
            <div ref="container">
                <img ref="image" src={styles.icon}/>
                <span> {systemMessage} </span>
            </div>
        </ModalPage>
    }
}

ModalPageInfo.propTypes = {
    systemMessage: PropTypes.string,
    modalPageBtnClick: PropTypes.func
}

module.exports = ModalPageInfo;
