'use strict';

const React = require('react');
const Documents = require('./../documents/documents.jsx');
const styles = require('./docs-register-styles');
const {withRouter} = require('react-router-dom');
const DOC_TYPE_ID = 'document';

/**
 * Класс реализует справочник документов пользователя.
 */
class Docs extends React.PureComponent {
    constructor(props) {
        super(props);
        this.gridData = props.initData.result.data;
        this.btnEditClick = this.btnEditClick.bind(this);
    }

    render() {
        return <Documents initData={this.props.initData}
                          userData={this.props.userData}
                          docTypeId='DOCUMENT'
                          ref = 'register'
                          style={styles}
                          btnEditClick = {this.btnEditClick}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>Docs types register special render</div>
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


module.exports = withRouter(Docs);


