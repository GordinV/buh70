'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const styles = require('./journal-register-styles');
const {withRouter} = require('react-router-dom');

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
                                 ref = 'register'
                                 userData={this.props.userData}
                                 docTypeId='JOURNAL'
                                 btnEditClick = {this.btnEditClick}
                                 style={styles}
                                 render={this.renderer}/>;
    }

    renderer() {
        return <div>JOURNAL register special render</div>
    }

    /**
     * кастомный вызов метода клик
     */
    btnEditClick() {
        //getValue
        let docId = this.refs['register'].state.value;
        if (docId) {
            return this.props.history.push(`/raama/journal/${docId}`);
        }
    }

}


module.exports = withRouter(Documents);


