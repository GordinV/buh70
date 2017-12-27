'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./arv-register-styles');
const {withRouter} = require('react-router-dom');
const DOC_TYPE_ID = 'ARV';

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.btnEditClick = this.btnEditClick.bind(this);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 userData={this.props.userData}
                                 ref = 'register'
                                 btnEditClick = {this.btnEditClick}
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return <div>Arve register special render</div>
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


