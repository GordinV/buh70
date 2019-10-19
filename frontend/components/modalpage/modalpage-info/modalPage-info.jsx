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

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.show !== prevState.show ) {
            return {show: nextProps.show};
        } else return null;
    }


    render() {

        let systemMessage = this.props.systemMessage ? this.props.systemMessage : '',
            modalObjects = ['btnOk'];

        return <ModalPage ref = 'modalPage'
            modalPageBtnClick={this.props.modalPageBtnClick}
            modalPageName='Warning!'
            modalObjects={modalObjects}
        >
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
};

module.exports = ModalPageInfo;
