'use strict';

const React = require('react');
const Documents = require('./documents.jsx');
const styles = require('./documents-styles');

/**
 * Класс реализует справочник документов пользователя.
 */
class Docs extends React.PureComponent {
    constructor(props) {
        super(props);
        this.getDocumentType = this.getDocumentType.bind(this);
        this.btnEditClick = this.btnEditClick.bind(this);
        this.gridData = props.initData.result.data;
    }

    render() {
        return <Documents initData={this.props.initData}
                          docTypeId='DOKS'
                          ref = 'docs'
                          style={styles}
                          render={this.renderer}/>;
    }

    renderer() {
        return <div>Documents register special render</div>
    }

    /**
     * Обработчик для кнопки Add
     */
    btnAddClick() {
//        let docId = this.getDocumentType();
//        document.location.href = "/document/" + this.docTypeId + '0';
    }

    /**
     * Обработчик для кнопки Edit
     */
    btnEditClick(docId) {
        let docTypeId = this.getDocumentType(docId);
        if (docTypeId) {
            document.location.href = `/document/${docTypeId}/${docId}`; //@todo привести в порядок
        }
    }

    /**
     * метод ищет по ид документа его тип
     * @param docId ид документа
     * @returns {null} вернет тип или нул
     */
    getDocumentType(docId) {
        let row = this.gridData.filter(row => row.id === docId);
        return row[0].doc_type_id ? row[0].doc_type_id: null;
    }

}


module.exports = Docs;


