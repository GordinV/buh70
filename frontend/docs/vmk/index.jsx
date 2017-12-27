'use strict';

const React = require('react');
const {withRouter} = require('react-router-dom');

const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./vmk-register-styles');
const DOC_TYPE_ID = 'vmk';

/**
 * Класс реализует документ приходного платежного ордера.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.btnEditClick = this.btnEditClick.bind(this);

    }

    render() {
        return <DocumentRegister initData={this.props.initData} userData={this.props.userData}
                                 ref = 'register'
                                 btnEditClick = {this.btnEditClick}
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return <div>VMK register special render</div>
    }

    /**
     * кастомный вызов метода клик
     */
    btnEditClick() {
        //getValue
        let docId = this.refs['register'].state.value;
        if (docId) {
            return this.props.history.push(`/raama/${DOC_TYPE_ID}/${docId}`);
        }
    }

}


module.exports = withRouter(Documents);


