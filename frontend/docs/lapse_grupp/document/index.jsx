'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    Select = require('../../../components/select/select.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    styles = require('./styles');

const LIBRARIES = [
    {id: 'nomenclature', filter: `where dok = 'ARV'`}
];

class LapseGrupp extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            module: 'lapsed'
        };

        this.renderer = this.renderer.bind(this);
        this.createGridRow = this.createGridRow.bind(this);
        this.gridValidateFields = this.gridValidateFields.bind(this);

//        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
    }

    render() {
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 module={this.state.module}
                                 docTypeId='LAPSE_GRUPP'
                                 libs={LIBRARIES}
                                 userData={this.props.userData}
                                 initData={initData}
                                 renderer={this.renderer}
                                 createGridRow={this.createGridRow}
                                 gridValidator={this.gridValidateFields}
                                 history={this.props.history}
                                 focusElement={'input-kood'}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let isEditMode = self.state.edited;

        if ((self.docData.id === 0 || !self.docData.parentid) && this.state.lapsId) {
            //new record
            self.docData.parentid = this.state.lapsId;
        }

        let gridValue;
        if (self.gridRowData) {
            gridValue = self.gridRowData.id ? self.gridRowData.id : null;
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title='Kood:'
                                   name='kood'
                                   value={self.docData.kood || ''}
                                   ref='input-kood'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

                        <InputText title='Nimetus:'
                                   name='nimetus'
                                   value={self.docData.nimetus || ''}
                                   ref='input-nimetus'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>
                        <label>
                            All üksused
                            <InputText title=''
                                       name='all_yksus_1'
                                       value={self.docData.all_yksus_1 || ''}
                                       ref='input-all_yksus_1'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title=''
                                       name='all_yksus_2'
                                       value={self.docData.all_yksus_2 || ''}
                                       ref='input-all_yksus_2'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title=''
                                       name='all_yksus_3'
                                       value={self.docData.all_yksus_3 || ''}
                                       ref='input-all_yksus_3'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title=''
                                       name='all_yksus_4'
                                       value={self.docData.all_yksus_4 || ''}
                                       ref='input-all_yksus_4'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title=''
                                       name='all_yksus_5'
                                       value={self.docData.all_yksus_5 || ''}
                                       ref='input-all_yksus_5'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                        </label>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <DataGrid source='teenused'
                              gridData={self.docData.gridData}
                              gridColumns={self.docData.gridConfig}
                              showToolBar={isEditMode}
                              createGridRow={this.createGridRow}
                              handleGridRow={self.handleGridRow}
                              handleGridBtnClick={self.handleGridBtnClick}
                              readOnly={!isEditMode}
                              style={styles.grid.headerTable}
                              ref="data-grid"/>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Märkused"
                              name='muud'
                              ref="textarea-muud"
                              onChange={self.handleInputChange}
                              value={self.docData.muud || ''}
                              readOnly={!isEditMode}/>
                </div>
                {self.state.gridRowEdit ?
                    this.createGridRow(self)
                    : null}

            </div>
        );
    }

    /**
     * формирует объекты модального окна редактирования строки грида
     * @returns {XML}
     */
    createGridRow(self) {
        let row = self.gridRowData ? self.gridRowData : {},
            validateMessage = '', // self.state.warning
            buttonOkReadOnly = validateMessage.length > 0 || !self.state.checked,
            modalObjects = ['btnOk', 'btnCancel'];

        if (buttonOkReadOnly) {
            // уберем кнопку Ок
            modalObjects.splice(0, 1);
        }

        if (!row) return <div/>;

        return (<div className='.modalPage'>
                <ModalPage
                    modalObjects={modalObjects}
                    ref="modalpage-grid-row"
                    show={true}
                    modalPageBtnClick={self.modalPageClick}
                    modalPageName='Rea lisamine / parandamine'>
                    <div ref="grid-row-container">
                        {self.state.gridWarning.length ? (
                            <div style={styles.docRow}>
                                <span>{self.state.gridWarning}</span>
                            </div>
                        ) : null}

                        <div style={styles.docRow}>
                            <Select title="Teenus"
                                    name='nomid'
                                    libs="nomenclature"
                                    data={self.libs['nomenclature']}
                                    value={row.nomid || 0}
                                    defaultValue={row.kood || ''}
                                    ref='nomid'
                                    placeholder='Teenuse kood'
                                    onChange={self.handleGridRowChange}/>
                        </div>
                        <div style={styles.docRow}>

                            <InputNumber title='Kogus: '
                                         name='kogus'
                                         value={Number(row.kogus) || 1}
                                         bindData={false}
                                         ref='kogus'
                                         onChange={self.handleGridRowInput}/>
                        </div>

                        <div style={styles.docRow}>

                            <InputNumber title='Hind: '
                                         name='hind'
                                         value={Number(row.hind) || 0}
                                         bindData={false}
                                         ref='hind'
                                         onChange={self.handleGridRowInput}/>
                        </div>
                    </div>
                    <div><span>{validateMessage}</span></div>
                </ModalPage>
            </div>
        );
    }

    /**
     * валидатор для строки грида
     * @returns {string}
     */
    gridValidateFields() {
        let warning = '';
        let doc = this.refs['document'];
        if (doc && doc.gridRowData) {

            // только после проверки формы на валидность
            if (doc.gridRowData && !doc.gridRowData['nomid']) warning = warning + ' Puudub operatsioon';

            //подставим наименование услогу

            if (doc.gridRowData['nomid']) {

                let nomDataName = doc.libs['nomenclature'].find(lib => Number(lib.id) === Number(doc.gridRowData['nomid']));

                doc.gridRowData['kood'] = nomDataName.kood;
                doc.gridRowData['nimetus'] = nomDataName.nimetus;

                if (!doc.gridRowData['hind']) {
                    doc.gridRowData['hind'] = nomDataName.hind;
                }
            }

            if (!doc.gridRowData['kogus']) {
                doc.gridRowData['kogus'] = 1;
            }


        }
        return warning;

    }


}

LapseGrupp.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

LapseGrupp.defaultProps = {
    params: {docId: 0},
    initData: {},
    userData: {}
};


module.exports = (LapseGrupp);