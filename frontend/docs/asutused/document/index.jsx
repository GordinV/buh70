'use strict';
const React = require('react');
const PropTypes = require('prop-types');

const DocContext = require('../../../doc-context');

const
    DocumentTemplate = require('./../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    CheckBox = require('../../../components/input-checkbox/input-checkbox.jsx'),

    styles = require('./asutused.styles');


class Asutused extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            loadedData: false
        };

        this.renderer = this.renderer.bind(this);
        this.createGridRow = this.createGridRow.bind(this);

    }

    render() {
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 history={this.props.history}
                                 module={DocContext.module}
                                 docTypeId='ASUTUSED'
                                 initData={this.props.initData}
                                 renderer={this.renderer}
                                 focusElement={'input-regkood'}

        />
    }

    renderer(self) {
        if (!self.docData) {
            return null;
        }

        let isEditeMode = self.state.edited;
        const gridData = self.docData.gridData ? self.docData.gridData : [],
            gridColumns = self.docData.gridConfig ? self.docData.gridConfig : [];

        if (!self.docData.omvorm) {
            self.docData.omvorm = 'ISIK';
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title="Reg.kood "
                                   name='regkood'
                                   ref="input-regkood"
                                   readOnly={!isEditeMode}
                                   value={self.docData.regkood || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Nimetus "
                                   name='nimetus'
                                   ref="input-nimetus"
                                   readOnly={!isEditeMode}
                                   value={self.docData.nimetus || ''}
                                   onChange={self.handleInputChange}/>
                        <InputText title="Om.vorm"
                                   name='omvorm'
                                   ref="input-omvorm"
                                   readOnly={true}
                                   value={self.docData.omvorm || 'ISIK'}
                                   onChange={self.handleInputChange}/>
                        {/*
                        <InputText title="Arveldus arve:"
                                   name='aa'
                                   ref="input-aa"
                                   readOnly={!isEditeMode}
                                   value={self.docData.aa || ''}
                                   onChange={self.handleInputChange}/>
*/}
                        <div style={styles.docRow}>
                            <DataGrid source='details'
                                      gridData={gridData}
                                      gridColumns={gridColumns}
                                      showToolBar={self.state.edited}
                                      handleGridBtnClick={self.handleGridBtnClick}
                                      readOnly={!self.state.edited}
                                      style={styles.grid.headerTable}
                                      ref="data-grid"/>
                        </div>
                        {self.state.gridRowEdit ?
                            this.createGridRow(self)
                            : null}
                        <div style={styles.docRow}>
                            <CheckBox title="Teiste KOVide lapsed:"
                                      name='kas_teiste_kov'
                                      value={Boolean(self.docData.kas_teiste_kov)}
                                      ref={'checkbox_kas_teiste_kov'}
                                      onChange={self.handleInputChange}
                                      readOnly={!self.state.edited}
                            />
                        </div>

                    </div>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Aadress"
                              name='aadress'
                              ref="textarea-aadress"
                              onChange={self.handleInputChange}
                              value={self.docData.aadress || ''}
                              readOnly={!isEditeMode}/>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Kontakt"
                              name='kontakt'
                              ref="textarea-kontakt"
                              onChange={self.handleInputChange}
                              value={self.docData.kontakt || ''}
                              readOnly={!isEditeMode}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Telefon"
                               name='tel'
                               ref="input-tel"
                               value={self.docData.tel || ''}
                               readOnly={!isEditeMode}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <InputText title="Email"
                               name='email'
                               ref="input-email"
                               value={self.docData.email || ''}
                               readOnly={!isEditeMode}
                               onChange={self.handleInputChange}/>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Muud"
                              name='muud'
                              ref="textarea-muud"
                              onChange={self.handleInputChange}
                              value={self.docData.muud || ''}
                              readOnly={!isEditeMode}/>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Märkused"
                              name='mark'
                              ref="textarea-mark"
                              onChange={self.handleInputChange}
                              value={self.docData.mark || ''}
                              readOnly={!isEditeMode}/>
                </div>
            </div>
        );
    }

    /**
     * Создаст компонет строки грида
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
                        <InputText title='Number: '
                                   name='aa'
                                   value={row.aa || ''}
                                   readOnly={false}
                                   disabled={false}
                                   bindData={false}
                                   ref='number'
                                   onChange={self.handleGridRowInput}/>
                    </div>
                    <div style={styles.docRow}>
                        <CheckBox title="Palk"
                                  name='kas_palk'
                                  value={Boolean(row.kas_palk)}
                                  ref={'checkbox_kas_palk'}
                                  onChange={self.handleGridRowChange}
                                  readOnly={false}
                                  labelStyle={styles.label ? styles.label : {}}
                        />
                        <CheckBox title="Õppetasu"
                                  name='kas_oppetasu'
                                  value={Boolean(row.kas_oppetasu)}
                                  ref={'checkbox_kas_oppetasu'}
                                  onChange={self.handleGridRowChange}
                                  readOnly={false}
                        />
                        <CheckBox title="Raamatupidamine"
                                  name='kas_raama'
                                  value={Boolean(row.kas_raama)}
                                  ref={'checkbox_kas_raama'}
                                  onChange={self.handleGridRowChange}
                                  readOnly={false}
                        />
                    </div>
                </div>
                <div><span>{validateMessage}</span></div>
            </ModalPage>
        </div>);
    }


}

Asutused.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object
};

Asutused.defaultProps = {
    initData: {},
    userData: {}
};

module.exports = (Asutused);
