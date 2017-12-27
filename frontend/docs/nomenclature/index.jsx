'use strict';

const React = require('react');
const {withRouter} = require('react-router-dom');

const Documents = require('./../documents/documents.jsx');
const styles = require('./nomenclature-register-styles');
const DOC_TYPE_ID = 'nomenclature';

/**
 * Класс реализует документ справочника признаков.
 */
class Nomenclatures extends React.PureComponent {
    constructor(props) {
        super(props);
        this.btnEditClick = this.btnEditClick.bind(this);
    }

    render() {
        return <Documents initData={this.props.initData} userData={this.props.userData}
                          ref = 'register'
                          btnEditClick = {this.btnEditClick}
                          docTypeId={DOC_TYPE_ID}
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>NOMENCLATURE register special render</div>
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


module.exports = withRouter(Nomenclatures);


